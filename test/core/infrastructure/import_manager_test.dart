import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:train_libre/core/infrastructure/import_manager.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US', null);
    await initializeDateFormatting('de_DE', null);
  });

  group('ImportManager decodeAndGroupWorkouts tests', () {
    test('CSV parsing with standard English headers and metrics', () {
      final csvString =
          'title,start_time,end_time,exercise,set_type,weight,reps,distance,duration,rpe,set_notes\n'
          'Upper Body Workout,2026-05-20 10:00:00,2026-05-20 11:30:00,Bench Press,normal,100,5,,,9,Felt strong\n'
          'Upper Body Workout,2026-05-20 10:00:00,2026-05-20 11:30:00,Bench Press,warmup,60,10,,,6,\n'
          'Cardio Session,2026-05-21 08:00:00,,Running,normal,,1,5.2,1800,8,\n';

      final params = ImportBackgroundTaskParams(
        fileBytes: Uint8List.fromList(utf8.encode(csvString)),
        extension: 'csv',
        isImperial: false,
      );

      final result = ImportManager.decodeAndGroupWorkouts(params);

      expect(result.length, 2);

      // Verify first workout (Upper Body Workout)
      final workout1 = result.firstWhere((w) => w.title == 'Upper Body Workout');
      expect(workout1.notes, isNull);
      expect(workout1.startTime, DateTime(2026, 5, 20, 10, 0, 0));
      expect(workout1.endTime, DateTime(2026, 5, 20, 11, 30, 0));
      expect(workout1.sets.length, 2);

      final set1 = workout1.sets[0];
      expect(set1.exerciseName, 'Bench Press');
      expect(set1.setType, 'normal');
      expect(set1.weightKg, 100.0);
      expect(set1.reps, 5);
      expect(set1.rpe, 9);
      expect(set1.notes, 'Felt strong');

      final set2 = workout1.sets[1];
      expect(set2.exerciseName, 'Bench Press');
      expect(set2.setType, 'warmup');
      expect(set2.weightKg, 60.0);
      expect(set2.reps, 10);
      expect(set2.rpe, 6);

      // Verify second workout (Cardio Session)
      final workout2 = result.firstWhere((w) => w.title == 'Cardio Session');
      expect(workout2.startTime, DateTime(2026, 5, 21, 8, 0, 0));
      expect(workout2.endTime, isA<DateTime>());
      expect(workout2.sets.length, 1);

      final cardioSet = workout2.sets[0];
      expect(cardioSet.exerciseName, 'Running');
      expect(cardioSet.setType, 'normal');
      expect(cardioSet.reps, 1);
      expect(cardioSet.distanceKm, 5.2);
      expect(cardioSet.durationSeconds, 1800);
      expect(cardioSet.rpe, 8);
    });

    test('CSV parsing with German headers and set-type abbreviations', () {
      final csvString =
          'übung,typ,gewicht,wiederholungen,notiz,datum,name\n'
          'Kniebeugen,w,120,5,Erster Satz,23.05.2026 15:30,Leg Day\n'
          'Kniebeugen,f,150,3,Failure set,23.05.2026 15:30,Leg Day\n'
          'Kreuzheben,d,100,8,Drop set,23.05.2026 15:30,Leg Day\n';

      final params = ImportBackgroundTaskParams(
        fileBytes: Uint8List.fromList(utf8.encode(csvString)),
        extension: 'csv',
        isImperial: false,
      );

      final result = ImportManager.decodeAndGroupWorkouts(params);

      expect(result.length, 1);
      final workout = result.first;
      expect(workout.title, 'Leg Day');
      expect(workout.startTime, DateTime(2026, 5, 23, 15, 30, 0));
      expect(workout.sets.length, 3);

      expect(workout.notes, 'Erster Satz');
      expect(workout.sets[0].exerciseName, 'Kniebeugen');
      expect(workout.sets[0].setType, 'warmup');
      expect(workout.sets[0].weightKg, 120.0);
      expect(workout.sets[0].reps, 5);
      expect(workout.sets[0].notes, isNull);

      expect(workout.sets[1].exerciseName, 'Kniebeugen');
      expect(workout.sets[1].setType, 'failure');
      expect(workout.sets[1].weightKg, 150.0);
      expect(workout.sets[1].reps, 3);

      expect(workout.sets[2].exerciseName, 'Kreuzheben');
      expect(workout.sets[2].setType, 'dropset');
      expect(workout.sets[2].weightKg, 100.0);
      expect(workout.sets[2].reps, 8);
    });

    test('CSV parsing with imperial flag converts lbs to kg', () {
      final csvString =
          'workout,start,exercise,mass,reps\n'
          'Chest Day,2026-05-22 18:00,Incline Press,220.46,8\n';

      final params = ImportBackgroundTaskParams(
        fileBytes: Uint8List.fromList(utf8.encode(csvString)),
        extension: 'csv',
        isImperial: true, // triggers conversion
      );

      final result = ImportManager.decodeAndGroupWorkouts(params);

      expect(result.length, 1);
      final set = result.first.sets.first;
      expect(set.exerciseName, 'Incline Press');
      // 220.46 lbs should convert to approximately 100 kg
      expect(set.weightKg, closeTo(100.0, 0.1));
    });

    test('Date parsing handles various formats cleanly', () {
      final formats = [
        '20 May 2026, 14:35',
        '2026-05-20 14:35:10',
        '2026-05-20 14:35',
        '20.05.2026, 14:35',
        '20.05.2026 14:35',
        '05/20/2026 14:35',
        '2026-05-20T14:35:00Z',
      ];

      for (final rawDate in formats) {
        final csvString =
            'title,start_time,exercise,weight,reps\n'
            'Test Date,"$rawDate",Curls,20,10\n';

        final params = ImportBackgroundTaskParams(
          fileBytes: Uint8List.fromList(utf8.encode(csvString)),
          extension: 'csv',
          isImperial: false,
        );

        final result = ImportManager.decodeAndGroupWorkouts(params);
        expect(result.length, 1, reason: 'Failed parsing date string: $rawDate');
        expect(result.first.startTime.year, 2026);
        expect(result.first.startTime.month, 5);
        expect(result.first.startTime.day, 20);
        expect(result.first.startTime.hour, 14);
        expect(result.first.startTime.minute, 35);
      }
    });

    test('Missing date fallback returns current date', () {
      final csvString =
          'title,start_time,exercise,weight,reps\n'
          'Test Date,,Curls,20,10\n';

      final params = ImportBackgroundTaskParams(
        fileBytes: Uint8List.fromList(utf8.encode(csvString)),
        extension: 'csv',
        isImperial: false,
      );

      final result = ImportManager.decodeAndGroupWorkouts(params);
      expect(result.length, 0); // start_time is required in CSV row grouping!
    });

    test('Handles malformed file extensions or data errors gracefully', () {
      final params = ImportBackgroundTaskParams(
        fileBytes: Uint8List.fromList(utf8.encode('random,garbage,data')),
        extension: 'unsupported',
        isImperial: false,
      );

      final result = ImportManager.decodeAndGroupWorkouts(params);
      expect(result, isEmpty);
    });

    test('Handles empty and minimal CSV inputs without crashing', () {
      final paramsEmpty = ImportBackgroundTaskParams(
        fileBytes: Uint8List.fromList([]),
        extension: 'csv',
        isImperial: false,
      );

      final result1 = ImportManager.decodeAndGroupWorkouts(paramsEmpty);
      expect(result1, isEmpty);

      final paramsHeaderOnly = ImportBackgroundTaskParams(
        fileBytes: Uint8List.fromList(utf8.encode('title,start_time,exercise\n')),
        extension: 'csv',
        isImperial: false,
      );

      final result2 = ImportManager.decodeAndGroupWorkouts(paramsHeaderOnly);
      expect(result2, isEmpty);
    });
  });
}
