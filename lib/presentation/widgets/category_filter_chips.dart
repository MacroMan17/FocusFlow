import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

class CategoryFilterChips extends ConsumerWidget {
  const CategoryFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListNotifierProvider);
    final taskState = ref.watch(taskListNotifierProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return categoriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row label ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 0, 6),
              child: Text(
                'FILTER BY CATEGORY',
                style: tt.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontSize: 10,
                ),
              ),
            ),

            // ── Chips ────────────────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length + 1, // +1 for "All"
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    final selected = taskState.categoryFilter == null;
                    return ChoiceChip(
                      avatar: Icon(
                        Icons.apps_rounded,
                        size: 13,
                        color: selected
                            ? cs.onSecondaryContainer
                            : cs.onSurfaceVariant,
                      ),
                      label: const Text('All'),
                      selected: selected,
                      onSelected: (_) => ref
                          .read(taskListNotifierProvider.notifier)
                          .setCategoryFilter(null),
                      selectedColor: cs.secondaryContainer,
                      backgroundColor: cs.surfaceContainerHighest,
                      labelStyle: TextStyle(
                        color: selected
                            ? cs.onSecondaryContainer
                            : cs.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    );
                  }

                  final cat = categories[i - 1];
                  final selected = taskState.categoryFilter == cat.id;
                  final color = Color(cat.color);

                  return ChoiceChip(
                    avatar: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: Colors.white, width: 1.5)
                            : null,
                      ),
                    ),
                    label: Text(cat.name),
                    selected: selected,
                    onSelected: (_) => ref
                        .read(taskListNotifierProvider.notifier)
                        .setCategoryFilter(selected ? null : cat.id),
                    selectedColor: color.withValues(alpha: 0.18),
                    backgroundColor: cs.surfaceContainerHighest,
                    labelStyle: TextStyle(
                      color: selected ? color : cs.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: selected
                        ? BorderSide(
                            color: color.withValues(alpha: 0.5), width: 1)
                        : BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
