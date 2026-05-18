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

        if "import 'workout_database_helper.dart';" in content:
            content = content.replace("import 'workout_database_helper.dart';", "import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';")
            changed = True

        if "import 'product_database_helper.dart';" in content:
            content = content.replace("import 'product_database_helper.dart';", "import 'package:train_libre/features/diary/data/sources/product_local_data_source.dart';")
            changed = True

        if filepath == './lib/features/diary/domain/use_cases/evaluate_food_source_use_case.dart':
            content = re.sub(r"import '\.\./\.\./features/diary/domain/models/food_item\.dart';", "import 'package:train_libre/features/diary/domain/models/food_item.dart';", content)
            changed = True

        if filepath == './lib/features/diary/domain/use_cases/retain_historical_off_products_use_case.dart':
            content = re.sub(r"import '\.\./\.\./data/drift_database\.dart';", "import 'package:train_libre/data/drift_database.dart' as db;\nimport 'package:train_libre/data/drift_database.dart';", content)
            content = content.replace('AppDatabase database', 'db.AppDatabase database')
            content = content.replace('ProductsCompanion', 'db.ProductsCompanion')
            changed = True

        if filepath == './lib/features/diary/data/sources/product_local_data_source.dart':
            if 'forTesting' not in content:
                content = content.replace('ProductLocalDataSource(this._dbInstance) : _dbHelper = null;', 'ProductLocalDataSource(this._dbInstance) : _dbHelper = null;\n  ProductLocalDataSource.forTesting({required DatabaseHelper databaseHelper}) : _dbInstance = null, _dbHelper = databaseHelper;')
                changed = True
        
        if filepath == './lib/features/workout/data/sources/workout_local_data_source.dart':
            if 'forTesting' not in content:
                content = content.replace('WorkoutLocalDataSource(this._dbInstance) : _dbHelper = null;', 'WorkoutLocalDataSource(this._dbInstance) : _dbHelper = null;\n  WorkoutLocalDataSource.forTesting({required DatabaseHelper databaseHelper}) : _dbInstance = null, _dbHelper = databaseHelper;')
                changed = True

        if filepath == './test/workout_session_manager_test.dart':
            # Fix undefined named parameter 'workoutDbHelper'
            content = content.replace('workoutDbHelper: WorkoutLocalDataSource.instance', 'workoutDb: WorkoutLocalDataSource.instance')
            changed = True

        if changed:
            with open(filepath, 'w') as f:
                f.write(content)
