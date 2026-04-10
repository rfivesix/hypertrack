import 'package:flutter/services.dart';

class WidgetLaunchService {
  WidgetLaunchService._();

  static final WidgetLaunchService instance = WidgetLaunchService._();

  static const MethodChannel _channel =
      MethodChannel('hypertrack.widget/launcher');

  Future<void> initialize(
      {required Future<void> Function() onOpenDiary}) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetAction') {
        final args = call.arguments;
        if (args is Map && args['action'] == 'openDiary') {
          await onOpenDiary();
        }
      }
    });

    try {
      final action = await _channel.invokeMethod<String>('getInitialAction');
      if (action == 'openDiary') {
        await onOpenDiary();
      }
    } on MissingPluginException {
      // Unsupported platform in MVP.
    } on PlatformException {
      // Ignore launcher bridge failures.
    }
  }
}
