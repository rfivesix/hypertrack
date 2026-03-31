import 'package:flutter/material.dart';

import '../data/sleep_day_repository.dart';
import 'details/depth_detail_page.dart';
import 'details/duration_detail_page.dart';
import 'details/heart_rate_detail_page.dart';
import 'details/interruptions_detail_page.dart';
import 'details/regularity_detail_page.dart';
import 'day/sleep_day_overview_page.dart';

class SleepRouteNames {
  static const day = '/sleep/day';
  static const durationDetail = '/sleep/day/duration';
  static const heartRateDetail = '/sleep/day/heart-rate';
  static const interruptionsDetail = '/sleep/day/interruptions';
  static const depthDetail = '/sleep/day/depth';
  static const regularityDetail = '/sleep/day/regularity';
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
      default:
        return null;
    }
  }

  static Future<void> openDay(BuildContext context) {
    return Navigator.of(context).pushNamed(SleepRouteNames.day);
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
