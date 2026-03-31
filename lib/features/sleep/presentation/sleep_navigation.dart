import 'package:flutter/material.dart';

import '../data/sleep_day_repository.dart';
import 'details/depth_detail_page.dart';
import 'details/duration_detail_page.dart';
import 'details/heart_rate_detail_page.dart';
import 'details/interruptions_detail_page.dart';
import 'details/regularity_detail_page.dart';
import 'day/sleep_day_overview_page.dart';
import 'sleep_placeholder_pages.dart';

class SleepRouteNames {
  static const day = '/sleep/day';
  static const week = '/sleep/week';
  static const month = '/sleep/month';
  static const durationDetail = '/sleep/day/duration';
  static const heartRateDetail = '/sleep/day/heart-rate';
  static const interruptionsDetail = '/sleep/day/interruptions';
  static const depthDetail = '/sleep/day/depth';
  static const regularityDetail = '/sleep/day/regularity';
  static const connectHealthData = '/sleep/state/connect-health-data';
  static const permissionDenied = '/sleep/state/permission-denied';
  static const sourceUnavailable = '/sleep/state/source-unavailable';
}

class SleepNavigation {
  static SleepDayOverviewData? _readOverview(RouteSettings settings) {
    final args = settings.arguments;
    if (args is SleepDayOverviewData) return args;
    return null;
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SleepRouteNames.day:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SleepDayOverviewPage(),
        );
      case SleepRouteNames.week:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SleepPlaceholderPage(
            title: 'Sleep week',
            message: 'Week overview is intentionally deferred in this batch.',
          ),
        );
      case SleepRouteNames.month:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SleepPlaceholderPage(
            title: 'Sleep month',
            message: 'Month overview is intentionally deferred in this batch.',
          ),
        );
      case SleepRouteNames.durationDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DurationDetailPage(overview: _readOverview(settings)),
        );
      case SleepRouteNames.heartRateDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              HeartRateDetailPage(overview: _readOverview(settings)),
        );
      case SleepRouteNames.interruptionsDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              InterruptionsDetailPage(overview: _readOverview(settings)),
        );
      case SleepRouteNames.depthDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DepthDetailPage(overview: _readOverview(settings)),
        );
      case SleepRouteNames.regularityDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              RegularityDetailPage(overview: _readOverview(settings)),
        );
      case SleepRouteNames.connectHealthData:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SleepPlaceholderPage(
            title: 'Connect health data',
            message:
                'Connect HealthKit or Health Connect to import sleep records.',
          ),
        );
      case SleepRouteNames.permissionDenied:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SleepPlaceholderPage(
            title: 'Permission denied',
            message:
                'Sleep permissions are denied. Open settings to grant access.',
          ),
        );
      case SleepRouteNames.sourceUnavailable:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SleepPlaceholderPage(
            title: 'Source unavailable',
            message:
                'Sleep data source is unavailable or not installed on this device.',
          ),
        );
      default:
        return null;
    }
  }

  static Future<void> openDay(BuildContext context) {
    return Navigator.of(context).pushNamed(SleepRouteNames.day);
  }

  static Future<void> openWeek(BuildContext context) {
    return Navigator.of(context).pushNamed(SleepRouteNames.week);
  }

  static Future<void> openMonth(BuildContext context) {
    return Navigator.of(context).pushNamed(SleepRouteNames.month);
  }

  static Future<void> openDurationDetail(
    BuildContext context, {
    required SleepDayOverviewData overview,
  }) {
    return Navigator.of(
      context,
    ).pushNamed(SleepRouteNames.durationDetail, arguments: overview);
  }

  static Future<void> openHeartRateDetail(
    BuildContext context, {
    required SleepDayOverviewData overview,
  }) {
    return Navigator.of(
      context,
    ).pushNamed(SleepRouteNames.heartRateDetail, arguments: overview);
  }

  static Future<void> openInterruptionsDetail(
    BuildContext context, {
    required SleepDayOverviewData overview,
  }) {
    return Navigator.of(
      context,
    ).pushNamed(SleepRouteNames.interruptionsDetail, arguments: overview);
  }

  static Future<void> openDepthDetail(
    BuildContext context, {
    required SleepDayOverviewData overview,
  }) {
    return Navigator.of(
      context,
    ).pushNamed(SleepRouteNames.depthDetail, arguments: overview);
  }

  static Future<void> openRegularityDetail(
    BuildContext context, {
    required SleepDayOverviewData overview,
  }) {
    return Navigator.of(
      context,
    ).pushNamed(SleepRouteNames.regularityDetail, arguments: overview);
  }
}
