import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/router.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/task_entity.dart';
import '../../providers/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/category_chip_widget.dart';

// ── Search provider ────────────────────────────────────────────────────────

final _searchQueryProvider = StateProvider<String>((_) => '');

final _searchResultsProvider =
    FutureProvider.family<List<TaskEntity>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final result = await ref.read(searchTasksUseCaseProvider)(query.trim());
  return result.fold((_) => [], (tasks) => tasks);
});

// ── Screen ─────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus on open
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_searchQueryProvider);
    final results = ref.watch(_searchResultsProvider(query));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          focusNode: _focus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search tasks…',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _ctrl.clear();
                      ref.read(_searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
          ),
          onChanged: (v) => ref.read(_searchQueryProvider.notifier).state = v,
        ),
      ),
      body: query.trim().isEmpty
          ? const EmptyState(
              icon: Icons.search_rounded,
              title: 'Search your tasks',
              subtitle: 'Type a keyword to find tasks by title or description.',
            )
          : results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No results',
                    subtitle: 'No tasks match "$query".',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _SearchResultCard(
                    task: tasks[i],
                    query: query,
                    onTap: () {
                      context.goNamed(
                        RouteNames.taskDetail,
                        pathParameters: {'id': tasks[i].id},
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ── Search result card ─────────────────────────────────────────────────────

class _SearchResultCard extends ConsumerWidget {
  final TaskEntity task;
  final String query;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.task,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final categories = ref
        .watch(categoryListNotifierProvider)
        .maybeWhen(data: (c) => c, orElse: () => <CategoryEntity>[]);
    final category = task.categoryId != null
        ? categories.where((c) => c.id == task.categoryId).firstOrNull
        : null;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Highlighted title
              _HighlightedText(
                text: task.title,
                query: query,
                style: tt.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                  color:
                      task.isCompleted ? cs.onSurface.withValues(alpha: 0.4) : null,
                ),
              ),
              // Highlighted description snippet
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                _HighlightedText(
                  text: task.description!,
                  query: query,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PriorityBadge(priority: task.priority, compact: true),
                  if (task.dueDate != null)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.schedule_rounded,
                          size: 12,
                          color:
                              task.isOverdue ? cs.error : cs.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Text(
                        '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              task.isOverdue ? cs.error : cs.onSurfaceVariant,
                        ),
                      ),
                    ]),
                  if (category != null)
                    CategoryChip(category: category, compact: true),
                  if (task.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Done',
                          style: TextStyle(
                              fontSize: 10,
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Highlighted text ───────────────────────────────────────────────────────

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;

  const _HighlightedText({
    required this.text,
    required this.query,
    this.style,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lowerText = text.toLowerCase();
    final lowerQ = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerQ, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          backgroundColor: cs.primaryContainer,
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ));
      start = idx + query.length;
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }
}
