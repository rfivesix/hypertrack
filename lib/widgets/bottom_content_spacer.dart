//bottom_content_spacer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/workout_session_manager.dart';

/// Visual overlay heights (your glass bar + detached FAB)
const double kOverlayBaseHeight = 120.0; // bottom bar + FAB + margins
const double kOverlayRunningExtra = 68.0; // extra when workout bar is shown

/// A scrollable spacer to avoid content being hidden behind floating UI elements.
///
/// Accounts for the height of the bottom navigation bar, FAB, and running workout bar.
class BottomContentSpacer extends StatelessWidget {
  /// Optional [extra] padding to add beyond the standard overlay heights.
  final double extra; // if a screen needs a bit more room
  const BottomContentSpacer({super.key, this.extra = 0});

  @override
  Widget build(BuildContext context) {
    final bool isRunning = context.select<WorkoutSessionManager, bool>(
      (m) => m.isActive,
    );
    final double safe = MediaQuery.of(context).padding.bottom;
    final double h = kOverlayBaseHeight +
        (isRunning ? kOverlayRunningExtra : 0) +
        safe +
        extra;
    return SizedBox(height: h);
  }
}

/// Use in CustomScrollView: sliver variant.
class SliverBottomContentSpacer extends StatelessWidget {
  final double extra;
  const SliverBottomContentSpacer({super.key, this.extra = 0});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: BottomContentSpacer(extra: extra));
  }
}
