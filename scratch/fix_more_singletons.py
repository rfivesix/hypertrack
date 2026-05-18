import os
import re

def fix_file(filepath, classname):
    with open(filepath, 'r') as f:
        content = f.read()

    # If _init is missing, add it
    if f'{classname}._init()' not in content:
        content = content.replace(f'static final {classname} instance = {classname}(DatabaseHelper.instance.database);', '')
        
        # We need to insert the correct singleton setup
        insertion = f'''  final db.AppDatabase? _dbInstance;
  final DatabaseHelper? _dbHelper;

  static final {classname} instance = {classname}._init();

  {classname}._init() : _dbInstance = null, _dbHelper = DatabaseHelper.instance;
  {classname}(this._dbInstance) : _dbHelper = null;
  {classname}.forTesting({{required DatabaseHelper databaseHelper}}) : _dbInstance = null, _dbHelper = databaseHelper;
'''
        # Find where to insert it. Let's just replace the class declaration block.
        if classname == 'ProductLocalDataSource':
            content = re.sub(r'class ProductLocalDataSource \{.*?(?=\s*// Access)', 'class ProductLocalDataSource {\n' + insertion, content, flags=re.DOTALL)
        elif classname == 'WorkoutLocalDataSource':
            content = re.sub(r'class WorkoutLocalDataSource \{.*?(?=\s*// Access)', 'class WorkoutLocalDataSource {\n' + insertion, content, flags=re.DOTALL)

    with open(filepath, 'w') as f:
        f.write(content)

fix_file('lib/features/diary/data/sources/product_local_data_source.dart', 'ProductLocalDataSource')
fix_file('lib/features/workout/data/sources/workout_local_data_source.dart', 'WorkoutLocalDataSource')

# Also fix the type errors
# In database_helper.dart: food.calories was int, but drift db.Product calories is double!
# Wait! food is FoodItem here, and FoodItem.calories is int. Wait, no. If FoodItem calories is int, why the error?
# Let's replace food.calories with (food.calories.toDouble()) just in case.

def replace_type_errors(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    # In database_helper.dart
    content = content.replace('consumedKcal += (food.calories * factor).round();', 'consumedKcal += (food.calories.toDouble() * factor).round();')
    content = content.replace('consumedProtein += (food.protein * factor).round();', 'consumedProtein += (food.protein.toDouble() * factor).round();')
    content = content.replace('consumedCarbs += (food.carbs * factor).round();', 'consumedCarbs += (food.carbs.toDouble() * factor).round();')
    content = content.replace('consumedFat += (food.fat * factor).round();', 'consumedFat += (food.fat.toDouble() * factor).round();')
    with open(filepath, 'w') as f:
        f.write(content)
        
replace_type_errors('lib/data/database_helper.dart')

def replace_type_errors_meal(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    content = content.replace('final itemKcal = (fi.calories) * factor;', 'final itemKcal = (fi.calories.toDouble()) * factor;')
    with open(filepath, 'w') as f:
        f.write(content)

replace_type_errors_meal('lib/features/diary/presentation/meal_screen.dart')

