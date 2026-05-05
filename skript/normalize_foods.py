import sqlite3
import os

db_path = "train_libre_base_foods.db"

if not os.path.exists(db_path):
    print(f"❌ {db_path} nicht gefunden.")
    exit()

print(f"🔧 Normalisiere {db_path}...")
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# 1. Spalten umbenennen (Mapping: Alt -> Neu)
# Drift erwartet: calories, protein, carbs, fat, sugar, fiber, salt, category
column_map = {
    "calories_100g": "calories",
    "protein_100g": "protein",
    "carbs_100g": "carbs",
    "fat_100g": "fat",
    "sugar_100g": "sugar",
    "fiber_100g": "fiber",
    "salt_100g": "salt",
    "category_key": "category"  # Wichtig!
}

try:
    # Prüfen, welche Spalten da sind
    cursor.execute("PRAGMA table_info(products)")
    existing_cols = [row[1] for row in cursor.fetchall()]

    for old_col, new_col in column_map.items():
        if old_col in existing_cols:
            print(f"  - Benenne um: {old_col} -> {new_col}")
            cursor.execute(f"ALTER TABLE products RENAME COLUMN {old_col} TO {new_col}")
        elif new_col in existing_cols:
            print(f"  - {new_col} existiert bereits.")
        else:
            print(f"  ⚠️ Spalte {old_col} nicht gefunden (übersprungen).")

    # 2. Version aktualisieren (damit die App das Update merkt!)
    cursor.execute('CREATE TABLE IF NOT EXISTS metadata (key TEXT PRIMARY KEY, value TEXT)')
    # Wir nehmen ein Datum in der Zukunft
    cursor.execute("INSERT OR REPLACE INTO metadata (key, value) VALUES ('version', '202512312359')")

    conn.commit()
    print("✅ Datenbank erfolgreich angepasst!")

except Exception as e:
    print(f"❌ Fehler: {e}")
finally:
    conn.close()
