import os
import re

def fix_file(filepath, classname):
    with open(filepath, 'r') as f:
        content = f.read()

    # Find the class declaration and constructor
    pattern = r'class ' + classname + r' \{\n  final db\.AppDatabase dbInstance;\n  ' + classname + r'\(this\.dbInstance\);\n  Future<db\.AppDatabase> get database async => dbInstance;'
    
    replacement = f'''class {classname} {{
  final db.AppDatabase? _dbInstance;
  final DatabaseHelper? _dbHelper;

  static final {classname} instance = {classname}._init();

  {classname}._init() : _dbInstance = null, _dbHelper = DatabaseHelper.instance;
  {classname}(this._dbInstance) : _dbHelper = null;

  Future<db.AppDatabase> get database async {{
    if (_dbInstance != null) return _dbInstance;
    return _dbHelper!.database;
  }}'''

    content = re.sub(pattern, replacement, content)

    with open(filepath, 'w') as f:
        f.write(content)

fix_file('lib/features/diary/data/sources/product_local_data_source.dart', 'ProductLocalDataSource')
fix_file('lib/features/workout/data/sources/workout_local_data_source.dart', 'WorkoutLocalDataSource')
