import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_providers.dart';

// ─── Filter state ─────────────────────────────────────────────────────────────

class TaskFilter {
  const TaskFilter({
    this.debouncedQuery = '',
    this.status,
  });

  final String debouncedQuery;
  final TaskStatus? status;

  TaskFilter copyWith({String? debouncedQuery, Object? status = _kSentinel}) =>
      TaskFilter(
        debouncedQuery: debouncedQuery ?? this.debouncedQuery,
        status: identical(status, _kSentinel)
            ? this.status
            : status as TaskStatus?,
      );
}

const Object _kSentinel = Object();

final taskFilterProvider =
    StateNotifierProvider<TaskFilterNotifier, TaskFilter>(
  (_) => TaskFilterNotifier(),
);

class TaskFilterNotifier extends StateNotifier<TaskFilter> {
  TaskFilterNotifier() : super(const TaskFilter());

  void setQuery(String q) => state = state.copyWith(debouncedQuery: q);
  void setStatus(TaskStatus? s) => state = state.copyWith(status: s);
  void clear() => state = const TaskFilter();
}

// ─── Main list controller ─────────────────────────────────────────────────────

final taskListControllerProvider =
    AsyncNotifierProvider<TaskListController, List<TaskItem>>(
  TaskListController.new,
);

class TaskListController extends AsyncNotifier<List<TaskItem>> {
  @override
  Future<List<TaskItem>> build() => _load();

  Future<List<TaskItem>> _load() async {
    final tasks = await ref.read(getTasksProvider).call();
    return _toItems(tasks);
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  Future<void> createTask(TaskEntity task) async {
    await ref.read(createTaskProvider).call(task);
    ref.invalidateSelf();
  }

  Future<void> updateTask(TaskEntity task) async {
    await ref.read(updateTaskProvider).call(task);
    ref.invalidateSelf();
  }

  Future<void> deleteTask(String id) async {
    // Optimistic update: remove immediately, re-fetch to confirm.
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((i) => i.task.id != id).toList());
    await ref.read(deleteTaskProvider).call(id);
    ref.invalidateSelf();
  }

  /// Quick status tap on a card — no simulated delay.
  Future<void> quickUpdateStatus(TaskEntity task, TaskStatus newStatus) async {
    final updated = task.copyWith(status: newStatus);
    // Optimistic update first for instant feedback.
    final current = state.valueOrNull ?? [];
    final optimistic = current
        .map((i) => i.task.id == task.id
            ? TaskItem(
                task: updated,
                isBlocked: i.isBlocked,
                blocker: i.blocker,
              )
            : i)
        .toList();
    state = AsyncData(_recomputeBlocking(optimistic.map((i) => i.task).toList()));
    // Persist without the 2s delay (status toggle shouldn't feel slow).
    await ref.read(updateTaskProvider).call(updated);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<TaskItem> _toItems(List<TaskEntity> tasks) =>
      _recomputeBlocking(tasks);

  List<TaskItem> _recomputeBlocking(List<TaskEntity> tasks) {
    final byId = {for (final t in tasks) t.id: t};
    return tasks.map((task) {
      if (task.blockedById == null) {
        return TaskItem(task: task, isBlocked: false);
      }
      final blocker = byId[task.blockedById];
      final isBlocked =
          blocker != null && blocker.status != TaskStatus.done;
      return TaskItem(task: task, isBlocked: isBlocked, blocker: blocker);
    }).toList();
  }
}

// ─── Derived: filtered list ───────────────────────────────────────────────────

final filteredTasksProvider = Provider<AsyncValue<List<TaskItem>>>((ref) {
  final listAsync = ref.watch(taskListControllerProvider);
  final filter = ref.watch(taskFilterProvider);

  return listAsync.whenData((items) {
    var result = items;

    if (filter.status != null) {
      result = result.where((i) => i.task.status == filter.status).toList();
    }

    if (filter.debouncedQuery.isNotEmpty) {
      final q = filter.debouncedQuery.toLowerCase();
      result =
          result.where((i) => i.task.title.toLowerCase().contains(q)).toList();
    }

    return result;
  });
});
