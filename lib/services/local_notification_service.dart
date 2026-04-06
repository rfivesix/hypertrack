import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Handles local notification setup and rest timer notifications.
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const int restTimerNotificationId = 8801;
  static const int adaptiveRecommendationDueNotificationId = 8802;
  static const String _restChannelId = 'rest_timer_channel';
  static const String _adaptiveRecommendationChannelId =
      'adaptive_recommendation_channel';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings: settings);
    await _requestPermissions();
    tz.initializeTimeZones();
    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  NotificationDetails _restNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _restChannelId,
        'Rest Timer',
        channelDescription: 'Alerts when the workout rest timer is finished.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      macOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
  }

  NotificationDetails _adaptiveRecommendationNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _adaptiveRecommendationChannelId,
        'Adaptive nutrition',
        channelDescription: 'Alerts when a new adaptive recommendation is due.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      macOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
  }

  ({String title, String body}) _localizedRestTexts() {
    final languageCode = WidgetsBinding
        .instance.platformDispatcher.locale.languageCode
        .toLowerCase();

    if (languageCode == 'de') {
      return (
        title: 'Pause beendet',
        body:
            'Dein Pausentimer ist abgelaufen. Bereit fuer den naechsten Satz.',
      );
    }

    return (
      title: 'Rest finished',
      body: 'Your pause timer is over. Ready for the next set.',
    );
  }

  ({String title, String body}) _localizedAdaptiveRecommendationDueTexts() {
    final languageCode = WidgetsBinding
        .instance.platformDispatcher.locale.languageCode
        .toLowerCase();

    if (languageCode == 'de') {
      return (
        title: 'Neue adaptive Empfehlung verfuegbar',
        body:
            'Deine neue woechentliche adaptive Ernaehrungsempfehlung ist jetzt faellig.',
      );
    }

    return (
      title: 'New adaptive recommendation due',
      body:
          'Your new weekly adaptive nutrition recommendation is now available.',
    );
  }

  Future<void> scheduleRestTimerDoneNotification({
    required int secondsFromNow,
  }) async {
    if (!_isInitialized) await initialize();
    final texts = _localizedRestTexts();

    final when = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(seconds: secondsFromNow.clamp(0, 24 * 60 * 60)));

    try {
      await _plugin.zonedSchedule(
        id: restTimerNotificationId,
        title: texts.title,
        body: texts.body,
        scheduledDate: when,
        notificationDetails: _restNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Fallback for devices that do not allow exact alarms.
      await _plugin.zonedSchedule(
        id: restTimerNotificationId,
        title: texts.title,
        body: texts.body,
        scheduledDate: when,
        notificationDetails: _restNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> showRestTimerDoneNotification() async {
    if (!_isInitialized) await initialize();
    final texts = _localizedRestTexts();

    await _plugin.show(
      id: restTimerNotificationId,
      title: texts.title,
      body: texts.body,
      notificationDetails: _restNotificationDetails(),
    );
  }

  Future<void> cancelRestTimerNotification() async {
    if (!_isInitialized) return;
    await _plugin.cancel(id: restTimerNotificationId);
  }

  Future<void> showAdaptiveRecommendationDueNotification() async {
    if (!_isInitialized) await initialize();
    final texts = _localizedAdaptiveRecommendationDueTexts();

    await _plugin.show(
      id: adaptiveRecommendationDueNotificationId,
      title: texts.title,
      body: texts.body,
      notificationDetails: _adaptiveRecommendationNotificationDetails(),
    );
  }
}
