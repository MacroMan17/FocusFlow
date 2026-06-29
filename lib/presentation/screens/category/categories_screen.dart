import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/category_entity.dart';
import '../../../domain/usecases/category/create_category_use_case.dart';
import '../../providers/providers.dart';
import '../../widgets/empty_state.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListNotifierProvider);
    final taskState       = ref.watch(taskListNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (categories) {
          if (categories.isEmpty) {
            return EmptyState(
              icon: Icons.label_outline_rounded,
              title: 'No categories yet',
              subtitle: 'Create a category to organise your tasks.',
              actionLabel: 'Add Category',
              onAction: () => _showAddEditDialog(context, ref),
            );
          }

          // Build a pending-task count map
          final pendingMap = <String, int>{};
          for (final t in taskState.tasks) {
            if (!t.isCompleted && t.categoryId != null) {
              pendingMap[t.categoryId!] =
                  (pendingMap[t.categoryId!] ?? 0) + 1;
            }
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final cat = categories[i];
              return _CategoryCard(
                category:     cat,
                pendingCount: pendingMap[cat.id] ?? 0,
                onEdit:   () => _showAddEditDialog(context, ref, existing: cat),
                onDelete: () => _confirmDelete(context, ref, cat),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context, ref),
        icon:  const Icon(Icons.add_rounded),
        label: const Text('Add Category'),
      ),
    );
  }

  // ── Add / Edit dialog ─────────────────────────────────────────────────────

  Future<void> _showAddEditDialog(
    BuildContext context,
    WidgetRef ref, {
    CategoryEntity? existing,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => _AddEditCategoryDialog(existing: existing, ref: ref),
    );
  }

  // ── Delete confirm ────────────────────────────────────────────────────────

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryEntity cat,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          'Delete "${cat.name}"?\n\n'
          'Tasks in this category will become uncategorised.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    final result =
        await ref.read(deleteCategoryUseCaseProvider)(cat.id);
    result.fold(
      (f) => _snack(context, f.message, isError: true),
      (_) {
        ref.read(categoryListNotifierProvider.notifier).load();
        ref.read(taskListNotifierProvider.notifier).load();
        _snack(context, '"${cat.name}" deleted');
      },
    );
  }

  void _snack(BuildContext context, String msg, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? Theme.of(context).colorScheme.error : null,
    ));
  }
}

// ── Category card ──────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final CategoryEntity category;
  final int            pendingCount;
  final VoidCallback   onEdit;
  final VoidCallback   onDelete;

  const _CategoryCard({
    required this.category,
    required this.pendingCount,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final color = Color(category.color);

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color:  color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Icon(Icons.label_rounded, color: color, size: 22),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          pendingCount == 0
              ? 'No pending tasks'
              : '$pendingCount pending task${pendingCount == 1 ? '' : 's'}',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pendingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:         color.withValues(alpha: 0.15),
                  borderRadius:  BorderRadius.circular(12),
                ),
                child: Text(
                  '$pendingCount',
                  style: TextStyle(
                    color:      color,
                    fontWeight: FontWeight.w700,
                    fontSize:   13,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon:     const Icon(Icons.edit_outlined, size: 20),
              tooltip:  'Edit',
              onPressed: onEdit,
            ),
            if (!category.isDefault)
              IconButton(
                icon:     Icon(Icons.delete_outline_rounded,
                    size: 20, color: Theme.of(context).colorScheme.error),
                tooltip:  'Delete',
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Add / Edit dialog widget ──────────────────────────────────────────────

class _AddEditCategoryDialog extends ConsumerStatefulWidget {
  final CategoryEntity? existing;
  final WidgetRef       ref;

  const _AddEditCategoryDialog({this.existing, required this.ref});

  @override
  ConsumerState<_AddEditCategoryDialog> createState() =>
      _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState
    extends ConsumerState<_AddEditCategoryDialog> {
  final _nameCtrl = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  bool  _saving   = false;
  int   _selectedColor = 0xFF2196F3;

  static const _palette = [
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFF9C27B0, // Purple
    0xFFF44336, // Red
    0xFFFF9800, // Orange
    0xFF009688, // Teal
    0xFFE91E63, // Pink
    0xFF607D8B, // Slate
    0xFFFFEB3B, // Yellow
    0xFF795548, // Brown
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text    = widget.existing!.name;
      _selectedColor    = widget.existing!.color;
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    if (widget.existing != null) {
      // Edit
      final updated = widget.existing!.copyWith(
        name:  _nameCtrl.text.trim(),
        color: _selectedColor,
      );
      final result =
          await ref.read(updateCategoryUseCaseProvider)(updated);
      result.fold(
        (f) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(f.message)));
        },
        (_) {
          ref.read(categoryListNotifierProvider.notifier).load();
          Navigator.pop(context);
        },
      );
    } else {
      // Create
      final params = CreateCategoryParams(
        id:    const Uuid().v4(),
        name:  _nameCtrl.text.trim(),
        color: _selectedColor,
      );
      final result =
          await ref.read(createCategoryUseCaseProvider)(params);
      result.fold(
        (f) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(f.message)));
        },
        (_) {
          ref.read(categoryListNotifierProvider.notifier).load();
          Navigator.pop(context);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Category' : 'New Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameCtrl,
              autofocus:  true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Category name *',
                hintText:  'e.g. Work, Study, Health',
              ),
              maxLength: 30,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            Text('Colour',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _palette.map((c) {
                final selected = _selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color:  Color(c),
                      shape:  BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 3)
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isEdit ? 'Save' : 'Create')),
      ],
    );
  }
}
