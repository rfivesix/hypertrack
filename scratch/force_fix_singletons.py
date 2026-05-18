import os
import re

def force_fix(filepath, classname):
    with open(filepath, 'r') as f:
        content = f.read()

    # Find the top of the class up to "Future<db.AppDatabase> get database"
    pattern = r'class ' + classname + r' \{.*?(?=\s*// Access|\s*Future<db\.AppDatabase> get database)'
    
    replacement = f'''class {classname} {{
  final db.AppDatabase? _dbInstance;
  final DatabaseHelper? _dbHelper;

  static final {classname} instance = {classname}._init();

  {classname}._init() : _dbInstance = null, _dbHelper = DatabaseHelper.instance;
  {classname}(this._dbInstance) : _dbHelper = null;
  {classname}.forTesting({{required DatabaseHelper databaseHelper}}) : _dbInstance = null, _dbHelper = databaseHelper;
'''
    
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    with open(filepath, 'w') as f:
        f.write(content)

force_fix('lib/features/diary/data/sources/product_local_data_source.dart', 'ProductLocalDataSource')
force_fix('lib/features/workout/data/sources/workout_local_data_source.dart', 'WorkoutLocalDataSource')

# Fix test/workout_session_manager_test.dart
test_file = 'test/workout_session_manager_test.dart'
with open(test_file, 'r') as f:
    content = f.read()
content = content.replace('workoutDbHelper: WorkoutLocalDataSource.instance', 'workoutDb: WorkoutLocalDataSource.instance')
with open(test_file, 'w') as f:
    f.write(content)

