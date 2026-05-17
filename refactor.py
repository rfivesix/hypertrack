import re

def refactor():
    with open('lib/screens/diary_screen.dart', 'r') as f:
        content = f.read()

    # Add import
    if "import 'diary_view_model.dart';" not in content:
        content = content.replace(
            "import '../widgets/glass_progress_bar.dart';",
            "import '../widgets/glass_progress_bar.dart';\nimport 'diary_view_model.dart';"
        )

    # 1. Remove Top Helpers
    content = re.sub(r'DateTime resolveDiaryInitialDate.*?class DiaryLoadCoordinator.*?\n}\n', '', content, flags=re.DOTALL)

    # 2. Refactor DiaryScreen to use Provider
    new_screen = """class DiaryScreen extends StatelessWidget {
  final DateTime? initialDate;

  const DiaryScreen({super.key, this.initialDate});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DiaryViewModel(initialDate: initialDate),
      child: const _DiaryScreenContent(),
    );
  }
}

class _DiaryScreenContent extends StatefulWidget {
  const _DiaryScreenContent({super.key});

  @override
  State<_DiaryScreenContent> createState() => DiaryScreenState();
}"""
    content = re.sub(r'class DiaryScreen extends StatefulWidget.*?State<DiaryScreen> createState\(\) => DiaryScreenState\(\);\n}', new_screen, content, flags=re.DOTALL)
    
    content = content.replace('class DiaryScreenState extends State<DiaryScreen>', 'class DiaryScreenState extends State<_DiaryScreenContent>')

    # 3. Remove all state fields related to data
    # From `static const Duration _stepsSyncInterval` up to `Map<String, dynamic>? _workoutSummary;`
    content = re.sub(r'static const Duration _stepsSyncInterval.*?\n  Map<String, dynamic>\? _workoutSummary;\n', '', content, flags=re.DOTALL)

    # Remove initState and dispose
    content = re.sub(r'  @override\n  void initState\(\).*?super\.initState\(\);\n.*?}\n', '', content, flags=re.DOTALL)
    content = re.sub(r'  @override\n  void dispose\(\).*?super\.dispose\(\);\n.*?}\n', '', content, flags=re.DOTALL)

    # Remove loadDataForDate and all its sub-methods up to _deleteFoodEntry
    content = re.sub(r'  // Data-loading entry point.*?Future<void> _deleteFoodEntry\(int id\) async {', '  Future<void> _deleteFoodEntry(int id) async {', content, flags=re.DOTALL)

    # Replace delete bodies
    content = re.sub(r'  Future<void> _deleteFoodEntry\(int id\) async \{.*?\}', r'''  Future<void> _deleteFoodEntry(int id) async {
    final viewModel = context.read<DiaryViewModel>();
    await viewModel.deleteFoodEntry(id);
  }''', content, flags=re.DOTALL)

    content = re.sub(r'  Future<void> _deleteFluidEntry\(int id\) async \{.*?\}', r'''  Future<void> _deleteFluidEntry(int id) async {
    final viewModel = context.read<DiaryViewModel>();
    await viewModel.deleteFluidEntry(id);
  }''', content, flags=re.DOTALL)

    # Replace DB Helper calls inside edit/add methods
    content = content.replace('DatabaseHelper.instance.updateFluidEntry(updated)', 'context.read<DiaryViewModel>().updateFluidEntry(updated)')
    content = content.replace('DatabaseHelper.instance.updateFoodEntry(updatedEntry)', 'context.read<DiaryViewModel>().updateFoodEntry(updatedEntry)')
    content = content.replace('DatabaseHelper.instance.deleteFluidEntryByLinkedFoodId', 'context.read<DiaryViewModel>().deleteFluidEntryByLinkedFoodId')
    content = content.replace('DatabaseHelper.instance.insertFluidEntry(newFluidEntry)', 'context.read<DiaryViewModel>().insertFluidEntry(newFluidEntry)')
    content = content.replace('DatabaseHelper.instance.insertFluidEntry(newEntry)', 'context.read<DiaryViewModel>().insertFluidEntry(newEntry)')
    content = content.replace('DatabaseHelper.instance.insertFoodEntry', 'context.read<DiaryViewModel>().insertFoodEntry')

    # Remove _logCaffeineDose implementation entirely, replace calls
    content = re.sub(r'  Future<void> _logCaffeineDose\(.*?\}', '', content, flags=re.DOTALL)
    content = content.replace('_logCaffeineDose', 'context.read<DiaryViewModel>().logCaffeineDose')

    # Replace pickDate and navigateDay
    content = re.sub(r'  Future<void> pickDate\(\) async \{.*?\}', r'''  Future<void> pickDate() async {
    final viewModel = context.read<DiaryViewModel>();
    final picked = await showDatePicker(
      context: context,
      initialDate: viewModel.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      viewModel.pickDate(picked);
    }
  }''', content, flags=re.DOTALL)

    content = re.sub(r'  void navigateDay\(bool forward\) \{.*?\}', r'''  void navigateDay(bool forward) {
    context.read<DiaryViewModel>().navigateDay(forward);
  }''', content, flags=re.DOTALL)

    # In build(), inject viewModel
    content = content.replace('  @override\n  Widget build(BuildContext context) {\n', '  @override\n  Widget build(BuildContext context) {\n    final viewModel = context.watch<DiaryViewModel>();\n')

    # Replace ALL state reads with viewModel reads
    # But carefully: only those not assigned locally
    replacements = [
        ('_isLoading', 'viewModel.isLoading'),
        ('loadDataForDate(_selectedDate)', 'viewModel.loadDataForDate(viewModel.selectedDate)'),
        ('loadDataForDate(diaryDate, queueIfInFlight: true)', 'context.read<DiaryViewModel>().loadDataForDate(diaryDate, queueIfInFlight: true)'),
        ('_selectedDate', 'viewModel.selectedDate'),
        ('_dailyNutrition', 'viewModel.dailyNutrition'),
        ('_entriesByMeal', 'viewModel.entriesByMeal'),
        ('_fluidEntries', 'viewModel.fluidEntries'),
        ('_trackedSupplements', 'viewModel.trackedSupplements'),
        ('_workoutSummary', 'viewModel.workoutSummary'),
        ('_showSugarInOverview', 'viewModel.showSugarInOverview'),
        ('_isStepsWidgetLoading', 'viewModel.isStepsWidgetLoading'),
        ('_stepsForSelectedDay', 'viewModel.stepsForSelectedDay'),
        ('_targetSteps', 'viewModel.targetSteps'),
        ('_isSleepWidgetLoading', 'viewModel.isSleepWidgetLoading'),
        ('_sleepOverview', 'viewModel.sleepOverview'),
        ('_isPulseWidgetLoading', 'viewModel.isPulseWidgetLoading'),
        ('_pulseSummary', 'viewModel.pulseSummary'),
        ('_stepsTrackingEnabled', 'viewModel.stepsTrackingEnabled'),
        ('_sleepTrackingEnabled', 'viewModel.sleepTrackingEnabled'),
        ('_pulseTrackingEnabled', 'viewModel.pulseTrackingEnabled'),
        ('selectedDateNotifier', 'viewModel.selectedDateNotifier'),
        ('loadDataForDate(diaryDate', 'context.read<DiaryViewModel>().loadDataForDate(diaryDate'),
    ]

    for old, new in replacements:
        content = content.replace(old, new)

    with open('lib/screens/diary_screen.dart', 'w') as f:
        f.write(content)

if __name__ == '__main__':
    refactor()
