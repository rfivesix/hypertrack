import os
import re

directories_to_search = ['lib', 'test']

for root, dirs, files in os.walk('.'):
    if not any(root.startswith(f'./{d}') or root == f'./{d}' for d in directories_to_search):
        continue
    for file in files:
        if not file.endswith('.dart'): continue
        filepath = os.path.join(root, file)
        
        with open(filepath, 'r') as f:
            content = f.read()

        changed = False

        # Replace any import of workout_database_helper.dart
        if re.search(r"import\s+'[^']*workout_database_helper\.dart';?", content):
            content = re.sub(r"import\s+'[^']*workout_database_helper\.dart';?", "import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';", content)
            changed = True

        # Replace any import of product_database_helper.dart
        if re.search(r"import\s+'[^']*product_database_helper\.dart';?", content):
            content = re.sub(r"import\s+'[^']*product_database_helper\.dart';?", "import 'package:train_libre/features/diary/data/sources/product_local_data_source.dart';", content)
            changed = True

        # Fix missing _init
        if "WorkoutLocalDataSource.instance" in content and "_init" not in content and filepath == "./lib/features/workout/data/sources/workout_local_data_source.dart":
             pass # I already fixed this in fix_singletons.py

        if changed:
            with open(filepath, 'w') as f:
                f.write(content)
