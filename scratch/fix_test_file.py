import os

test_file = 'test/workout_session_manager_test.dart'
with open(test_file, 'r') as f:
    content = f.read()

# Replace:
#          localDataSource: WorkoutLocalDataSource(
#            database,
#            workoutDb: workoutDb,
#          ),
import re
content = re.sub(r'WorkoutLocalDataSource\(\s*database,\s*workoutDb:\s*workoutDb,\s*\)', 'WorkoutLocalDataSource(database)', content)
with open(test_file, 'w') as f:
    f.write(content)
