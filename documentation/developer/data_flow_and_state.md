# Data Flow & State Lifecycle

Train Libre utilizes a strict state management paradigm to ensure data consistency, rapid interface updates, and leak-free memory cycles. This paradigm is built around **Reactive Reads / Imperative Writes** and explicit stream subscription management.

---

## The "Reactive Reads / Imperative Writes" Paradigm

To avoid state synchronization bugs (where the UI and the database disagree on the current values), the system separates data reading from data writing into two distinct pipelines.

```
       +--------------------------------------------+
       |                                            |
       v                                            |
[Drift Database] --(Reactive Stream Update)--> [ViewModel] --> [UI Screen]
       ^                                                            |
       |                                                            |
       +--------------(Asynchronous Command)------------------------+
```

### 1. Reactive Reads (Observer Pattern)
The user interface never queries the database on-demand for a single snapshot of data during normal render cycles. Instead, it subscribes to active streams exposed by repositories, which in turn wrap Drift's query-watching capabilities:

```dart
// Establishing reactive stream listeners for a selected date
_goalsSubscription = _nutritionRepo.watchGoalsForDate(diaryDate).listen((goals) {
  _activeGoals = goals;
  _updateCalculatedState(); // Recalculates totals and triggers notifyListeners()
});
```

When database records are inserted or deleted by *any* system thread, the underlying Drift engine detects which tables have changed, executes the query again under the hood, and pushes the new result list down the active Stream. The ViewModel receives the update, recalculates relevant macros, and dispatches `notifyListeners()` to rebuild the UI.

### 2. Imperative Writes (Action Pattern)
All database modifications—inserts, edits, deletes, and sync imports—are executed as one-off, imperative asynchronous commands. For example, deleting a food log or updating a fluid entry:

```dart
Future<void> deleteFoodEntry(int id) async {
  await _nutritionRepo.deleteFoodEntry(id);
}
```

Writers do **not** return the updated state list to the UI, nor do they trigger manual UI refreshes. The write completes, the transaction is committed, and Drift’s reactive stream automatically dispatches the updated rows to all active observers.

---

## Subscription Lifecycles & Teardown

Because active streams run indefinitely, keeping subscriptions open when switching screens or moving between calendar days results in severe memory leaks, background CPU waste, and duplicate UI renderings.

### Date Switching Handlers
When the user selects a new date inside the diary interface, the active subscriptions for the previous date must be cancelled immediately before establishing new ones. This is managed explicitly:

```dart
void setSelectedDate(DateTime date) {
  final diaryDate = normalizeDiaryDate(date);
  selectedDateNotifier.value = diaryDate;

  // Cancel all existing subscriptions
  _goalsSubscription?.cancel();
  _entriesSubscription?.cancel();
  _fluidsSubscription?.cancel();
  _supplementsSubscription?.cancel();
  _supplementLogsSubscription?.cancel();
  _workoutsSubscription?.cancel();

  isLoading = true;
  notifyListeners();

  // Re-establish reactive stream listeners for the new selected date
  _goalsSubscription = _nutritionRepo.watchGoalsForDate(diaryDate).listen((goals) { ... });
  // [Additional stream listeners mapped similarly...]
}
```

### ViewModel Disposal
When a screen is popped or closed, its associated ViewModel is removed from the widget tree. The ViewModel must override the native `dispose()` method to cancel all remaining subscriptions and prevent context leaks:

```dart
@override
void dispose() {
  _goalsSubscription?.cancel();
  _entriesSubscription?.cancel();
  _fluidsSubscription?.cancel();
  _supplementsSubscription?.cancel();
  _supplementLogsSubscription?.cancel();
  _workoutsSubscription?.cancel();
  
  healthSyncCoordinator.removeListener(notifyListeners);
  healthSyncCoordinator.dispose();
  selectedDateNotifier.dispose();
  super.dispose();
}
```

---

## Input Blocking & Asynchronous Safety

To prevent race conditions, duplicate writes, and double-taps during asynchronous processes (e.g., executing an AI meal capture query or running a health sync routine), ViewModels maintain strict interface-blocking flags.

### Concurrency Guards
1.  **State Flags**: Variables such as `isLoading` or `isGenerating` are set to `true` immediately upon starting an asynchronous event.
2.  **UI Feedback**: The presentation layer reads these flags to display localized progress indicators (spinners, skeleton loaders).
3.  **Interactive Blocking**: Interactive elements (save buttons, text fields, checkboxes) are disabled programmatically if any blocking flag is active:

```dart
// Example widget button disabling logic
ElevatedButton(
  onPressed: viewModel.isGenerating ? null : () => viewModel.startAiAnalysis(),
  child: viewModel.isGenerating 
      ? const CircularProgressIndicator() 
      : const Text('Analyze Meal'),
)
```

By passing `null` to `onPressed`, the Flutter framework natively disables the button and blocks tap actions, guaranteeing that only one asynchronous request can occupy the execution pipeline at a time.
