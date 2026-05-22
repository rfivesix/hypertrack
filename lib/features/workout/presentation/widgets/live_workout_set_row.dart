import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/haptic_feedback_service.dart';
import '../../../../services/unit_service.dart';
import '../../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../domain/models/set_log.dart';
import '../../domain/models/set_template.dart';
import '../live_workout_view_model.dart';

/// An interactive row representing a single set in an active workout session.
///
/// Supports text fields for weight/distance, reps/time, RIR/intensity, type selections,
/// personal record tags, last session copy shortcuts, and swipe-to-delete actions.
class LiveWorkoutSetRow extends StatelessWidget {
  final int setIndex;
  final int rowIndex;
  final int templateId;
  final SetLog setLog;
  final List<SetLog> lastPerfSets;
  final SetTemplate template;
  final LiveWorkoutViewModel manager;
  final bool isCardio;

  const LiveWorkoutSetRow({
    super.key,
    required this.setIndex,
    required this.rowIndex,
    required this.templateId,
    required this.setLog,
    required this.lastPerfSets,
    required this.template,
    required this.manager,
    required this.isCardio,
  });

  void _removeSet(int templateId) {
    manager.removeSet(templateId);
  }

  void _changeSetType(int templateId, String newType) {
    manager.updateSet(templateId, setType: newType);
  }

  void _showSetTypePicker(BuildContext context, int templateId) {
    final l10n = AppLocalizations.of(context)!;

    Widget buildSymbol(String char, Color color) {
      return Text(
        char,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final options = [
      {
        'type': 'normal',
        'label': l10n.set_type_normal,
        'symbol': buildSymbol('N', Colors.grey),
      },
      {
        'type': 'warmup',
        'label': l10n.set_type_warmup,
        'symbol': buildSymbol('W', Colors.orange),
      },
      {
        'type': 'failure',
        'label': l10n.set_type_failure,
        'symbol': buildSymbol('F', Colors.red),
      },
      {
        'type': 'dropset',
        'label': l10n.set_type_dropset,
        'symbol': buildSymbol('D', Colors.blue),
      },
    ];

    showGlassBottomMenu(
      context: context,
      title: l10n.changeSetTypTitle,
      actions: options.map((opt) {
        return GlassMenuAction(
          customIcon: opt['symbol'] as Widget,
          label: opt['label'] as String,
          onTap: () => _changeSetType(templateId, opt['type'] as String),
        );
      }).toList(),
    );
  }

  String _getSetDisplayText(String setType, int setIndex) {
    switch (setType) {
      case 'warmup':
        return 'W';
      case 'failure':
        return 'F';
      case 'dropset':
        return 'D';
      default:
        return '$setIndex';
    }
  }

  Color _getSetTypeColor(String setType) {
    switch (setType) {
      case 'warmup':
        return Colors.orange;
      case 'dropset':
        return Colors.blue;
      case 'failure':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _isQualifyingSetForE1rm(
    SetLog setLog, {
    required bool requireCompleted,
  }) {
    final reps = setLog.reps;
    final weight = setLog.weightKg;
    final isWarmup = setLog.setType == 'warmup';
    final isCompleted = setLog.isCompleted == true;

    if (isWarmup) return false;
    if (requireCompleted && !isCompleted) return false;
    if (weight == null || weight <= 0) return false;
    if (reps == null || reps <= 0 || reps > 10) return false;

    return true;
  }

  double? _calculateBrzyckiE1rm(
    SetLog setLog, {
    required bool requireCompleted,
  }) {
    if (!_isQualifyingSetForE1rm(setLog, requireCompleted: requireCompleted)) {
      return null;
    }

    final reps = setLog.reps!;
    final weight = setLog.weightKg!;
    return weight * (36 / (37 - reps));
  }

  String _formatDisplayWeightValue(
    double metricValue,
    UnitService unitService, {
    int fractionDigits = 1,
  }) {
    return unitService
        .convertDisplayValue(metricValue, UnitDimension.weight)
        .toStringAsFixed(fractionDigits)
        .replaceAll('.0', '');
  }

  Widget _buildPRBadge(SetLog setLog, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unitService = context.read<UnitService>();
    String label = l10n.newPersonalRecordLabel;

    if (setLog.isMaxWeightPR && setLog.weightPRDiff != null) {
      label =
          "+${_formatDisplayWeightValue(setLog.weightPRDiff!, unitService)} ${unitService.suffixFor(UnitDimension.weight)}";
    } else if (setLog.isMaxEst1RMPR && setLog.est1rmPRDiff != null) {
      label =
          "+${_formatDisplayWeightValue(setLog.est1rmPRDiff!, unitService)} ${unitService.suffixFor(UnitDimension.weight)} (1RM)";
    } else if (setLog.isMaxVolumePR && setLog.volumePRDiff != null) {
      label =
          "+${_formatDisplayWeightValue(setLog.volumePRDiff!, unitService, fractionDigits: 0)} ${unitService.suffixFor(UnitDimension.weight)} (Vol)";
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Tooltip(
        message: l10n.prBadgeTooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isCompleted = setLog.isCompleted ?? false;
    final unitService = context.read<UnitService>();

    final isLightMode = Theme.of(context).brightness == Brightness.light;
    final bool isColoredRow = rowIndex > 0 && rowIndex.isOdd;
    final Color rowColor = isColoredRow
        ? (isLightMode
            ? Colors.grey.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.1))
        : Colors.transparent;

    // Hint Logic
    String weightHint = '0';
    String repHint = '0';
    final String rirHint = isCompleted
        ? '-'
        : (template.targetRir != null ? template.targetRir.toString() : '-');

    if (isCardio) {
      weightHint = "-"; // Distance Hint
      repHint = "-"; // Time Hint
    } else {
      final double tWeight = template.targetWeight ?? 0.0;
      weightHint = tWeight > 0
          ? unitService
              .convertDisplayValue(tWeight, UnitDimension.weight)
              .toStringAsFixed(1)
              .replaceAll('.0', '')
          : '0';
      repHint = (template.targetReps?.isNotEmpty == true)
          ? template.targetReps!
          : '0';
    }

    final rowContent = Row(
      children: [
        // 1. SET NUMBER
        Expanded(
          flex: isCardio ? 2 : 1,
          child: Center(
            child: GestureDetector(
              onTap: () => isCompleted ? null : _showSetTypePicker(context, templateId),
              child: Text(
                _getSetDisplayText(setLog.setType, setIndex),
                style: TextStyle(
                  color: _getSetTypeColor(setLog.setType),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // 2. LAST PERFORMANCE (tap to apply)
        Expanded(
          flex: isCardio ? 3 : 2,
          child: isCardio
              ? const SizedBox.shrink()
              : GestureDetector(
                  onTap: (!isCompleted && rowIndex < lastPerfSets.length)
                      ? () {
                          final lastSet = lastPerfSets[rowIndex];
                          double? metricWeight;
                          int? reps;

                          // Apply weight
                          if (lastSet.weightKg != null) {
                            final displayWeight = unitService
                                .convertDisplayValue(
                                    lastSet.weightKg!, UnitDimension.weight)
                                .toStringAsFixed(1)
                                .replaceAll('.0', '');
                            manager.weightControllers[templateId]?.text =
                                displayWeight;
                            metricWeight = lastSet.weightKg;
                          }
                          // Apply reps
                          if (lastSet.reps != null) {
                            manager.repsControllers[templateId]?.text =
                                lastSet.reps.toString();
                            reps = lastSet.reps;
                          }

                          // Explicitly propagate and bind to the underlying state model
                          manager.updateSet(
                            templateId,
                            weight: metricWeight,
                            reps: reps,
                          );

                          HapticFeedbackService.instance.selectionFeedback();
                        }
                      : null,
                  child: Text(
                    (rowIndex < lastPerfSets.length)
                        ? "${unitService.convertDisplayValue(lastPerfSets[rowIndex].weightKg ?? 0, UnitDimension.weight).toStringAsFixed(1).replaceAll('.0', '')}${unitService.suffixFor(UnitDimension.weight)} × ${lastPerfSets[rowIndex].reps}"
                        : "-",
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),

        // 3. INPUT 1: WEIGHT / DISTANCE
        Expanded(
          flex: isCardio ? 4 : 2,
          child: TextFormField(
            controller: manager.weightControllers[templateId],
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              fillColor: Colors.transparent,
              hintText: weightHint,
              hintStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.5),
                fontSize: 18,
              ),
            ),
            enabled: !isCompleted,
            onChanged: (text) {
              final String sanitized = text.replaceAll(',', '.');
              final double? val;
              if (sanitized.contains('-')) {
                final parts = sanitized.split('-');
                if (parts.length == 2) {
                  final min = double.tryParse(parts[0].trim());
                  final max = double.tryParse(parts[1].trim());
                  if (min != null && max != null) {
                    val = (min + max) / 2;
                  } else {
                    val = null;
                  }
                } else {
                  val = null;
                }
              } else {
                val = double.tryParse(sanitized);
              }
              final clearValue = val == null && text.isEmpty;

              if (isCardio) {
                if (val != manager.setLogs[templateId]?.distanceKm ||
                    clearValue) {
                  manager.updateSet(templateId,
                      distance: val, clearDistance: clearValue);
                }
              } else {
                final metricValue = val == null
                    ? null
                    : unitService.convertToMetric(val, UnitDimension.weight);
                if (metricValue != manager.setLogs[templateId]?.weightKg ||
                    clearValue) {
                  manager.updateSet(templateId,
                      weight: metricValue, clearWeight: clearValue);
                }
              }
            },
          ),
        ),

        // 4. INPUT 2: REPS / TIME
        Expanded(
          flex: isCardio ? 4 : 2,
          child: TextFormField(
            controller: manager.repsControllers[templateId],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              fillColor: Colors.transparent,
              hintText: repHint,
              hintStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.5),
                fontSize: 18,
              ),
            ),
            enabled: !isCompleted,
            onChanged: (text) {
              if (isCardio) {
                final String sanitized = text.replaceAll(',', '.');
                final double? val;
                if (sanitized.contains('-')) {
                  final parts = sanitized.split('-');
                  if (parts.length == 2) {
                    final min = double.tryParse(parts[0].trim());
                    final max = double.tryParse(parts[1].trim());
                    if (min != null && max != null) {
                      val = (min + max) / 2;
                    } else {
                      val = null;
                    }
                  } else {
                    val = null;
                  }
                } else {
                  val = double.tryParse(sanitized);
                }
                final seconds = (val != null) ? (val * 60).round() : null;
                final clearDuration = seconds == null && text.isEmpty;
                if (seconds != manager.setLogs[templateId]?.durationSeconds ||
                    clearDuration) {
                  manager.updateSet(templateId,
                      duration: seconds, clearDuration: clearDuration);
                }
              } else {
                final int? val;
                if (text.contains('-')) {
                  final parts = text.split('-');
                  if (parts.length == 2) {
                    final min = int.tryParse(parts[0].trim());
                    final max = int.tryParse(parts[1].trim());
                    if (min != null && max != null) {
                      val = ((min + max) / 2).round();
                    } else {
                      val = null;
                    }
                  } else {
                    val = null;
                  }
                } else {
                  val = int.tryParse(text);
                }
                final clearValue = val == null && text.isEmpty;
                if (val != manager.setLogs[templateId]?.reps || clearValue) {
                  manager.updateSet(templateId,
                      reps: val, clearReps: clearValue);
                }
              }
            },
          ),
        ),

        // 5. INPUT 3: RIR / INTENSITY
        Expanded(
          flex: isCardio ? 2 : 1,
          child: TextFormField(
            controller: manager.rirControllers[templateId],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              fillColor: Colors.transparent,
              hintText: rirHint,
              hintStyle: TextStyle(
                color: Colors.grey.withValues(alpha: 0.5),
                fontSize: 18,
              ),
            ),
            enabled: !isCompleted,
            onChanged: (text) {
              final val = int.tryParse(text);
              final clearValue = val == null && text.isEmpty;
              if (val != manager.setLogs[templateId]?.rir || clearValue) {
                manager.updateSet(templateId, rir: val, clearRir: clearValue);
              }
            },
          ),
        ),

        // 6. CHECKBOX
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                child: IconButton(
                  icon: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
                  onPressed: () async {
                    await manager.updateSet(templateId,
                        isCompleted: !isCompleted);
                    if (!isCompleted) {
                      final updatedSet = manager.setLogs[templateId];
                      if (updatedSet != null) {
                        if (isCardio) {
                          if (updatedSet.distanceKm != null) {
                            manager.weightControllers[templateId]?.text =
                                updatedSet.distanceKm!
                                    .toStringAsFixed(1)
                                    .replaceAll('.0', '');
                          }
                          if (updatedSet.durationSeconds != null) {
                            manager.repsControllers[templateId]?.text =
                                (updatedSet.durationSeconds! ~/ 60).toString();
                          }
                        } else {
                          if (updatedSet.weightKg != null) {
                            final displayWeight =
                                unitService.convertDisplayValue(
                                    updatedSet.weightKg!, UnitDimension.weight);
                            manager.weightControllers[templateId]?.text =
                                displayWeight
                                    .toStringAsFixed(2)
                                    .replaceAll(RegExp(r'0*$'), '')
                                    .replaceAll(RegExp(r'\.$'), '');
                          }
                          if (updatedSet.reps != null) {
                            manager.repsControllers[templateId]?.text =
                                updatedSet.reps!.toString();
                          }
                        }
                        if (updatedSet.rir != null) {
                          manager.rirControllers[templateId]?.text =
                              updatedSet.rir!.toString();
                        } else {
                          manager.rirControllers[templateId]?.text = '';
                        }
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final currentSetE1rm = _calculateBrzyckiE1rm(
      setLog,
      requireCompleted: false,
    );
    final showCurrentSetE1rm = !isCardio && currentSetE1rm != null;

    final bool hasPR = isCompleted &&
        (setLog.isMaxWeightPR || setLog.isMaxVolumePR || setLog.isMaxEst1RMPR);

    final rowWithSubInfo = Column(
      children: [
        rowContent,
        if (showCurrentSetE1rm || hasPR)
          Padding(
            padding: const EdgeInsets.only(right: 12.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasPR) ...[
                  _buildPRBadge(setLog, context),
                  if (showCurrentSetE1rm) const SizedBox(width: 8),
                ],
                if (showCurrentSetE1rm)
                  Text(
                    l10n.liveWorkoutE1rmCurrentSet(
                      _formatDisplayWeightValue(currentSetE1rm, unitService),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );

    return Dismissible(
      key: ValueKey('set_$templateId'),
      direction:
          isCompleted ? DismissDirection.none : DismissDirection.endToStart,
      onDismissed: (_) => _removeSet(templateId),
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color:
                  isCompleted ? Colors.green.withValues(alpha: 0.2) : rowColor,
            ),
          ),
          rowWithSubInfo,
        ],
      ),
    );
  }
}
