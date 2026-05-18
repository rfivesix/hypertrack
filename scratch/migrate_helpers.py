import os
import re

# 1. ProductDatabaseHelper -> ProductLocalDataSource
with open('lib/data/product_database_helper.dart', 'r') as f:
    content = f.read()

content = content.replace('class ProductDatabaseHelper', 'class ProductLocalDataSource')
content = re.sub(r'static final ProductLocalDataSource instance = ProductDatabaseHelper\._init\(\);\n?', '', content)
content = re.sub(r'final DatabaseHelper _databaseHelper;\n?', 'final db.AppDatabase dbInstance;\n', content)
content = re.sub(r'ProductDatabaseHelper\._init\(\) : _databaseHelper = DatabaseHelper\.instance;\n?', 'ProductLocalDataSource(this.dbInstance);\n', content)
content = re.sub(r'ProductDatabaseHelper\.forTesting\(\{required DatabaseHelper databaseHelper\}\)\n\s*: _databaseHelper = databaseHelper;\n?', '', content)
content = content.replace('Future<db.AppDatabase> get database async => _databaseHelper.database;', 'Future<db.AppDatabase> get database async => dbInstance;')

with open('lib/features/diary/data/sources/product_local_data_source.dart', 'w') as f:
    f.write(content)

# 2. WorkoutDatabaseHelper -> WorkoutLocalDataSource
with open('lib/data/workout_database_helper.dart', 'r') as f:
    content = f.read()

content = content.replace('class WorkoutDatabaseHelper', 'class WorkoutLocalDataSource')
content = re.sub(r'static final WorkoutLocalDataSource instance = WorkoutDatabaseHelper\._init\(\);\n?', '', content)
content = re.sub(r'final DatabaseHelper _databaseHelper;\n?', 'final db.AppDatabase dbInstance;\n', content)
content = re.sub(r'WorkoutDatabaseHelper\._init\(\) : _databaseHelper = DatabaseHelper\.instance;\n?', 'WorkoutLocalDataSource(this.dbInstance);\n', content)
content = re.sub(r'WorkoutDatabaseHelper\.forTesting\(\{required DatabaseHelper databaseHelper\}\)\n\s*: _databaseHelper = databaseHelper;\n?', '', content)
content = content.replace('Future<db.AppDatabase> get database async => _databaseHelper.database;', 'Future<db.AppDatabase> get database async => dbInstance;')

with open('lib/features/workout/data/sources/workout_local_data_source.dart', 'w') as f:
    f.write(content)

# 3. DiaryLocalDataSource -> Update usages
with open('lib/features/diary/data/sources/diary_local_data_source.dart', 'r') as f:
    diary_content = f.read()

diary_content = diary_content.replace('import \'../../../../data/workout_database_helper.dart\';', 'import \'../../../workout/data/sources/workout_local_data_source.dart\';')
diary_content = diary_content.replace('import \'../../../../data/product_database_helper.dart\';', 'import \'product_local_data_source.dart\';')
diary_content = diary_content.replace('ProductDatabaseHelper', 'ProductLocalDataSource')
diary_content = diary_content.replace('WorkoutDatabaseHelper', 'WorkoutLocalDataSource')
diary_content = diary_content.replace('_productDbHelper = productDbHelper ?? ProductLocalDataSource.instance', '_productDbHelper = productDbHelper ?? ProductLocalDataSource(db)')
diary_content = diary_content.replace('_workoutDbHelper = workoutDbHelper ?? WorkoutLocalDataSource.instance', '_workoutDbHelper = workoutDbHelper ?? WorkoutLocalDataSource(db)')

with open('lib/features/diary/data/sources/diary_local_data_source.dart', 'w') as f:
    f.write(diary_content)
