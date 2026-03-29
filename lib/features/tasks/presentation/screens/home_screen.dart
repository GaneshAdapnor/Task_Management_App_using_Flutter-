import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/debouncer.dart';
import '../../domain/entities/task_entity.dart';
import '../controllers/task_list_controller.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  final _debouncer = Debouncer();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debouncer(() {
      ref.read(taskFilterProvider.notifier).setQuery(value);
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _debouncer.dispose();
    ref.read(taskFilterProvider.notifier).setQuery('');
  }

  Future<void> _openForm([TaskEntity? task]) async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, anim, __) => TaskFormScreen(existingTask: task),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(taskFilterProvider);
    final filteredAsync = ref.watch(filteredTasksProvider);
    final hasFilter =
        filter.debouncedQuery.isNotEmpty || filter.status != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Large App Bar ─────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 20, bottom: 14),
              title: const Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: AppColors.textPrimary,
                ),
              ),
              background: Container(color: AppColors.background),
            ),
            actions: [
              _StatsChip(ref: ref),
              const SizedBox(width: 8),
            ],
          ),

          // ── Search + Filter ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search field
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by title…',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.textTertiary, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: AppColors.textTertiary),
                              onPressed: _clearSearch,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Status filter chips
                  _StatusFilterRow(
                    current: filter.status,
                    onSelect: (s) =>
                        ref.read(taskFilterProvider.notifier).setStatus(s),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Task list ─────────────────────────────────────────────────────
          filteredAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (items) {
              if (items.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyStateWidget(hasFilter: hasFilter),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return TaskCard(
                      key: ValueKey(item.task.id),
                      item: item,
                      index: i,
                      searchQuery: filter.debouncedQuery,
                      onTap: () => _openForm(item.task),
                      onDelete: () => ref
                          .read(taskListControllerProvider.notifier)
                          .deleteTask(item.task.id),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Task',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      )
          .animate()
          .scale(
            delay: 400.ms,
            duration: 300.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }
}

// ─── Stats chip (total / done count) ─────────────────────────────────────────

class _StatsChip extends StatelessWidget {
  const _StatsChip({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(taskListControllerProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        final done = items.where((i) => i.task.status == TaskStatus.done).length;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$done / ${items.length} done',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}

// ─── Status filter chips row ──────────────────────────────────────────────────

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({required this.current, required this.onSelect});
  final TaskStatus? current;
  final ValueChanged<TaskStatus?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: current == null,
            color: AppColors.primary,
            bg: AppColors.primaryDim,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 8),
          ...TaskStatus.values.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: s.label,
                  isSelected: current == s,
                  color: s.foreground,
                  bg: s.background,
                  onTap: () => onSelect(s),
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 180.ms,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? bg : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.4) : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
