part of '../share_card_renderer.dart';

class _ShareScaffold extends StatelessWidget {
  const _ShareScaffold({required this.children, required this.labels});

  final List<Widget> children;
  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF111315) : Colors.white;
    final foreground = isDark ? Colors.white : const Color(0xFF161A1D);

    return DefaultTextStyle(
      style: TextStyle(
        color: foreground,
        decoration: TextDecoration.none,
        fontFamily: theme.textTheme.bodyMedium?.fontFamily,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: background),
        child: Padding(
          padding: const EdgeInsets.all(72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
              _TrainLibreFooter(labels: labels),
            ],
          ),
        ),
      ),
    );
  }
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 34,
        fontWeight: FontWeight.w900,
        decoration: TextDecoration.none,
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text, {this.maxLines = 2});

  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 78,
        height: 1.02,
        fontWeight: FontWeight.w900,
        decoration: TextDecoration.none,
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.64),
        fontSize: 34,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.none,
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: metrics
          .map(
            (metric) => SizedBox(
              width: 444,
              height: 210,
              child: _MetricTile(metric: metric),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2124) : const Color(0xFFF0F3F0),
        borderRadius: BorderRadius.circular(34),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.58),
                fontSize: 28,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
            ),
            Text(
              metric.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExercisePill extends StatelessWidget {
  const _ExercisePill({required this.count, required this.name});

  final String count;
  final String name;

  @override
  Widget build(BuildContext context) {
    return _ListPill(
      child: Row(
        children: [
          Text(
            count,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineExerciseGrid extends StatelessWidget {
  const _RoutineExerciseGrid({
    required this.rows,
    required this.remainingCount,
    required this.labels,
  });

  final List<RoutineShareExerciseSummary> rows;
  final int remainingCount;
  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 18,
      children: [
        for (final row in rows)
          SizedBox(
            width: 454,
            height: 126,
            child: _RoutinePill(name: row.name, detail: row.detail),
          ),
        if (remainingCount > 0)
          SizedBox(
            width: 454,
            height: 126,
            child: _MoreRoutinePill(text: labels.moreExercises(remainingCount)),
          ),
      ],
    );
  }
}

class _RoutinePill extends StatelessWidget {
  const _RoutinePill({required this.name, required this.detail});

  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2124) : const Color(0xFFF0F3F0),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 31,
                height: 1.02,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.62),
                fontSize: 25,
                height: 1.05,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreRoutinePill extends StatelessWidget {
  const _MoreRoutinePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2124) : const Color(0xFFF0F3F0),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Center(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _MuscleVolumePill extends StatelessWidget {
  const _MuscleVolumePill({required this.muscle, required this.maxVolume});

  final MuscleVolumeSummary muscle;
  final double maxVolume;

  @override
  Widget build(BuildContext context) {
    final ratio = maxVolume <= 0 ? 0.0 : (muscle.volume / maxVolume);
    return _ListPill(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  muscle.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                muscle.formattedVolume,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.1),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListPill extends StatelessWidget {
  const _ListPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1D2124) : const Color(0xFFF0F3F0),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
          child: child,
        ),
      ),
    );
  }
}

class _HugeMetric extends StatelessWidget {
  const _HugeMetric(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 96,
        fontWeight: FontWeight.w900,
        decoration: TextDecoration.none,
      ),
    );
  }
}

class _MoreLine extends StatelessWidget {
  const _MoreLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _TrainLibreFooter extends StatelessWidget {
  const _TrainLibreFooter({required this.labels});

  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Row(
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: SvgPicture.asset(
            'assets/icon/train-libre_icon_dark_green_no_bg.svg',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          labels.appName,
          style: TextStyle(
            color: muted,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            decoration: TextDecoration.none,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            labels.githubUrl.replaceFirst('https://', ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: muted,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value);

  final String label;
  final String value;
}
