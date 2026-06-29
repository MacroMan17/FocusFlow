import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class TaskSortSheet extends ConsumerWidget {
  const TaskSortSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => const TaskSortSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(taskListNotifierProvider).sort;
    final cs = Theme.of(context).colorScheme;

    const options = [
      (TaskSort.createdAt, Icons.access_time_rounded, 'Date Created'),
      (TaskSort.dueDate, Icons.event_rounded, 'Due Date'),
      (TaskSort.priority, Icons.flag_rounded, 'Priority'),
      (TaskSort.title, Icons.sort_by_alpha_rounded, 'Title (A-Z)'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sort by',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final (sort, icon, label) = opt;
            final selected = current == sort;
            return ListTile(
              leading: Icon(icon,
                  color: selected ? cs.primary : cs.onSurfaceVariant),
              title: Text(label,
                  style: TextStyle(
                      color: selected ? cs.primary : null,
                      fontWeight: selected ? FontWeight.w600 : null)),
              trailing: selected
                  ? Icon(Icons.check_rounded, color: cs.primary)
                  : null,
              contentPadding: EdgeInsets.zero,
              onTap: () {
                ref.read(taskListNotifierProvider.notifier).setSort(sort);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
