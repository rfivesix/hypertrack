import sqlite3
import os
import sys

# List of files to check by default.
default_files = ["train_libre_base_foods.db", "train_libre_training.db"]

def inspect_db(db_path):
    print(f"\n{'='*60}")
    print(f"🔍 INSPEKTION: {db_path}")
    print(f"{'='*60}")

    if not os.path.exists(db_path):
        print(f"❌ Datei existiert nicht: {db_path}")
        return

    try:
        conn = sqlite3.connect(db_path)
        # Show column names instead of only indexes (optional, but helpful).
        conn.row_factory = sqlite3.Row 
        cursor = conn.cursor()

        # 1. List all tables except internal SQLite tables.
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
        tables = cursor.fetchall()

        if not tables:
            print("⚠️  LEER: Keine Tabellen gefunden!")
            conn.close()
            return

        print(f"📂 Gefundene Tabellen: {[t['name'] for t in tables]}\n")

        # 2. Analyze each table in detail.
        for table in tables:
            table_name = table['name']
            print(f"--- Tabelle: [{table_name}] ---")

            # A) Fetch the column structure.
            cursor.execute(f"PRAGMA table_info({table_name})")
            columns = cursor.fetchall()
            print(f"  🛠  Spalten ({len(columns)}):")
            col_names = []
            for col in columns:
                # col[1] is the name, col[2] is the type.
                print(f"      - {col[1]} ({col[2]})")
                col_names.append(col[1])

            # B) Count the rows.
            try:
                cursor.execute(f"SELECT COUNT(*) as cnt FROM {table_name}")
                count = cursor.fetchone()['cnt']
                print(f"  📊 Einträge: {count}")

                # C) Show sample data if the table is not empty.
                if count > 0:
                    print("  👀 Vorschau (Top 3):")
                    cursor.execute(f"SELECT * FROM {table_name} LIMIT 3")
                    rows = cursor.fetchall()
                    for row in rows:
                        # Convert Row to a real dict for readable output.
                        print(f"      {dict(row)}")
                else:
                    print("      (Tabelle ist leer)")

            except Exception as e:
                print(f"  ❌ Fehler beim Lesen: {e}")
            
            print("") # Blank line separator

    except Exception as e:
        print(f"🔥 KRITISCHER FEHLER: {e}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    # When arguments are passed (for example: python check_database.py my_file.db).
    if len(sys.argv) > 1:
        for f in sys.argv[1:]:
            inspect_db(f)
    else:
        # Otherwise check all known DBs in the folder.
        print("Keine Datei angegeben, prüfe Standard-Dateien...")
        for f in default_files:
            inspect_db(f)
