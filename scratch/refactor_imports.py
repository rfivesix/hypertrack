import os
import re

project_dir = "/Users/richardgeorgschotte/Projekte/train-libre"

# Old path to new path mapping (relative to project_dir)
moved_files = {
    # Block 5 Part 1
    "lib/data/nutrition_repository.dart": "lib/features/diary/data/nutrition_repository.dart",
    "lib/domain/use_cases/calculate_daily_nutrition_use_case.dart": "lib/features/diary/domain/calculate_daily_nutrition_use_case.dart",
    "lib/screens/diary_view_model.dart": "lib/features/diary/presentation/diary_view_model.dart",
    "lib/screens/diary_screen.dart": "lib/features/diary/presentation/diary_screen.dart",
    "lib/data/workout_repository.dart": "lib/features/workout/data/workout_repository.dart",
    "lib/domain/use_cases/detect_personal_record_use_case.dart": "lib/features/workout/domain/detect_personal_record_use_case.dart",
    "lib/domain/use_cases/log_workout_set_use_case.dart": "lib/features/workout/domain/log_workout_set_use_case.dart",
    "lib/screens/live_workout_view_model.dart": "lib/features/workout/presentation/live_workout_view_model.dart",
    "lib/screens/live_workout_screen.dart": "lib/features/workout/presentation/live_workout_screen.dart",
    
    # Leftover Feature Screens from Diary & Workout
    "lib/screens/add_food_screen.dart": "lib/features/diary/presentation/add_food_screen.dart",
    "lib/screens/food_detail_screen.dart": "lib/features/diary/presentation/food_detail_screen.dart",
    "lib/screens/add_food_navigation_result.dart": "lib/features/diary/presentation/add_food_navigation_result.dart",
    "lib/screens/food_explorer_screen.dart": "lib/features/diary/presentation/food_explorer_screen.dart",
    "lib/screens/general_food_selection_screen.dart": "lib/features/diary/presentation/general_food_selection_screen.dart",
    "lib/screens/workout_history_screen.dart": "lib/features/workout/presentation/workout_history_screen.dart",
    "lib/screens/workout_summary_screen.dart": "lib/features/workout/presentation/workout_summary_screen.dart",
    "lib/screens/workout_log_detail_screen.dart": "lib/features/workout/presentation/workout_log_detail_screen.dart",
    
    # Fallback keys to repair already-broken analyzer state imports
    "lib/domain/calculate_daily_nutrition_use_case.dart": "lib/features/diary/domain/calculate_daily_nutrition_use_case.dart",
    "lib/domain/detect_personal_record_use_case.dart": "lib/features/workout/domain/detect_personal_record_use_case.dart",
    "lib/domain/log_workout_set_use_case.dart": "lib/features/workout/domain/log_workout_set_use_case.dart",
    
    # --- NEW REALIGNMENTS (Turn 3) ---
    # Exercise Catalog
    "lib/screens/exercise_catalog_screen.dart": "lib/features/exercise_catalog/presentation/exercise_catalog_screen.dart",
    "lib/screens/create_exercise_screen.dart": "lib/features/exercise_catalog/presentation/create_exercise_screen.dart",
    "lib/screens/exercise_detail_screen.dart": "lib/features/exercise_catalog/presentation/exercise_detail_screen.dart",
    "lib/screens/exercise_mapping_screen.dart": "lib/features/exercise_catalog/presentation/exercise_mapping_screen.dart",
    "lib/screens/general_exercise_selection_screen.dart": "lib/features/exercise_catalog/presentation/general_exercise_selection_screen.dart",
    
    # Supplements
    "lib/screens/manage_supplements_screen.dart": "lib/features/supplements/presentation/manage_supplements_screen.dart",
    "lib/screens/supplement_hub_screen.dart": "lib/features/supplements/presentation/supplement_hub_screen.dart",
    "lib/screens/supplement_track_screen.dart": "lib/features/supplements/presentation/supplement_track_screen.dart",
    "lib/screens/create_supplement_screen.dart": "lib/features/supplements/presentation/create_supplement_screen.dart",
    
    # Profile & Measurements
    "lib/screens/profile_screen.dart": "lib/features/profile/presentation/profile_screen.dart",
    "lib/screens/goals_screen.dart": "lib/features/profile/presentation/goals_screen.dart",
    "lib/screens/add_measurement_screen.dart": "lib/features/profile/presentation/add_measurement_screen.dart",
    "lib/screens/measurement_session_detail_screen.dart": "lib/features/profile/presentation/measurement_session_detail_screen.dart",
    "lib/screens/measurements_screen.dart": "lib/features/profile/presentation/measurements_screen.dart",
    
    # Onboarding
    "lib/screens/onboarding_screen.dart": "lib/features/onboarding/presentation/onboarding_screen.dart",
    "lib/screens/initial_consent_screen.dart": "lib/features/onboarding/presentation/initial_consent_screen.dart",
    
    # Settings
    "lib/screens/settings_screen.dart": "lib/features/settings/presentation/settings_screen.dart",
    "lib/screens/appearance_settings_screen.dart": "lib/features/settings/presentation/appearance_settings_screen.dart",
    "lib/screens/ai_settings_screen.dart": "lib/features/settings/presentation/ai_settings_screen.dart",
    "lib/screens/data_management_screen.dart": "lib/features/settings/presentation/data_management_screen.dart",
    "lib/screens/health_export_settings_screen.dart": "lib/features/settings/presentation/health_export_settings_screen.dart",
    "lib/screens/pulse_settings_screen.dart": "lib/features/settings/presentation/pulse_settings_screen.dart",
    "lib/screens/sleep_settings_screen.dart": "lib/features/settings/presentation/sleep_settings_screen.dart",
    "lib/screens/steps_settings_screen.dart": "lib/features/settings/presentation/steps_settings_screen.dart",
    
    # Analytics
    "lib/screens/statistics_hub_screen.dart": "lib/features/analytics/presentation/statistics_hub_screen.dart",
    "lib/screens/statistics_hub_view_model.dart": "lib/features/analytics/presentation/statistics_hub_view_model.dart",
    "lib/screens/analytics/body_nutrition_correlation_screen.dart": "lib/features/analytics/presentation/body_nutrition_correlation_screen.dart",
    "lib/screens/analytics/consistency_tracker_screen.dart": "lib/features/analytics/presentation/consistency_tracker_screen.dart",
    "lib/screens/analytics/muscle_group_analytics_screen.dart": "lib/features/analytics/presentation/muscle_group_analytics_screen.dart",
    "lib/screens/analytics/pr_dashboard_screen.dart": "lib/features/analytics/presentation/pr_dashboard_screen.dart",
    "lib/screens/analytics/recovery_tracker_screen.dart": "lib/features/analytics/presentation/recovery_tracker_screen.dart",
    
    # App Shell
    "lib/screens/main_screen.dart": "lib/features/app/presentation/main_screen.dart",
    "lib/screens/home.dart": "lib/features/app/presentation/home.dart",
    "lib/screens/app_initializer_screen.dart": "lib/features/app/presentation/app_initializer_screen.dart",
    "lib/screens/about_screen.dart": "lib/features/app/presentation/about_screen.dart",
    "lib/screens/legal_screen.dart": "lib/features/app/presentation/legal_screen.dart",
    
    # Remaining Leftover Screens in Diary & Workout
    "lib/screens/ai_meal_capture_screen.dart": "lib/features/diary/presentation/ai_meal_capture_screen.dart",
    "lib/screens/ai_meal_review_screen.dart": "lib/features/diary/presentation/ai_meal_review_screen.dart",
    "lib/screens/ai_recommendation_screen.dart": "lib/features/diary/presentation/ai_recommendation_screen.dart",
    "lib/screens/create_food_screen.dart": "lib/features/diary/presentation/create_food_screen.dart",
    "lib/screens/meal_editor_screen.dart": "lib/features/diary/presentation/meal_editor_screen.dart",
    "lib/screens/meal_screen.dart": "lib/features/diary/presentation/meal_screen.dart",
    "lib/screens/meals_screen.dart": "lib/features/diary/presentation/meals_screen.dart",
    "lib/screens/nutrition_hub_screen.dart": "lib/features/diary/presentation/nutrition_hub_screen.dart",
    "lib/screens/nutrition_screen.dart": "lib/features/diary/presentation/nutrition_screen.dart",
    "lib/screens/scanner_screen.dart": "lib/features/diary/presentation/scanner_screen.dart",
    "lib/screens/edit_routine_screen.dart": "lib/features/workout/presentation/edit_routine_screen.dart",
    "lib/screens/routines_screen.dart": "lib/features/workout/presentation/routines_screen.dart",
    "lib/screens/workout_hub_screen.dart": "lib/features/workout/presentation/workout_hub_screen.dart",
    
    # Widgets
    "lib/widgets/add_menu_sheet.dart": "lib/features/app/presentation/widgets/add_menu_sheet.dart",
    "lib/widgets/analytics_chart_defaults.dart": "lib/features/analytics/presentation/widgets/analytics_chart_defaults.dart",
    "lib/widgets/app_tour_overlay.dart": "lib/features/onboarding/presentation/widgets/app_tour_overlay.dart",
    "lib/widgets/bottom_content_spacer.dart": "lib/widgets/common/bottom_content_spacer.dart",
    "lib/widgets/compact_nutrition_bar.dart": "lib/features/diary/presentation/widgets/compact_nutrition_bar.dart",
    "lib/widgets/editable_set_row.dart": "lib/features/workout/presentation/widgets/editable_set_row.dart",
    "lib/widgets/frosted_container.dart": "lib/widgets/common/frosted_container.dart",
    "lib/widgets/glass_bottom_menu.dart": "lib/features/app/presentation/widgets/glass_bottom_menu.dart",
    "lib/widgets/glass_bottom_nav_bar.dart": "lib/features/app/presentation/widgets/glass_bottom_nav_bar.dart",
    "lib/widgets/glass_fab.dart": "lib/widgets/common/glass_fab.dart",
    "lib/widgets/glass_menu.dart": "lib/widgets/common/glass_menu.dart",
    "lib/widgets/glass_pill_button.dart": "lib/widgets/common/glass_pill_button.dart",
    "lib/widgets/glass_progress_bar.dart": "lib/widgets/common/glass_progress_bar.dart",
    "lib/widgets/global_app_bar.dart": "lib/widgets/common/global_app_bar.dart",
    "lib/widgets/keep_alive_page.dart": "lib/widgets/common/keep_alive_page.dart",
    "lib/widgets/measurement_chart_widget.dart": "lib/features/profile/presentation/widgets/measurement_chart_widget.dart",
    "lib/widgets/muscle_radar_chart.dart": "lib/features/workout/presentation/widgets/muscle_radar_chart.dart",
    "lib/widgets/nutrition_summary_widget.dart": "lib/features/diary/presentation/widgets/nutrition_summary_widget.dart",
    "lib/widgets/off_attribution_widget.dart": "lib/features/diary/presentation/widgets/off_attribution_widget.dart",
    "lib/widgets/running_workout_bar.dart": "lib/features/workout/presentation/widgets/running_workout_bar.dart",
    "lib/widgets/set_type_chip.dart": "lib/features/workout/presentation/widgets/set_type_chip.dart",
    "lib/widgets/shadow_container.dart": "lib/widgets/common/shadow_container.dart",
    "lib/widgets/statistics_steps_card.dart": "lib/features/steps/presentation/statistics_steps_card.dart",
    "lib/widgets/summary_card.dart": "lib/widgets/common/summary_card.dart",
    "lib/widgets/supplement_summary_widget.dart": "lib/features/supplements/presentation/widgets/supplement_summary_widget.dart",
    "lib/widgets/swipe_action_background.dart": "lib/widgets/common/swipe_action_background.dart",
    "lib/widgets/todays_workout_summary_card.dart": "lib/features/workout/presentation/widgets/todays_workout_summary_card.dart",
    "lib/widgets/wger_attribution_widget.dart": "lib/features/exercise_catalog/presentation/widgets/wger_attribution_widget.dart",
    "lib/widgets/workout_card.dart": "lib/features/workout/presentation/widgets/workout_card.dart",
    "lib/widgets/workout_summary_bar.dart": "lib/features/workout/presentation/widgets/workout_summary_bar.dart",
}

# Replacements for package imports
package_replacements = {}
for old_path, new_path in moved_files.items():
    old_pkg = "package:train_libre/" + old_path[4:]
    new_pkg = "package:train_libre/" + new_path[4:]
    package_replacements[old_pkg] = new_pkg

def resolve_relative_import(importing_file_path, relative_import_str, resolve_base_path):
    dir_name = os.path.dirname(resolve_base_path)
    resolved = os.path.normpath(os.path.join(dir_name, relative_import_str))
    
    # Check if the resolved file is one of the moved files
    if resolved in moved_files:
        resolved = moved_files[resolved]
        
    if resolved.startswith("lib/"):
        return "package:train_libre/" + resolved[4:]
    return None

def process_file(file_path):
    # Find relative path of file_path to project_dir
    rel_path = os.path.relpath(file_path, project_dir)
    
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
        
    modified = False
    
    # 1. Replace package imports
    for old_pkg, new_pkg in package_replacements.items():
        if old_pkg in content:
            content = content.replace(old_pkg, new_pkg)
            modified = True
            
    # 2. Check if any relative imports point to moved files or need absolute conversion
    pattern = r"(import\s+['\"])(?!(?:package:|dart:))([^'\"]+)(['\"])"
    
    # Treat ALL files in moved_files values as newly moved in the working tree
    is_newly_moved = rel_path in moved_files.values()
    
    # Find the old path of the file
    old_moved_path = None
    if is_newly_moved:
        for k, v in moved_files.items():
            if rel_path == v:
                old_moved_path = k
                break
            
    def replace_relative(match):
        nonlocal modified
        prefix = match.group(1)
        rel_import = match.group(2)
        suffix = match.group(3)
        
        # Resolve from the correct base path
        resolve_base = old_moved_path if is_newly_moved else rel_path
        
        dir_name = os.path.dirname(resolve_base)
        resolved = os.path.normpath(os.path.join(dir_name, rel_import))
        
        # If the resolved file was an old path of a moved file, rewrite it to the new path
        if resolved in moved_files:
            modified = True
            new_pkg_path = "package:train_libre/" + moved_files[resolved][4:]
            return prefix + new_pkg_path + suffix
            
        # If the file itself was newly moved, convert ALL its relative imports to package imports
        if is_newly_moved:
            abs_pkg = resolve_relative_import(rel_path, rel_import, resolve_base)
            if abs_pkg:
                modified = True
                return prefix + abs_pkg + suffix
                
        return match.group(0)
        
    content = re.sub(pattern, replace_relative, content)
        
    if modified:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Refactored: {rel_path}")

def main():
    # Traverse lib/ and test/
    for folder in ["lib", "test"]:
        full_folder = os.path.join(project_dir, folder)
        for root, dirs, files in os.walk(full_folder):
            for file in files:
                if file.endswith(".dart"):
                    process_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
