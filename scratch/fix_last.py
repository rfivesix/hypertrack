import os

# 1. Fix DatabaseHelper import in WorkoutLocalDataSource
workout_file = 'lib/features/workout/data/sources/workout_local_data_source.dart'
with open(workout_file, 'r') as f:
    content = f.read()

if "import 'package:train_libre/data/database_helper.dart';" not in content:
    content = "import 'package:train_libre/data/database_helper.dart';\n" + content

# Fix get database async => dbInstance;
content = content.replace('Future<db.AppDatabase> get database async => dbInstance;', '''Future<db.AppDatabase> get database async {
    if (_dbInstance != null) return _dbInstance!;
    return _dbHelper!.database;
  }''')
with open(workout_file, 'w') as f:
    f.write(content)

# 2. Fix ProductLocalDataSource get database
product_file = 'lib/features/diary/data/sources/product_local_data_source.dart'
with open(product_file, 'r') as f:
    content = f.read()

content = content.replace('Future<db.AppDatabase> get database async => dbInstance;', '''Future<db.AppDatabase> get database async {
    if (_dbInstance != null) return _dbInstance!;
    return _dbHelper!.database;
  }''')
with open(product_file, 'w') as f:
    f.write(content)

# 3. Fix test file named parameter
test_file = 'test/workout_session_manager_test.dart'
with open(test_file, 'r') as f:
    content = f.read()

content = content.replace('workoutDbHelper:', 'workoutDb:')
with open(test_file, 'w') as f:
    f.write(content)

