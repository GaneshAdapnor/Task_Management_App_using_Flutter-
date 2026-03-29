import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/highlighted_text.dart';
import '../../domain/entities/task_entity.dart';
import '../controllers/task_list_controller.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.item,
    required this.searchQuery,
    required this.onTap,
    required this.onDelete,
    required this.index,
  });

  final TaskItem item;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = item.task;
    final blocked = item.isBlocked;

    return Animate(
      effects: [
        FadeEffect(
          delay: Duration(milliseconds: index * 40),
          duration: 280.ms,
        ),
        SlideEffect(
          delay: Duration(milliseconds: index * 40),
          duration: 280.ms,
          begin: const Offset(0, 0.06),
          end: Offset.zero,
          curve: Curves.easeOut,
        ),
      ],
      child: AnimatedOpacity(
        opacity: blocked ? 0.5 : 1.0,
        duration: 300.ms,
        child: Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                    item: item,
                    searchQuery: searchQuery,
                    onDelete: onDelete,
                    ref: ref,
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _CardFooter(item: item),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header row ────────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.item,
    required this.searchQuery,
    required this.onDelete,
    required this.ref,
  });

  final TaskItem item;
  final String searchQuery;
  final VoidCallback onDelete;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final task = item.task;
    final blocked = item.isBlocked;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lock icon for blocked tasks
        if (blocked)
          const Padding(
            padding: EdgeInsets.only(right: 6, top: 1),
            child: Icon(Icons.lock_outline_rounded,
                size: 14, color: AppColors.textTertiary),
          ),
        Expanded(
          child: HighlightedText(
            text: task.title,
            query: searchQuery,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color:
                  blocked ? AppColors.textTertiary : AppColors.textPrimary,
              decoration: task.status == TaskStatus.done
                  ? TextDecoration.lineThrough
                  : null,
              decorationColor: AppColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Tappable status chip (cycles status when not blocked)
        _StatusChip(task: task, blocked: blocked, ref: ref),
        const SizedBox(width: 4),
        // Delete
        GestureDetector(
          onTap: () => _confirmDelete(context),
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(Icons.close_rounded,
                size: 16, color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip(
      {required this.task, required this.blocked, required this.ref});

  final TaskEntity task;
  final bool blocked;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final s = task.status;
    return GestureDetector(
      onTap: blocked
          ? null
          : () {
              final next = switch (s) {
                TaskStatus.todo => TaskStatus.inProgress,
                TaskStatus.inProgress => TaskStatus.done,
                TaskStatus.done => TaskStatus.todo,
              };
              ref
                  .read(taskListControllerProvider.notifier)
                  .quickUpdateStatus(task, next);
            },
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: blocked ? AppColors.surfaceVariant : s.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          s.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: blocked ? AppColors.textTertiary : s.foreground,
          ),
        ),
      ),
    );
  }
}

// ── Footer row ────────────────────────────────────────────────────────────────

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.item});
  final TaskItem item;

  @override
  Widget build(BuildContext context) {
    final task = item.task;
    final overdue = task.isOverdue;

    return Row(
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 12,
          color: overdue ? AppColors.overdue : AppColors.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          DateFormat('MMM d, yyyy').format(task.dueDate),
          style: TextStyle(
            fontSize: 12,
            color: overdue ? AppColors.overdue : AppColors.textTertiary,
            fontWeight:
                overdue ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        if (overdue) ...[
          const SizedBox(width: 6),
          _Pill(label: 'Overdue', fg: AppColors.overdue, bg: AppColors.dangerSurface),
        ],
        const Spacer(),
        if (item.isBlocked && item.blocker != null)
          _Pill(
            label: 'Waiting on "${item.blocker!.title}"',
            fg: const Color(0xFF92400E),
            bg: AppColors.blockedSurface,
            maxWidth: 140,
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.fg,
    required this.bg,
    this.maxWidth = double.infinity,
  });
  final String label;
  final Color fg;
  final Color bg;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
