// lib/screens/home.dart (Final & SWR-Lade-Logik)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tracked_supplement.dart';
import '../models/supplement.dart';
//import 'supplement_hub_screen.dart';
import 'supplement_track_screen.dart';
import '../util/design_constants.dart';
import '../widgets/supplement_summary_widget.dart';
import '../data/database_helper.dart';
import '../data/product_database_helper.dart';
import '../data/workout_database_helper.dart';
import '../generated/app_localizations.dart';
import '../models/chart_data_point.dart';
import '../models/daily_nutrition.dart';
import 'measurements_screen.dart';
import 'nutrition_screen.dart';
import '../widgets/measurement_chart_widget.dart';
import '../widgets/nutrition_summary_widget.dart';
import '../widgets/summary_card.dart';
import '../util/date_util.dart';

/// The primary dashboard of the application.
///
/// Aggregates data from nutrition logs, supplement tracking, workout history,
/// and body measurements into a high-level summary for the user.
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  DailyNutrition? _nutritionData;
  String _recommendationText = "";
  // KORREKTUR: _isLoading wird jetzt nur für den ERSTEN Ladevorgang auf true gesetzt
  bool _isLoading = true;

  List<ChartDataPoint> _weightChartData = [];
  DateTimeRange _currentDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 29)),
    end: DateTime.now(),
  );
  final String _chartType = 'weight';
  Map<String, int> _workoutStats = {};
  bool _isFirstLoad = true;
  List<TrackedSupplement> _trackedSupplements = [];

  final List<String> _chartDateRangeKeys = ['30D', '90D', 'All'];
  String _selectedChartRangeKey = '30D';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      loadAllHomeScreenData(
        showLoadingIndicator: true,
      ); // KORREKTUR: Zeige Indikator nur beim ersten Mal
      _isFirstLoad = false;
    }
  }

  Future<void> loadAllHomeScreenData({
    bool showLoadingIndicator = false,
  }) async {
    if (!mounted) return;

    // FIX: Only set _isLoading if the indicator should actually be shown
    if (showLoadingIndicator) {
      setState(() => _isLoading = true);
    }

    // --- LOAD DATA HERE ---
    final l10n = AppLocalizations.of(context)!;
    final dbHelper = DatabaseHelper.instance;
    final today = DateTime.now();
    final goals = await dbHelper.getGoalsForDate(today);
    final targetCalories = goals?.targetCalories ?? 2500;
    final targetProtein = goals?.targetProtein ?? 180;
    final targetCarbs = goals?.targetCarbs ?? 250;
    final targetFat = goals?.targetFat ?? 80;
    final targetWater = goals?.targetWater ?? 3000;

    final entries = await dbHelper.getEntriesForDate(DateTime.now());
    final fluidEntries = await dbHelper.getFluidEntriesForDate(DateTime.now());
    final waterIntake = fluidEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.quantityInMl,
    );
    final newTodaysNutrition = DailyNutrition(
      targetCalories: targetCalories,
      targetProtein: targetProtein,
      targetCarbs: targetCarbs,
      targetFat: targetFat,
      targetWater: targetWater,
    );
    newTodaysNutrition.water = waterIntake;

    final newWorkoutStats =
        await _getWorkoutStats(); // KORREKTUR: Methode umbenannt
    await _loadChartData(); // Lädt Chart-Daten und setzt _weightChartData

    for (final entry in entries) {
      final foodItem = await ProductDatabaseHelper.instance.getProductByBarcode(
        entry.barcode,
      );
      if (foodItem != null) {
        newTodaysNutrition.calories +=
            (foodItem.calories / 100 * entry.quantityInGrams).round();
        newTodaysNutrition.protein +=
            (foodItem.protein / 100 * entry.quantityInGrams).round();
        newTodaysNutrition.carbs +=
            (foodItem.carbs / 100 * entry.quantityInGrams).round();
        newTodaysNutrition.fat += (foodItem.fat / 100 * entry.quantityInGrams)
            .round();
      }
    }

    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    final recentEntries = await dbHelper.getEntriesForDateRange(
      sevenDaysAgo,
      today,
    );
    String newRecommendation = l10n.recommendationDefault;
    if (recentEntries.isNotEmpty) {
      final uniqueDaysTracked = recentEntries
          .map((e) => DateFormat.yMd().format(e.timestamp))
          .toSet();
      final numberOfTrackedDays = uniqueDaysTracked.length;
      int totalRecentCalories = 0;
      for (final entry in recentEntries) {
        final foodItem = await ProductDatabaseHelper.instance
            .getProductByBarcode(entry.barcode);
        if (foodItem != null) {
          totalRecentCalories +=
              (foodItem.calories / 100 * entry.quantityInGrams).round();
        }
      }
      int totalTargetCalories = 0;
      for (final dateString in uniqueDaysTracked) {
        final d = DateFormat.yMd().parse(dateString);
        final dGoals = await DatabaseHelper.instance.getGoalsForDate(d);
        totalTargetCalories += dGoals?.targetCalories ?? 2500;
      }
      final difference = totalRecentCalories - totalTargetCalories;
      if (numberOfTrackedDays > 1) {
        final tolerance = totalTargetCalories * 0.05;
        if (difference > tolerance) {
          newRecommendation = l10n.recommendationOverTarget(
            numberOfTrackedDays,
            difference.round(),
          );
        } else if (difference < -tolerance) {
          newRecommendation = l10n.recommendationUnderTarget(
            numberOfTrackedDays,
            (-difference).round(),
          );
        } else {
          newRecommendation = l10n.recommendationOnTarget(numberOfTrackedDays);
        }
      } else {
        newRecommendation = l10n.recommendationFirstEntry;
      }
    }

    // NEU: Lade Supplement-Daten
    final supplementsForDate = await dbHelper.getSupplementsForDate(
      DateTime.now(),
    );
    final allSupplements = await dbHelper.getAllSupplements();
    final todaysSupplementLogs = await dbHelper.getSupplementLogsForDate(
      DateTime.now(),
    );
    final Map<int, double> todaysDoses = {};
    for (final log in todaysSupplementLogs) {
      todaysDoses.update(
        log.supplementId,
        (value) => value + log.dose,
        ifAbsent: () => log.dose,
      );
    }

    final Map<int, Supplement> byId = {
      for (final s in allSupplements)
        if (s.id != null) s.id!: s,
    };

    final List<TrackedSupplement> trackedSupps = [];
    for (final s in supplementsForDate) {
      final hasLog = todaysDoses.containsKey(s.id);
      if (s.isTracked || hasLog) {
        trackedSupps.add(
          TrackedSupplement(
            supplement: s,
            totalDosedToday: todaysDoses[s.id] ?? 0.0,
          ),
        );
      }
    }
    for (final id in todaysDoses.keys) {
      if (!trackedSupps.any((ts) => ts.supplement.id == id)) {
        if (byId.containsKey(id)) {
          trackedSupps.add(
            TrackedSupplement(
              supplement: byId[id]!,
              totalDosedToday: todaysDoses[id]!,
            ),
          );
        }
      }
    }

    // --- DATEN LADEN ENDE ---

    if (mounted) {
      setState(() {
        _nutritionData = newTodaysNutrition; // Neue Daten
        _recommendationText = newRecommendation; // Neue Daten
        _workoutStats = newWorkoutStats; // Neue Daten
        _trackedSupplements = trackedSupps; // NEU
        _isLoading = false; // Ladezustand beenden
      });
    }
  }

  Future<void> _loadChartData() async {
    // KORRIGIERT: Die Logik zur Berechnung des Zeitraums wird hierher verschoben.
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedChartRangeKey) {
      case '90D':
        start = now.subtract(const Duration(days: 89));
        break;
      case 'All':
        // Für "Alle" holen wir das früheste Datum aus der Datenbank
        final earliest = await DatabaseHelper.instance
            .getEarliestMeasurementDate();
        start = earliest ?? now;
        break;
      case '30D':
      default:
        start = now.subtract(const Duration(days: 29));
    }

    final normalizedStart = DateTime(start.year, start.month, start.day);

    // Wichtig: Den State für den Datumsbereich hier aktualisieren!
    if (!mounted) return;
    setState(() {
      _currentDateRange = DateTimeRange(start: normalizedStart, end: end);
    });

    // Der Rest der Methode bleibt gleich, lädt aber jetzt mit dem korrekten Zeitbereich.
    final sessions = await DatabaseHelper.instance.getMeasurementSessions();
    final points = <ChartDataPoint>[];

    for (final s in sessions) {
      if (s.timestamp.isBefore(normalizedStart) || s.timestamp.isAfter(end)) {
        continue;
      }

      for (final m in s.measurements) {
        if (m.type == _chartType) {
          points.add(
            ChartDataPoint(date: s.timestamp, value: m.value.toDouble()),
          );
        }
      }
    }

    points.sort((a, b) => a.date.compareTo(b.date));

    if (!mounted) return;
    setState(() {
      _weightChartData = points;
    });
  }

  // KORREKTUR: Methode umbenannt, damit sie Daten ZURÜCKGIBT
  Future<Map<String, int>> _getWorkoutStats() async {
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 6));

    final logs = await WorkoutDatabaseHelper.instance
        .getWorkoutLogsForDateRange(sevenDaysAgo, today);

    int count = logs.length;
    int duration = 0;
    int volume = 0;

    for (final log in logs) {
      if (log.endTime != null) {
        duration += log.endTime!.difference(log.startTime).inMinutes;
      }
      for (final set in log.sets) {
        volume += ((set.weightKg ?? 0) * (set.reps ?? 0)).round();
      }
    }
    return {'count': count, 'duration': duration, 'volume': volume};
  }

  void _navigateTimeRange(bool forward) {
    // "All" deckt sowieso alles ab – kein Paging
    if (_selectedChartRangeKey == 'All') return;

    final int days = _selectedChartRangeKey == '90D' ? 90 : 30;
    final delta = Duration(days: days);

    final newStart = forward
        ? _currentDateRange.start.add(delta)
        : _currentDateRange.start.subtract(delta);
    final newEnd = forward
        ? _currentDateRange.end.add(delta)
        : _currentDateRange.end.subtract(delta);

    setState(() {
      _currentDateRange = DateTimeRange(start: newStart, end: newEnd);
    });

    // Daten für die neue Range nachladen
    _loadChartData();
  }

  void _navigateToNutritionScreen() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const NutritionScreen()))
        .then((_) => loadAllHomeScreenData(showLoadingIndicator: false));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // KORREKTUR: Zeige den Ladeindikator nur, wenn _isLoading true UND keine Daten vorhanden sind
    final showLoadingOverlay = _isLoading && _nutritionData == null;

    return Scaffold(
      body: Stack(
        children: [
          // KORREKTUR: Der RefreshIndicator ist immer da, damit man ziehen kann.
          // Der Inhalt wird immer angezeigt, auch wenn _isLoading true ist (alte Daten).
          RefreshIndicator(
            onRefresh: () => loadAllHomeScreenData(
              showLoadingIndicator: false,
            ), // KORREKTUR: Kein Ladeindikator bei manueller Aktualisierung
            child: ListView(
              padding: DesignConstants.screenPadding,
              children: [
                _buildBannerCard(l10n),
                const SizedBox(height: DesignConstants.spacingS),
                GestureDetector(
                  onTap: _navigateToNutritionScreen,
                  child: _nutritionData != null
                      ? NutritionSummaryWidget(
                          nutritionData: _nutritionData!,
                          isExpandedView: false,
                          l10n: l10n,
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: DesignConstants.spacingS),
                SupplementSummaryWidget(
                  trackedSupplements: _trackedSupplements,
                  onTap: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) => const SupplementTrackScreen(),
                        ),
                      )
                      .then(
                        (_) =>
                            loadAllHomeScreenData(showLoadingIndicator: false),
                      ),
                ),
                if (_weightChartData.isNotEmpty)
                  const SizedBox(height: DesignConstants.spacingS),
                GestureDetector(
                  onTap: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) => const MeasurementsScreen(),
                        ),
                      )
                      .then((_) => loadAllHomeScreenData()),
                  child: _buildWeightChartCard(context, colorScheme, l10n),
                ),
                const SizedBox(height: DesignConstants.spacingS),
                _buildWorkoutStatsCard(l10n),
              ],
            ),
          ),
          // KORREKTUR: Lade-Overlay nur anzeigen, wenn showLoadingOverlay true ist
          if (showLoadingOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(AppLocalizations l10n) {
    // KORREKTUR: externalMargin wird jetzt gesetzt
    return SummaryCard(
      //internalPadding: const EdgeInsets.symmetric(horizontal: 16.0),
      //externalMargin: EdgeInsets.zero, // Wichtig, da ListView.separated den Abstand steuert
      child: Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          _recommendationText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // In lib/screens/home.dart, innerhalb von HomeState

  Widget _buildWeightChartCard(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return SummaryCard(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.weightHistoryTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8.0,
                      alignment: WrapAlignment.end,
                      children: _chartDateRangeKeys
                          .map((key) => _buildFilterButton(key, key))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _navigateTimeRange(false),
                ),
                Text(
                  "${DateFormat.MMMd().format(_currentDateRange.start)} - ${DateFormat.MMMd().format(_currentDateRange.end)}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentDateRange.end.isSameDate(DateTime.now())
                      ? null
                      : () => _navigateTimeRange(true),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingL),
            MeasurementChartWidget(
              chartType: _chartType,
              dateRange: _currentDateRange,
              // KORREKTUR: Die folgende Zeile wurde entfernt
              // lineColor: colorScheme.secondary,
              unit: "kg",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String key) {
    final theme = Theme.of(context);
    final isSelected = _selectedChartRangeKey == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartRangeKey = key;
        });
        _loadChartData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutStatsCard(AppLocalizations l10n) {
    // KORREKTUR: externalMargin wird jetzt gesetzt
    return SummaryCard(
      //externalMargin: EdgeInsets.zero, // Wichtig
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.workoutStatsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: DesignConstants.spacingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Icon(Icons.fitness_center, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      "${_workoutStats['count'] ?? 0}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.workoutsLabel,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.timer, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      "${_workoutStats['duration'] ?? 0} min",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.durationLabel,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.monitor_weight, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      "${_workoutStats['volume'] ?? 0} kg",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l10n.volumeLabel,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
