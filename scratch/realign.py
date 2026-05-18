import os
import shutil
import subprocess
import re

project_dir = "/Users/richardgeorgschotte/Projekte/train-libre"

# Old models path relative to lib/models/
model_mapping = {
    # Diary
    "food_item.dart": "lib/features/diary/domain/models/food_item.dart",
    "food_entry.dart": "lib/features/diary/domain/models/food_entry.dart",
    "daily_nutrition.dart": "lib/features/diary/domain/models/daily_nutrition.dart",
    "fluid_entry.dart": "lib/features/diary/domain/models/fluid_entry.dart",
    "tracked_food_item.dart": "lib/features/diary/domain/models/tracked_food_item.dart",
    "water_entry.dart": "lib/features/diary/domain/models/water_entry.dart",
    
    # Workout
    "workout_log.dart": "lib/features/workout/domain/models/workout_log.dart",
    "set_log.dart": "lib/features/workout/domain/models/set_log.dart",
    "routine.dart": "lib/features/workout/domain/models/routine.dart",
    "routine_exercise.dart": "lib/features/workout/domain/models/routine_exercise.dart",
    "set_template.dart": "lib/features/workout/domain/models/set_template.dart",
    
    # Exercise Catalog
    "exercise.dart": "lib/features/exercise_catalog/domain/models/exercise.dart",
    
    # Supplements
    "supplement.dart": "lib/features/supplements/domain/models/supplement.dart",
    "supplement_log.dart": "lib/features/supplements/domain/models/supplement_log.dart",
    "tracked_supplement.dart": "lib/features/supplements/domain/models/tracked_supplement.dart",
    
    # Profile
    "measurement.dart": "lib/features/profile/domain/models/measurement.dart",
    "measurement_session.dart": "lib/features/profile/domain/models/measurement_session.dart",
    
    # Analytics / Presentation / Leftover
    "chart_data_point.dart": "lib/features/analytics/domain/models/chart_data_point.dart",
    "timeline_entry.dart": "lib/features/analytics/domain/models/timeline_entry.dart",
    
    # App
    "train_libre_backup.dart": "lib/features/app/domain/models/train_libre_backup.dart",
}

def move_files():
    print("Moving models...")
    for filename, target_rel_path in model_mapping.items():
        src_path = os.path.join(project_dir, "lib", "models", filename)
        dst_path = os.path.join(project_dir, target_rel_path)
        
        if not os.path.exists(src_path):
            print(f"Source file {src_path} does not exist. Skipping.")
            continue
            
        dst_dir = os.path.dirname(dst_path)
        os.makedirs(dst_dir, exist_ok=True)
        
        # Try git mv first, fall back to shutil.move
        try:
            subprocess.run(["git", "mv", src_path, dst_path], check=True, cwd=project_dir)
            print(f"Git moved {filename} to {target_rel_path}")
        except subprocess.CalledProcessError:
            shutil.move(src_path, dst_path)
            print(f"Moved {filename} to {target_rel_path}")

def update_imports():
    print("Updating imports project-wide...")
    
    # Build replacement mapping for package imports
    package_replacements = {}
    for filename, target_rel_path in model_mapping.items():
        old_pkg = f"package:train_libre/models/{filename}"
        new_pkg = f"package:train_libre/{target_rel_path[4:]}"
        package_replacements[old_pkg] = new_pkg
    
    # We also want to match any relative imports pointing to models/...
    # For example, import '../../models/food_item.dart';
    relative_model_patterns = {}
    for filename, target_rel_path in model_mapping.items():
        # Match imports ending with models/filename
        # We can construct a regex pattern that matches '.*models/filename' in the import path.
        pattern = re.compile(r"import\s+['\"]([^'\"]*/models/" + filename + r")['\"];")
        new_import = f"import 'package:train_libre/{target_rel_path[4:]}';"
        relative_model_patterns[pattern] = new_import

    # Traverse all folders
    for folder in ["lib", "test"]:
        full_folder = os.path.join(project_dir, folder)
        for root, dirs, files in os.walk(full_folder):
            for file in files:
                if file.endswith(".dart"):
                    file_path = os.path.join(root, file)
                    with open(file_path, "r", encoding="utf-8") as f:
                        content = f.read()
                        
                    original_content = content
                    
                    # 1. Replace package imports
                    for old_pkg, new_pkg in package_replacements.items():
                        content = content.replace(old_pkg, new_pkg)
                    
                    # 2. Replace relative imports
                    for pattern, new_import in relative_model_patterns.items():
                        content = pattern.sub(new_import, content)
                        
                    # Also replace package imports without subfolders if any (e.g. package:train_libre/models/food_item.dart)
                    # using regex for safety
                    if content != original_content:
                        with open(file_path, "w", encoding="utf-8") as f:
                            f.write(content)
                        # print(f"Updated imports in {os.path.relpath(file_path, project_dir)}")

if __name__ == "__main__":
    move_files()
    update_imports()
    print("Realign completed!")
