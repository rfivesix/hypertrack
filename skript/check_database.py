import sqlite3
import os
import sys

# Liste der Dateien, die standardmäßig geprüft werden sollen
default_files = ["hypertrack_base_foods.db", "hypertrack_training.db"]

def inspect_db(db_path):
    print(f"\n{'='*60}")
    print(f"🔍 INSPEKTION: {db_path}")
    print(f"{'='*60}")

    if not os.path.exists(db_path):
        print(f"❌ Datei existiert nicht: {db_path}")
        return

    try:
        conn = sqlite3.connect(db_path)
        # Damit wir Spaltennamen statt nur Indexe sehen (optional, aber hilfreich)
        conn.row_factory = sqlite3.Row 
        cursor = conn.cursor()

        # 1. Alle Tabellen auflisten (außer interne SQLite-Tabellen)
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
        tables = cursor.fetchall()

        if not tables:
            print("⚠️  LEER: Keine Tabellen gefunden!")
            conn.close()
            return

        print(f"📂 Gefundene Tabellen: {[t['name'] for t in tables]}\n")

        # 2. Jede Tabelle im Detail analysieren
        for table in tables:
            table_name = table['name']
            print(f"--- Tabelle: [{table_name}] ---")

            # A) Spalten-Struktur holen
            cursor.execute(f"PRAGMA table_info({table_name})")
            columns = cursor.fetchall()
            print(f"  🛠  Spalten ({len(columns)}):")
            col_names = []
            for col in columns:
                # col[1] ist Name, col[2] ist Typ
                print(f"      - {col[1]} ({col[2]})")
                col_names.append(col[1])

            # B) Anzahl der Zeilen zählen
            try:
                cursor.execute(f"SELECT COUNT(*) as cnt FROM {table_name}")
                count = cursor.fetchone()['cnt']
                print(f"  📊 Einträge: {count}")

                # C) Beispiel-Daten zeigen (nur wenn nicht leer)
                if count > 0:
                    print("  👀 Vorschau (Top 3):")
                    cursor.execute(f"SELECT * FROM {table_name} LIMIT 3")
                    rows = cursor.fetchall()
                    for row in rows:
                        # Row in echtes Dict wandeln für lesbare Ausgabe
                        print(f"      {dict(row)}")
                else:
                    print("      (Tabelle ist leer)")

            except Exception as e:
                print(f"  ❌ Fehler beim Lesen: {e}")
            
            print("") # Leerzeile zur Trennung

    except Exception as e:
        print(f"🔥 KRITISCHER FEHLER: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    # Wenn man Argumente übergibt (z.B. python check_database.py meine_datei.db)
    if len(sys.argv) > 1:
        for f in sys.argv[1:]:
            inspect_db(f)
    else:
        # Sonst einfach alle bekannten DBs im Ordner prüfen
        print("Keine Datei angegeben, prüfe Standard-Dateien...")
        for f in default_files:
            inspect_db(f)
