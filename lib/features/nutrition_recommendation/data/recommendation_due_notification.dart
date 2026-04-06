import '../../../services/local_notification_service.dart';

abstract interface class AdaptiveRecommendationDueNotifier {
  Future<void> notifyRecommendationDue({
    required String dueWeekKey,
    required DateTime dueAt,
  });
}

class NoopAdaptiveRecommendationDueNotifier
    implements AdaptiveRecommendationDueNotifier {
  const NoopAdaptiveRecommendationDueNotifier();

  @override
  Future<void> notifyRecommendationDue({
    required String dueWeekKey,
    required DateTime dueAt,
  }) async {}
}

class LocalAdaptiveRecommendationDueNotifier
    implements AdaptiveRecommendationDueNotifier {
  const LocalAdaptiveRecommendationDueNotifier();

  @override
  Future<void> notifyRecommendationDue({
    required String dueWeekKey,
    required DateTime dueAt,
  }) {
    return LocalNotificationService.instance
        .showAdaptiveRecommendationDueNotification();
  }
}
