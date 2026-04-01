import 'package:flutter/material.dart';
import '../../../generated/app_localizations.dart';
import '../data/sleep_day_repository.dart';
import 'details/depth_detail_page.dart';
import 'details/duration_detail_page.dart';
import 'details/heart_rate_detail_page.dart';
import 'details/interruptions_detail_page.dart';
import 'details/regularity_detail_page.dart';
import 'day/sleep_day_overview_page.dart';
import 'sleep_placeholder_pages.dart';
import 'widgets/sleep_period_scope_layout.dart';

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
  static DateTime _readAnchorDate(RouteSettings settings) {
    final args = settings.arguments;
    if (args is DateTime) {
      return DateTime(args.year, args.month, args.day);
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static SleepDayOverviewData? _readOverview(RouteSettings settings) {
    final args = settings.arguments;
    if (args is SleepDayOverviewData) return args;
    return null;
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SleepRouteNames.day:
        final selectedDay = _readAnchorDate(settings);
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SleepDayOverviewPage(
            selectedDay: selectedDay,
            initialScope: SleepPeriodScope.day,
          ),
        );
      case SleepRouteNames.week:
        final anchor = _readAnchorDate(settings);
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SleepDayOverviewPage(
            selectedDay: anchor,
            initialScope: SleepPeriodScope.week,
          ),
        );
      case SleepRouteNames.month:
        final anchor = _readAnchorDate(settings);
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SleepDayOverviewPage(
            selectedDay: anchor,
            initialScope: SleepPeriodScope.month,
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
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return SleepPlaceholderPage(
              title: l10n.sleepConnectHealthDataTitle,
              message: l10n.sleepConnectHealthDataMessage,
            );
          },
        );
      case SleepRouteNames.permissionDenied:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return SleepPlaceholderPage(
              title: l10n.sleepPermissionDeniedTitle,
              message: l10n.sleepPermissionDeniedMessage,
            );
          },
        );
      case SleepRouteNames.sourceUnavailable:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return SleepPlaceholderPage(
              title: l10n.sleepSourceUnavailableTitle,
              message: l10n.sleepSourceUnavailableMessage,
            );
          },
        );
      default:
        return null;
    }
  }

  static Future<void> openDay(BuildContext context, {bool replace = false}) {
    return openDayForDate(context, DateTime.now(), replace: replace);
  }

  static Future<void> openDayForDate(
    BuildContext context,
    DateTime day, {
    bool replace = false,
  }) {
    if (replace) {
      return Navigator.of(context).pushReplacementNamed(
        SleepRouteNames.day,
        arguments: day,
      );
    }
    return Navigator.of(context).pushNamed(SleepRouteNames.day, arguments: day);
  }

  static Future<void> openWeek(BuildContext context, {bool replace = false}) {
    return openWeekForDate(context, DateTime.now(), replace: replace);
  }

  static Future<void> openWeekForDate(
    BuildContext context,
    DateTime anchorDay, {
    bool replace = false,
  }) {
    if (replace) {
      return Navigator.of(context).pushReplacementNamed(
        SleepRouteNames.week,
        arguments: anchorDay,
      );
    }
    return Navigator.of(
      context,
    ).pushNamed(SleepRouteNames.week, arguments: anchorDay);
  }

  static Future<void> openMonth(BuildContext context, {bool replace = false}) {
    return openMonthForDate(context, DateTime.now(), replace: replace);
  }

  static Future<void> openMonthForDate(
    BuildContext context,
    DateTime anchorDay, {
    bool replace = false,
  }) {
    if (replace) {
      return Navigator.of(context).pushReplacementNamed(
        SleepRouteNames.month,
        arguments: anchorDay,
      );
    }
    return Navigator.of(
      context,
    ).pushNamed(SleepRouteNames.month, arguments: anchorDay);
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
