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

        if 'WorkoutDatabaseHelper' in content:
            content = content.replace('WorkoutDatabaseHelper', 'WorkoutLocalDataSource')
            changed = True
            
        if 'workout_database_helper.dart' in content:
            content = re.sub(r'[\'"](?:package:train_libre/data/|\.*(?:/data/)+)workout_database_helper\.dart[\'"]', "'package:train_libre/features/workout/data/sources/workout_local_data_source.dart'", content)
            changed = True

        if 'ProductDatabaseHelper' in content:
            content = content.replace('ProductDatabaseHelper', 'ProductLocalDataSource')
            changed = True

        if 'product_database_helper.dart' in content:
            content = re.sub(r'[\'"](?:package:train_libre/data/|\.*(?:/data/)+)product_database_helper\.dart[\'"]', "'package:train_libre/features/diary/data/sources/product_local_data_source.dart'", content)
            changed = True

        if 'evaluate_food_source_use_case.dart' in content:
            content = re.sub(r'[\'"](?:package:train_libre/domain/use_cases/|\.*(?:/domain/use_cases/)+)evaluate_food_source_use_case\.dart[\'"]', "'package:train_libre/features/diary/domain/use_cases/evaluate_food_source_use_case.dart'", content)
            changed = True

        if 'retain_historical_off_products_use_case.dart' in content:
            content = re.sub(r'[\'"](?:package:train_libre/domain/use_cases/|\.*(?:/domain/use_cases/)+)retain_historical_off_products_use_case\.dart[\'"]', "'package:train_libre/features/diary/domain/use_cases/retain_historical_off_products_use_case.dart'", content)
            changed = True

        if filepath == './lib/features/diary/data/sources/product_local_data_source.dart':
            content = re.sub(r"import 'database_helper\.dart';", "import 'package:train_libre/data/database_helper.dart';", content)
            content = re.sub(r"import 'drift_database\.dart' as db;", "import 'package:train_libre/data/drift_database.dart' as db;", content)
            content = re.sub(r"import '\.\./config/app_data_sources\.dart';", "import 'package:train_libre/config/app_data_sources.dart';", content)
            content = re.sub(r"import '\.\./features/diary/domain/models/food_item\.dart';", "import 'package:train_libre/features/diary/domain/models/food_item.dart';", content)
            content = re.sub(r"import '\.\./services/catalog_file_migration\.dart';", "import 'package:train_libre/services/catalog_file_migration.dart';", content)
            content = re.sub(r"import '\.\./util/perf_debug_timer\.dart';", "import 'package:train_libre/util/perf_debug_timer.dart';", content)
            changed = True
            
        if filepath == './lib/features/workout/data/sources/workout_local_data_source.dart':
            content = re.sub(r"import 'database_helper\.dart';", "import 'package:train_libre/data/database_helper.dart';", content)
            content = re.sub(r"import 'drift_database\.dart' as db;", "import 'package:train_libre/data/drift_database.dart' as db;", content)
            content = re.sub(r"import '\.\./features/exercise_catalog/domain/models/exercise\.dart';", "import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';", content)
            content = re.sub(r"import '\.\./features/workout/domain/models/routine\.dart';", "import 'package:train_libre/features/workout/domain/models/routine.dart';", content)
            content = re.sub(r"import '\.\./features/workout/domain/models/routine_exercise\.dart';", "import 'package:train_libre/features/workout/domain/models/routine_exercise.dart';", content)
            content = re.sub(r"import '\.\./features/workout/domain/models/set_log\.dart';", "import 'package:train_libre/features/workout/domain/models/set_log.dart';", content)
            content = re.sub(r"import '\.\./features/workout/domain/models/set_template\.dart';", "import 'package:train_libre/features/workout/domain/models/set_template.dart';", content)
            content = re.sub(r"import '\.\./features/workout/domain/models/workout_log\.dart';", "import 'package:train_libre/features/workout/domain/models/workout_log.dart';", content)
            content = re.sub(r"import '\.\./features/workout/domain/classification/workout_classification\.dart';", "import 'package:train_libre/features/workout/domain/classification/workout_classification.dart';", content)
            content = re.sub(r"import '\.\./features/statistics/domain/recovery_domain_service\.dart';", "import 'package:train_libre/features/statistics/domain/recovery_domain_service.dart';", content)
            content = re.sub(r"import '\.\./util/muscle_analytics_utils\.dart';", "import 'package:train_libre/util/muscle_analytics_utils.dart';", content)
            content = re.sub(r"import '\.\./util/perf_debug_timer\.dart';", "import 'package:train_libre/util/perf_debug_timer.dart';", content)
            changed = True

        if changed:
            with open(filepath, 'w') as f:
                f.write(content)
