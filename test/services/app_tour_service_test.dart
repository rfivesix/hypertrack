import 'package:flutter_test/flutter_test.dart';
import 'package:hypertrack/services/app_tour_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('queues and consumes post-onboarding offer once', () async {
    final service = AppTourService.instance;

    await service.queuePostOnboardingOffer();

    final first = await service.consumePendingEntryPoint();
    final second = await service.consumePendingEntryPoint();

    expect(first, AppTourEntryPoint.postOnboardingOffer);
    expect(second, isNull);
  });

  test('settings restart requests direct start and resets progress flags',
      () async {
    final service = AppTourService.instance;

    await service.markCompleted();
    await service.requestRestartFromSettings();

    final entry = await service.consumePendingEntryPoint();
    final progress = await service.loadProgress();

    expect(entry, AppTourEntryPoint.settingsRestart);
    expect(progress.hasBeenOffered, isTrue);
    expect(progress.wasCompleted, isFalse);
    expect(progress.wasSkipped, isFalse);
  });

  test('skip and complete update persisted progress', () async {
    final service = AppTourService.instance;

    await service.markSkipped();
    final skipped = await service.loadProgress();

    await service.markCompleted();
    final completed = await service.loadProgress();

    expect(skipped.hasBeenOffered, isTrue);
    expect(skipped.wasSkipped, isTrue);
    expect(skipped.wasCompleted, isFalse);

    expect(completed.hasBeenOffered, isTrue);
    expect(completed.wasCompleted, isTrue);
    expect(completed.wasSkipped, isFalse);
  });
}
