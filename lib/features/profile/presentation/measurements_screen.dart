// lib/features/profile/presentation/measurements_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../domain/repositories/profile_repository.dart';
import '../../../generated/app_localizations.dart';
import '../domain/models/measurement_session.dart';
import 'add_measurement_screen.dart';
import '../../../util/design_constants.dart';
import '../../../widgets/common/bottom_content_spacer.dart';
import '../../../widgets/common/common.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/glass_fab.dart';
import '../../../widgets/common/global_app_bar.dart';
import 'widgets/measurement_chart_widget.dart';
import '../../../widgets/common/summary_card.dart';
import '../../../util/l10n_ext.dart';
import '../../../widgets/common/swipe_action_background.dart';
import '../../../services/unit_service.dart';

/// A screen for viewing and analyzing body measurement history.
class MeasurementsScreen extends StatefulWidget {
  final IProfileRepository? repository;

  const MeasurementsScreen({super.key, this.repository});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  late final IProfileRepository _repository = widget.repository ?? context.read<IProfileRepository>();
  bool _isLoading = true;
  List<MeasurementSession> _sessions = [];
  String? _selectedChartType;
  List<String> _availableMeasurementTypes = [];

  DateTimeRange _currentChartDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 29)),
    end: DateTime.now(),
  );
  final List<String> _chartDateRangeKeys = ['30D', '90D', '180D', 'All'];
  String _selectedChartRangeKey = '30D';

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _repository.getMeasurementSessions();

      final Set<String> types = {};
      for (final session in sessions) {
        for (final measurement in session.measurements) {
          types.add(measurement.type);
        }
      }

      if (mounted) {
        setState(() {
          _sessions = sessions;
          _availableMeasurementTypes = types.toList()..sort();
          if (_selectedChartType == null &&
              _availableMeasurementTypes.isNotEmpty) {
            _selectedChartType = _availableMeasurementTypes.contains('weight')
                ? 'weight'
                : _availableMeasurementTypes.first;
          }
        });
        _loadChartData();
      }
    } catch (e) {
      debugPrint('Error loading measurements: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadChartData() async {
    if (_selectedChartType == null || _selectedChartType!.isEmpty) return;

    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedChartRangeKey) {
      case '90D':
        start = now.subtract(const Duration(days: 89));
        break;
      case '180D':
        start = now.subtract(const Duration(days: 179));
        break;
      case 'All':
        final earliest =
            await _repository.getEarliestMeasurementDate();
        start = earliest ?? now;
        break;
      case '30D':
      default:
        start = now.subtract(const Duration(days: 29));
    }

    setState(() {
      _currentChartDateRange = DateTimeRange(start: start, end: end);
    });
  }

  void _navigateToCreateMeasurement() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                AddMeasurementScreen(initialDate: DateTime.now(), repository: _repository),
          ),
        )
        .then((_) => _loadMeasurements());
  }

  Future<void> _deleteMeasurementSession(MeasurementSession session) async {
    final sessionId = session.id;
    if (sessionId == null) {
      await _loadMeasurements();
      return;
    }

    try {
      await _repository.deleteMeasurementSession(
        sessionId,
      );
    } finally {
      if (mounted) {
        await _loadMeasurements();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(title: l10n.measurementsScreenTitle),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? _buildEmptyState(l10n, context)
              : ListView(
                  padding: DesignConstants.cardPadding.copyWith(
                    top: DesignConstants.cardPadding.top + topPadding,
                  ),
                  children: [
                    if (_availableMeasurementTypes.isNotEmpty) ...[
                      _buildChartSection(
                        l10n,
                        colorScheme,
                        Theme.of(context).textTheme,
                      ),
                      const SizedBox(height: DesignConstants.spacingXL),
                    ],
                    AppSectionHeader(title: l10n.all_measurements),
                    ..._sessions.map(
                      (session) => _buildMeasurementSessionCard(
                          l10n, colorScheme, session),
                    ),
                    const BottomContentSpacer(),
                  ],
                ),
      floatingActionButton: GlassFab(
        label: l10n.addMeasurement,
        onPressed: _navigateToCreateMeasurement,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, BuildContext context) {
    return Center(
      child: Padding(
        padding: DesignConstants.cardPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.measurementsEmptyState,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: DesignConstants.spacingXL),
            ElevatedButton.icon(
              onPressed: _navigateToCreateMeasurement,
              icon: const Icon(Icons.add),
              label: Text(l10n.addMeasurement),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final unitService = context.watch<UnitService>();
    if (_selectedChartType == null) return const SizedBox.shrink();

    return SummaryCard(
      padding: DesignConstants.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedChartType,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedChartType = newValue;
                        });
                        _loadChartData();
                      }
                    },
                    items: _availableMeasurementTypes
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          l10n.getLocalizedMeasurementName(value),
                        ),
                      );
                    }).toList(),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: _chartDateRangeKeys
                    .map((key) => _buildFilterButton(key, key))
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingS),
          MeasurementChartWidget(
            chartType: _selectedChartType!,
            dateRange: _currentChartDateRange,
            unit: _getMeasurementUnit(_selectedChartType!, unitService),
            repository: _repository,
          ),
        ],
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
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
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

  Widget _buildMeasurementSessionCard(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    MeasurementSession session,
  ) {
    final unitService = context.watch<UnitService>();
    final locale = Localizations.localeOf(context).toString();
    final sortedMeasurements = session.measurements.toList()
      ..sort((a, b) => a.type.compareTo(b.type));

    return Dismissible(
      key: Key('session_${session.id}'),
      direction: DismissDirection.endToStart,
      background: const SwipeActionBackground(
        color: Colors.redAccent,
        icon: Icons.delete,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        return await showDeleteConfirmation(context);
      },
      onDismissed: (direction) {
        setState(() {
          _sessions.removeWhere(
            (s) =>
                (s.id != null && s.id == session.id) ||
                (s.id == null && s.timestamp == session.timestamp),
          );
        });
        _deleteMeasurementSession(session);
      },
      child: SummaryCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: DesignConstants.screenPadding,
              title: Text(
                DateFormat.yMMMMEEEEd(
                  locale,
                ).add_Hm().format(session.timestamp),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.measurement_session_detail_view)),
                );
              },
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
            ),
            ...sortedMeasurements.map(
              (measurement) => ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                leading: _getMeasurementIcon(measurement.type),
                title: Text(l10n.getLocalizedMeasurementName(measurement.type)),
                trailing: Text(
                  "${_displayMeasurementValue(measurement.type, measurement.value, unitService).toStringAsFixed(1)} ${_getMeasurementUnit(measurement.type, unitService)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _displayMeasurementValue(
    String type,
    double value,
    UnitService unitService,
  ) {
    switch (type) {
      case 'weight':
        return unitService.convertDisplayValue(value, UnitDimension.weight);
      case 'neck':
      case 'shoulder':
      case 'chest':
      case 'left_bicep':
      case 'right_bicep':
      case 'left_forearm':
      case 'right_forearm':
      case 'abdomen':
      case 'waist':
      case 'hips':
      case 'left_thigh':
      case 'right_thigh':
      case 'left_calf':
      case 'right_calf':
        return unitService.convertDisplayValue(value, UnitDimension.height);
      default:
        return value;
    }
  }

  String _getMeasurementUnit(String type, UnitService unitService) {
    switch (type) {
      case 'weight':
        return unitService.suffixFor(UnitDimension.weight);
      case 'fat_percent':
        return '%';
      case 'neck':
      case 'shoulder':
      case 'chest':
      case 'left_bicep':
      case 'right_bicep':
      case 'left_forearm':
      case 'right_forearm':
      case 'abdomen':
      case 'waist':
      case 'hips':
      case 'left_thigh':
      case 'right_thigh':
      case 'left_calf':
      case 'right_calf':
        return unitService.suffixFor(UnitDimension.height);
      default:
        return '';
    }
  }

  Icon _getMeasurementIcon(String type) {
    switch (type) {
      case 'weight':
        return const Icon(Icons.monitor_weight);
      case 'fat_percent':
        return const Icon(Icons.fitness_center);
      case 'neck':
        return const Icon(Icons.accessibility_new);
      case 'shoulder':
        return const Icon(Icons.accessibility_new);
      case 'chest':
        return const Icon(Icons.accessibility_new);
      case 'left_bicep':
        return const Icon(Icons.accessibility_new);
      case 'right_bicep':
        return const Icon(Icons.accessibility_new);
      case 'abdomen':
        return const Icon(Icons.accessibility_new);
      case 'waist':
        return const Icon(Icons.accessibility_new);
      case 'hips':
        return const Icon(Icons.accessibility_new);
      default:
        return const Icon(Icons.straighten);
    }
  }
}
