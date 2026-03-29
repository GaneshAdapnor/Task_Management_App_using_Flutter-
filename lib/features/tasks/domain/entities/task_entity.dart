import 'package:flutter/material.dart' show Color, Colors, immutable;

// ─── Status enum ──────────────────────────────────────────────────────────────

enum TaskStatus {
  todo,
  inProgress,
  done;

  String get label => switch (this) {
        TaskStatus.todo => 'To-Do',
        TaskStatus.inProgress => 'In Progress',
        TaskStatus.done => 'Done',
      };

  /// Database key
  String get key => switch (this) {
        TaskStatus.todo => 'todo',
        TaskStatus.inProgress => 'inProgress',
        TaskStatus.done => 'done',
      };

  Color get foreground => switch (this) {
        TaskStatus.todo => const Color(0xFF64748B),
        TaskStatus.inProgress => const Color(0xFFF59E0B),
        TaskStatus.done => const Color(0xFF10B981),
      };

  Color get background => switch (this) {
        TaskStatus.todo => const Color(0xFFF1F5F9),
        TaskStatus.inProgress => const Color(0xFFFFFBEB),
        TaskStatus.done => const Color(0xFFECFDF5),
      };

  static TaskStatus fromKey(String key) => switch (key) {
        'inProgress' => TaskStatus.inProgress,
        'done' => TaskStatus.done,
        _ => TaskStatus.todo,
      };
}

// ─── Pure domain entity ───────────────────────────────────────────────────────

@immutable
class TaskEntity {
  const TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedById,
    required this.createdAt,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;

  /// ID of the task that must be completed before this one.
  final String? blockedById;

  final DateTime createdAt;
  final int sortOrder;

  bool get isOverdue =>
      status != TaskStatus.done && dueDate.isBefore(DateTime.now());

  TaskEntity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    Object? blockedById = _kSentinel,
    DateTime? createdAt,
    int? sortOrder,
  }) =>
      TaskEntity(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        blockedById: identical(blockedById, _kSentinel)
            ? this.blockedById
            : blockedById as String?,
        createdAt: createdAt ?? this.createdAt,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  @override
  bool operator ==(Object other) =>
      other is TaskEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// Sentinel so copyWith can explicitly clear nullable fields.
const Object _kSentinel = Object();

// ─── View model used by the presentation layer ────────────────────────────────

/// Wraps a [TaskEntity] with pre-computed derived state so widgets stay dumb.
@immutable
class TaskItem {
  const TaskItem({
    required this.task,
    required this.isBlocked,
    this.blocker,
  });

  final TaskEntity task;

  /// True when [task.blockedById] points to an unfinished task.
  final bool isBlocked;

  /// The task blocking this one (null if [isBlocked] is false).
  final TaskEntity? blocker;
}
