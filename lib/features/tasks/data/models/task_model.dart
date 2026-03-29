import '../../domain/entities/task_entity.dart';

/// Database representation of a task.
/// Knows how to serialise to/from a SQLite row map AND convert to/from the
/// pure domain entity. Nothing outside the data layer should import this.
class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDateMs,
    required this.statusKey,
    this.blockedById,
    required this.createdAtMs,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String description;
  final int dueDateMs;       // millisecondsSinceEpoch — faster than string parsing
  final String statusKey;
  final String? blockedById;
  final int createdAtMs;
  final int sortOrder;

  // ── DB serialisation ──────────────────────────────────────────────────────

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'due_date_ms': dueDateMs,
        'status': statusKey,
        'blocked_by_id': blockedById,
        'created_at_ms': createdAtMs,
        'sort_order': sortOrder,
      };

  factory TaskModel.fromMap(Map<String, Object?> map) => TaskModel(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        dueDateMs: map['due_date_ms'] as int,
        statusKey: map['status'] as String,
        blockedById: map['blocked_by_id'] as String?,
        createdAtMs: map['created_at_ms'] as int,
        sortOrder: map['sort_order'] as int? ?? 0,
      );

  // ── Domain mapping ────────────────────────────────────────────────────────

  TaskEntity toEntity() => TaskEntity(
        id: id,
        title: title,
        description: description,
        dueDate: DateTime.fromMillisecondsSinceEpoch(dueDateMs),
        status: TaskStatus.fromKey(statusKey),
        blockedById: blockedById,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
        sortOrder: sortOrder,
      );

  factory TaskModel.fromEntity(TaskEntity e) => TaskModel(
        id: e.id,
        title: e.title,
        description: e.description,
        dueDateMs: e.dueDate.millisecondsSinceEpoch,
        statusKey: e.status.key,
        blockedById: e.blockedById,
        createdAtMs: e.createdAt.millisecondsSinceEpoch,
        sortOrder: e.sortOrder,
      );
}
