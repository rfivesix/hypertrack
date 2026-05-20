# One-Way Native Health Export & Idempotency Pipeline

Train Libre integrates directly with system-level health aggregates via Apple HealthKit (iOS) and Google Health Connect (Android). To preserve user privacy and maintain on-device authority, the integration functions strictly as a one-way export from Train Libre's local SQLite database to the target platform. 

---

## Architectural Principles

The synchronization engine operates under three technical invariants:

1.  **On-Device Authority**: Train Libre's local SQLite database serves as the absolute single source of truth (SSOT). Data is never imported from HealthKit or Health Connect to alter local history; the data flow is strictly outbound.
2.  **Zero Cloud Intermediaries**: All communication with the native health APIs occurs directly through OS-level platform channels and native bindings. No external servers or telemetry systems handle or store these records.
3.  **Strict Idempotency**: Repeated synchronization runs must never create duplicate segments or write redundant entries into the system health database, regardless of sync frequency or network interrupts.

---

## Idempotency Engine

To guarantee that each record is exported exactly once, the platform implements a hash-based tracking registry.

### SQLite Schema: `health_export_records`

Every successfully exported record is registered in a dedicated SQLite table managed via the Drift ORM:

```sql
CREATE TABLE IF NOT EXISTS health_export_records (
    local_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    id TEXT NOT NULL UNIQUE,
    platform TEXT NOT NULL,
    domain TEXT NOT NULL,
    idempotency_key TEXT NOT NULL,
    exported_at INTEGER NOT NULL,
    UNIQUE(platform, domain, idempotency_key)
);
```

#### Fields and Logic
*   `id`: A unique 128-bit hexadecimal identifier generated deterministically on insertion using the SQLite function `lower(hex(randomblob(16)))`.
*   `platform`: Identifies the target platform (`appleHealth` or `healthConnect`).
*   `domain`: Categorizes the exported record type into one of three domains: `measurements`, `nutritionHydration`, or `workouts`.
*   `idempotency_key`: A unique computed hash corresponding directly to the original record's identity, timestamp, and payload values.
*   `exported_at`: A Unix timestamp (seconds since epoch) capturing when the export was registered locally.

### Upsert and Verification Mechanics

When writing records, the local data source handles conflicts gracefully via SQL upsert. This is executed using the following statement in `StepsLocalDataSource.markHealthExported`:

```sql
INSERT INTO health_export_records (id, platform, domain, idempotency_key, exported_at)
VALUES (lower(hex(randomblob(16))), ?, ?, ?, ?)
ON CONFLICT(platform, domain, idempotency_key) DO UPDATE SET
  exported_at = excluded.exported_at;
```

Before passing payloads to the native adapter, the service queries the database to filter out already-exported items. The verification lookup matches keys in batches using `getExportedHealthKeys`:

```sql
SELECT idempotency_key
FROM health_export_records
WHERE platform = ?
  AND domain = ?
  AND idempotency_key IN (<idempotency_keys_placeholders>);
```

Only records whose `idempotency_key` is not returned by this query are forwarded to the native system APIs for writing.

---

## Step Segment Hourly Merging

Since step logs can be gathered concurrently by different sub-sensors (such as phone accelerometers, smartwatches, or manual inputs), the local database stores them as raw segments inside `health_step_segments`. When exporting or aggregating these segments for a given calendar day, overlapping data must be resolved. 

Train Libre implements two configurable merging policies inside `StepsLocalDataSource.getHourlyStepsTotalsForDay`:

### 1. Auto-Dominant Source Policy (`auto_dominant`)

The `auto_dominant` policy is the default behavior. It identifies the single device or sensor that contributed the highest volume of steps for the target day and aggregates data *only* from that source, ignoring potential overlap from secondary sensors.

#### SQL Execution Model:
1.  **Calculate Total Steps per Source**:
    ```sql
    WITH source_totals AS (
      SELECT
        COALESCE(source_id, '') AS source_key,
        SUM(step_count) AS source_total
      FROM health_step_segments
      WHERE start_at < ? AND end_at >= ?
      GROUP BY source_key
    )
    ```
2.  **Select Dominant Source**:
    ```sql
    dominant_source AS (
      SELECT source_key
      FROM source_totals
      ORDER BY source_total DESC, source_key ASC
      LIMIT 1
    )
    ```
3.  **Aggregate Hourly for Dominant Source**:
    ```sql
    SELECT
      CAST(strftime('%H', datetime(start_at, 'unixepoch', 'localtime')) AS INTEGER) AS hour_local,
      SUM(step_count) AS total_steps
    FROM health_step_segments
    WHERE start_at < ? AND end_at >= ?
      AND COALESCE(source_id, '') = (SELECT source_key FROM dominant_source)
    GROUP BY hour_local
    ORDER BY hour_local ASC;
    ```

### 2. Maximum Hourly Output Policy (`max_per_hour`)

The `max_per_hour` policy is designed for users with multiple active tracking devices. It aggregates and sums steps per hour for each source independently, and then selects the maximum hourly total among all active sources for each hour segment.

#### SQL Execution Model:
1.  **Calculate Hourly Sums per Source**:
    ```sql
    WITH source_hour AS (
      SELECT
        CAST(strftime('%H', datetime(start_at, 'unixepoch', 'localtime')) AS INTEGER) AS hour_local,
        COALESCE(source_id, '') AS source_key,
        SUM(step_count) AS source_steps
      FROM health_step_segments
      WHERE start_at < ? AND end_at >= ?
      GROUP BY hour_local, source_key
    )
    ```
2.  **Select Max Source Volume per Hour**:
    ```sql
    SELECT hour_local, MAX(source_steps) AS total_steps
    FROM source_hour
    GROUP BY hour_local
    ORDER BY hour_local ASC;
    ```

---

## Export Execution Lifecycle

The export loop is orchestrated by `HealthExportService` and involves a highly defensive multi-stage execution pipeline:

```
[Request Export] 
       │
       ▼
[Verify Platform Support & Permissions] ──(Not Configured)──► [Abort & Set Disabled]
       │
       ▼
[Load Domain Checkpoints (Checkpoints Map)]
       │
       ▼
[Load Payload for Domain since Checkpoint]
       │
       ▼
[Filter out Already Exported Keys (via SQLite lookup)]
       │
       ▼
[Chunk Pending Records (max 1000 per batch)]
       │
       ▼
[Write Batch via Native OS Adapter]
       │
  ┌────┴────────────────────────┐
  │                             │
(Success)                    (Failure)
  │                             │
  ▼                             ▼
[Mark Keys Exported in DB]   [Fall Back to Individual Writes]
                                │
                                ├─► (Success) ──► [Mark Key Exported in DB]
                                │
                                └─► (Failure) ──► [Log Error & Keep Key Pending]
```

### 1. Platform Validation & Permissions
Before initiating any transaction, the service queries `HealthExportAdapter.getAvailability()`. If the platform is not installed or is marked as unavailable, the platform state is set to `disabled`. The service also checks and requests explicit user permissions before reading or writing any data.

### 2. Incremental Domain Checkpoints
To avoid loading the entire database history for every export, `HealthExportService` reads the platform's historical execution state from `SharedPreferences`. The system tracks a separate `lastSuccessfulExportAtUtc` timestamp for each independent domain (`measurements`, `nutritionHydration`, `workouts`).
*   If a checkpoint exists for a domain, only logs added or updated *after* that timestamp are retrieved for export.
*   If a checkpoint is null (e.g., first sync or state reset), a full historical backfill is scheduled *only* for that specific domain. This ensures that a failure in one domain does not force other healthy domains to re-export their entire histories.

### 3. Record Batching (Chunking)
Native OS APIs impose strict bounds on payload sizes to prevent memory spikes and thread starvation. `HealthExportService` partitions all outbound arrays into batches of up to `1000` records (`maxWriteBatchSize`):
```dart
List<List<T>> _chunkRecords<T>(List<T> records) {
  if (records.isEmpty) return <List<T>>[];
  final chunks = <List<T>>[];
  for (var i = 0; i < records.length; i += maxWriteBatchSize) {
    final end = (i + maxWriteBatchSize) > records.length
        ? records.length
        : (i + maxWriteBatchSize);
    chunks.add(records.sublist(i, end));
  }
  return chunks;
}
```

### 4. Fault Tolerance & Individual Fallback
While measurements and workouts are exported in bulk, the `nutritionHydration` domain employs a defensive fallback mechanism. If a batch write to HealthKit or Health Connect fails, the system does not fail the entire sync. Instead, it enters a granular recovery mode:
1.  **Batch Write Attempt**: The service attempts to write the entire chunk of nutrition or hydration records.
2.  **Fallback Trigger**: If the batch throws an exception, the system catches the error and iterates over every record in that batch individually.
3.  **Individual Writes**: The service invokes the single-record writer method (`adapter.writeNutrition` or `adapter.writeHydration`) for each record.
4.  **Partial Completion**: Successful writes are recorded immediately in `health_export_records`, while failed records are logged individually and skipped. This prevents a single corrupt record (e.g., invalid timestamp or out-of-range value) from blocking the export of remaining healthy data.
