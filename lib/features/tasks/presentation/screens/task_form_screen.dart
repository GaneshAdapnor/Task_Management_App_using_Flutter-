import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/task_entity.dart';
import '../controllers/task_form_controller.dart';
import '../controllers/task_list_controller.dart';

class TaskFormScreen extends ConsumerWidget {
  const TaskFormScreen({super.key, this.existingTask});
  final TaskEntity? existingTask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.watch(taskFormControllerProvider(existingTask));
    final notifier =
        ref.read(taskFormControllerProvider(existingTask).notifier);
    final allTasks =
        ref.watch(taskListControllerProvider).valueOrNull ?? [];
    final others = allTasks
        .map((i) => i.task)
        .where((t) => t.id != existingTask?.id)
        .toList();

    final isEditing = existingTask != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger),
              tooltip: 'Delete task',
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              children: [
                // ── Error banner ──────────────────────────────────────────
                if (ctrl.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(ctrl.errorMessage!,
                        style: const TextStyle(color: AppColors.danger)),
                  ).animate().shake(),

                // ── Title ─────────────────────────────────────────────────
                _FieldLabel(label: 'Title', required: true),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: ctrl.title,
                  onChanged: notifier.updateTitle,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'What needs to be done?',
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Description ───────────────────────────────────────────
                _FieldLabel(label: 'Description'),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: ctrl.description,
                  onChanged: notifier.updateDescription,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Add details (optional)…',
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Due Date ──────────────────────────────────────────────
                _FieldLabel(label: 'Due Date'),
                const SizedBox(height: 8),
                _DateField(
                  date: ctrl.dueDate,
                  onChanged: notifier.updateDueDate,
                ),

                const SizedBox(height: 20),

                // ── Status ────────────────────────────────────────────────
                _FieldLabel(label: 'Status'),
                const SizedBox(height: 8),
                _StatusSelector(
                  selected: ctrl.status,
                  onChanged: notifier.updateStatus,
                ),

                const SizedBox(height: 20),

                // ── Blocked By ────────────────────────────────────────────
                _FieldLabel(label: 'Blocked By'),
                const SizedBox(height: 4),
                const Text(
                  'Select a task that must finish before this one.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 8),
                _BlockedByField(
                  others: others,
                  selected: ctrl.blockedById,
                  onChanged: notifier.updateBlockedById,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // ── Save button (sticky bottom) ───────────────────────────────────
          _SaveButton(
            isSaving: ctrl.isSaving,
            isValid: ctrl.isValid,
            isEditing: isEditing,
            onPressed: () async {
              final success = await notifier.save();
              if (success && context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(taskListControllerProvider.notifier)
                  .deleteTask(existingTask!.id);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ── Reusable form pieces ──────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
        if (required)
          const Text(' *',
              style: TextStyle(
                  fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── Date field ────────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.calendar_today_outlined,
              size: 18, color: AppColors.textTertiary),
          suffixIcon: Icon(Icons.chevron_right_rounded,
              color: AppColors.textTertiary),
        ),
        child: Text(
          DateFormat('EEEE, MMM d, yyyy').format(date),
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}

// ── Status selector ───────────────────────────────────────────────────────────

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({required this.selected, required this.onChanged});
  final TaskStatus selected;
  final ValueChanged<TaskStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TaskStatus.values.map((s) {
        final isSelected = s == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(s),
            child: AnimatedContainer(
              duration: 180.ms,
              margin: EdgeInsets.only(
                  right: s != TaskStatus.done ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? s.background : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? s.foreground.withOpacity(0.4)
                      : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: 180.ms,
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          isSelected ? s.foreground : AppColors.border,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    s.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? s.foreground
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Blocked by dropdown ───────────────────────────────────────────────────────

class _BlockedByField extends StatelessWidget {
  const _BlockedByField({
    required this.others,
    required this.selected,
    required this.onChanged,
  });
  final List<TaskEntity> others;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: selected,
      isExpanded: true,
      decoration: const InputDecoration(
        prefixIcon:
            Icon(Icons.link_rounded, size: 18, color: AppColors.textTertiary),
      ),
      hint: const Text('None — not blocked'),
      items: [
        const DropdownMenuItem(value: null, child: Text('None')),
        ...others.map(
          (t) => DropdownMenuItem(
            value: t.id,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: t.status.foreground,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

// ── Save button ───────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaving,
    required this.isValid,
    required this.isEditing,
    required this.onPressed,
  });

  final bool isSaving;
  final bool isValid;
  final bool isEditing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ElevatedButton(
        onPressed: (isSaving || !isValid) ? null : onPressed,
        child: AnimatedSwitcher(
          duration: 200.ms,
          child: isSaving
              ? const SizedBox.square(
                  key: ValueKey('loader'),
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  key: const ValueKey('label'),
                  isEditing ? 'Save Changes' : 'Create Task',
                ),
        ),
      ),
    );
  }
}
