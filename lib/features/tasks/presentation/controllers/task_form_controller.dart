import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_providers.dart';
import 'task_list_controller.dart';

// ─── Form state ───────────────────────────────────────────────────────────────

class TaskFormState {
  TaskFormState({
    this.title = '',
    this.description = '',
    DateTime? dueDate,
    this.status = TaskStatus.todo,
    this.blockedById,
    this.isSaving = false,
    this.errorMessage,
  }) : dueDate = dueDate ?? _tomorrow;

  final String title;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final String? blockedById;
  final bool isSaving;
  final String? errorMessage;

  bool get isValid => title.trim().isNotEmpty;

  static DateTime get _tomorrow =>
      DateTime.now().add(const Duration(days: 1));

  TaskFormState copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    Object? blockedById = _kSentinel,
    bool? isSaving,
    Object? errorMessage = _kSentinel,
  }) =>
      TaskFormState(
        title: title ?? this.title,
        description: description ?? this.description,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        blockedById: identical(blockedById, _kSentinel)
            ? this.blockedById
            : blockedById as String?,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: identical(errorMessage, _kSentinel)
            ? this.errorMessage
            : errorMessage as String?,
      );

  factory TaskFormState.fromEntity(TaskEntity e) => TaskFormState(
        title: e.title,
        description: e.description,
        dueDate: e.dueDate,
        status: e.status,
        blockedById: e.blockedById,
      );
}

const Object _kSentinel = Object();

// ─── Provider ─────────────────────────────────────────────────────────────────

/// Keyed by the existing task (null = new-task form).
/// `autoDispose` ensures the controller is recreated fresh every time the
/// form screen is opened, which also means the draft is re-read on each open.
final taskFormControllerProvider = StateNotifierProvider.autoDispose
    .family<TaskFormController, TaskFormState, TaskEntity?>(
  (ref, existingTask) {
    final prefs = ref.read(sharedPreferencesProvider);
    return TaskFormController(ref, existingTask, prefs);
  },
);

// ─── Controller ───────────────────────────────────────────────────────────────

class TaskFormController extends StateNotifier<TaskFormState> {
  TaskFormController(this._ref, this._existingTask, this._prefs)
      : super(
          _existingTask != null
              ? TaskFormState.fromEntity(_existingTask)
              : TaskFormState(),
        ) {
    if (_existingTask == null) _loadDraft();
  }

  final Ref _ref;
  final TaskEntity? _existingTask;
  final SharedPreferences _prefs;

  static const _draftTitleKey = 'draft_title';
  static const _draftDescKey = 'draft_description';

  // ── Draft ──────────────────────────────────────────────────────────────────

  void _loadDraft() {
    final t = _prefs.getString(_draftTitleKey) ?? '';
    final d = _prefs.getString(_draftDescKey) ?? '';
    if (t.isNotEmpty || d.isNotEmpty) {
      state = state.copyWith(title: t, description: d);
    }
  }

  void _saveDraft() {
    if (_existingTask != null) return; // never draft edit screens
    _prefs.setString(_draftTitleKey, state.title);
    _prefs.setString(_draftDescKey, state.description);
  }

  Future<void> _clearDraft() async {
    await _prefs.remove(_draftTitleKey);
    await _prefs.remove(_draftDescKey);
  }

  // ── Field updates (all trigger draft save) ────────────────────────────────

  void updateTitle(String v) {
    state = state.copyWith(title: v);
    _saveDraft();
  }

  void updateDescription(String v) {
    state = state.copyWith(description: v);
    _saveDraft();
  }

  void updateDueDate(DateTime v) => state = state.copyWith(dueDate: v);

  void updateStatus(TaskStatus v) => state = state.copyWith(status: v);

  void updateBlockedById(String? v) =>
      state = state.copyWith(blockedById: v);

  // ── Save ──────────────────────────────────────────────────────────────────

  /// Returns true on success so the screen can pop.
  Future<bool> save() async {
    if (!state.isValid || state.isSaving) return false;

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final controller = _ref.read(taskListControllerProvider.notifier);

      if (_existingTask != null) {
        final updated = _existingTask.copyWith(
          title: state.title.trim(),
          description: state.description.trim(),
          dueDate: state.dueDate,
          status: state.status,
          blockedById: state.blockedById,
        );
        await controller.updateTask(updated);
      } else {
        final allTasks = _ref.read(taskListControllerProvider).valueOrNull ?? [];
        final entity = TaskEntity(
          id: const Uuid().v4(),
          title: state.title.trim(),
          description: state.description.trim(),
          dueDate: state.dueDate,
          status: state.status,
          blockedById: state.blockedById,
          createdAt: DateTime.now(),
          sortOrder: allTasks.length,
        );
        await controller.createTask(entity);
        await _clearDraft();
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }
}
