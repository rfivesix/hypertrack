import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/workout/domain/log_workout_set_use_case.dart';
import 'package:train_libre/features/workout/domain/models/set_log.dart';
import 'package:train_libre/features/workout/domain/models/set_template.dart';

void main() {
  group('LogWorkoutSetUseCase', () {
    final useCase = LogWorkoutSetUseCase();

    test('RIR optional null behavior defaults strictly to null', () {
      final oldLog = SetLog(
        id: 1,
        workoutLogId: 10,
        exerciseName: 'Bench Press',
        setType: 'normal',
        rir: null,
      );

      final result = useCase.execute(
        oldLog: oldLog,
        rir: null,
      );

      expect(result.updatedSet.rir, isNull);
    });

    test('RIR updates to value and can be cleared back to null', () {
      final oldLog = SetLog(
        id: 1,
        workoutLogId: 10,
        exerciseName: 'Bench Press',
        setType: 'normal',
        rir: null,
      );

      final resultWithRir = useCase.execute(
        oldLog: oldLog,
        rir: 3,
      );
      expect(resultWithRir.updatedSet.rir, equals(3));

      final resultCleared = useCase.execute(
        oldLog: resultWithRir.updatedSet,
        clearRir: true,
      );
      expect(resultCleared.updatedSet.rir, isNull);
    });

    test('Rep range average fallback parses hyphen range and rounds correctly', () {
      final oldLog = SetLog(
        id: 1,
        workoutLogId: 10,
        exerciseName: 'Bench Press',
        setType: 'normal',
        reps: null,
        weightKg: null,
        isCompleted: false,
      );

      final template = SetTemplate(
        id: 100,
        setType: 'normal',
        targetReps: '8-12',
        targetWeight: 60.0,
      );

      // Complete the set without manually entered reps/weight
      final result = useCase.execute(
        oldLog: oldLog,
        template: template,
        isCompleted: true,
      );

      // Average of 8 and 12 is 10
      expect(result.updatedSet.reps, equals(10));
      expect(result.updatedSet.weightKg, equals(60.0));
      expect(result.updatedSet.isCompleted, isTrue);
    });

    test('Rep range average fallback handles odd range and rounds correctly', () {
      final oldLog = SetLog(
        id: 1,
        workoutLogId: 10,
        exerciseName: 'Squat',
        setType: 'normal',
        reps: null,
        weightKg: null,
        isCompleted: false,
      );

      final template = SetTemplate(
        id: 100,
        setType: 'normal',
        targetReps: '8-11', // (8 + 11) / 2 = 9.5 -> rounds to 10
      );

      final result = useCase.execute(
        oldLog: oldLog,
        template: template,
        isCompleted: true,
      );

      expect(result.updatedSet.reps, equals(10));
    });

    test('Rep range average fallback handles whitespace around hyphen', () {
      final oldLog = SetLog(
        id: 1,
        workoutLogId: 10,
        exerciseName: 'Deadlift',
        setType: 'normal',
        reps: null,
        weightKg: null,
        isCompleted: false,
      );

      final template = SetTemplate(
        id: 100,
        setType: 'normal',
        targetReps: '  5  -  7  ', // (5 + 7) / 2 = 6
      );

      final result = useCase.execute(
        oldLog: oldLog,
        template: template,
        isCompleted: true,
      );

      expect(result.updatedSet.reps, equals(6));
    });
  });
}
