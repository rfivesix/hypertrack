import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/models/exercise.dart';
import 'package:hypertrack/models/set_log.dart';
import 'package:hypertrack/services/statistics/domain/recovery/recovery_scoring_service.dart';

void main() {
  group('RecoveryScoringService', () {
    test('totalVolume sums weight * reps across sets', () {
      final sets = [
        SetLog(
          id: 1,
          workoutLogId: 1,
          exerciseName: 'Bench Press',
          setType: 'normal',
          weightKg: 100,
          reps: 5,
        ),
        SetLog(
          id: 2,
          workoutLogId: 1,
          exerciseName: 'Bench Press',
          setType: 'normal',
          weightKg: 80,
          reps: 8,
        ),
      ];

      expect(RecoveryScoringService.totalVolume(sets), 1140);
    });

    test('categoryVolume groups by category and skips zero volume', () {
      final sets = [
        SetLog(
          id: 1,
          workoutLogId: 1,
          exerciseName: 'Bench Press',
          setType: 'normal',
          weightKg: 100,
          reps: 5,
        ),
        SetLog(
          id: 2,
          workoutLogId: 1,
          exerciseName: 'Incline Press',
          setType: 'normal',
          weightKg: 80,
          reps: 8,
        ),
        SetLog(
          id: 3,
          workoutLogId: 1,
          exerciseName: 'Treadmill',
          setType: 'normal',
          weightKg: 0,
          reps: 0,
        ),
      ];

      final details = <String, Exercise>{
        'Bench Press': const Exercise(
          id: 1,
          nameDe: 'Bankdrücken',
          nameEn: 'Bench Press',
          descriptionDe: '',
          descriptionEn: '',
          categoryName: 'Chest',
          primaryMuscles: [],
          secondaryMuscles: [],
        ),
        'Incline Press': const Exercise(
          id: 2,
          nameDe: 'Schrägbankdrücken',
          nameEn: 'Incline Press',
          descriptionDe: '',
          descriptionEn: '',
          categoryName: 'Chest',
          primaryMuscles: [],
          secondaryMuscles: [],
        ),
      };

      final result = RecoveryScoringService.categoryVolume(sets, details);
      expect(result.length, 1);
      expect(result['Chest'], 1140);
    });

    test('share returns zero when total is zero', () {
      expect(RecoveryScoringService.share(10, 0), 0);
    });

    test('share returns value/total for positive values', () {
      expect(RecoveryScoringService.share(25, 100), 0.25);
    });

    test('share returns zero when value is zero and total is positive', () {
      expect(RecoveryScoringService.share(0, 100), 0);
    });
  });
}
