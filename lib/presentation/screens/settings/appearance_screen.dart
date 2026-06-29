import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/color_schemes.dart';
import '../../providers/providers.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('$e')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Theme mode ───────────────────────────────────────────────
            Text('Theme Mode',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _ThemeModeSelector(
              current: settings.themeMode,
              onChanged: (mode) => ref
                  .read(settingsNotifierProvider.notifier)
                  .update(settings.copyWith(themeMode: mode)),
            ),

            const SizedBox(height: 28),

            // ── Accent colour ────────────────────────────────────────────
            Text('Accent Colour',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Changes apply instantly throughout the app.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
            const SizedBox(height: 16),
            _AccentColorGrid(
              current: settings.accentColor,
              onChanged: (color) => ref
                  .read(settingsNotifierProvider.notifier)
                  .update(settings.copyWith(accentColor: color)),
            ),

            const SizedBox(height: 28),

            // ── Live preview ─────────────────────────────────────────────
            Text('Preview',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _ThemePreview(),
          ],
        ),
      ),
    );
  }
}

// ── Theme mode selector ────────────────────────────────────────────────────

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemeModeSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final options = [
      (ThemeMode.system, Icons.brightness_auto_rounded,  'Auto'),
      (ThemeMode.light,  Icons.light_mode_rounded,       'Light'),
      (ThemeMode.dark,   Icons.dark_mode_rounded,        'Dark'),
    ];

    return Row(
      children: options.map((opt) {
        final (mode, icon, label) = opt;
        final selected = current == mode;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color:        selected
                      ? cs.primaryContainer
                      : cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border:       selected
                      ? Border.all(color: cs.primary, width: 2)
                      : Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Icon(icon,
                        color: selected ? cs.primary : cs.onSurfaceVariant,
                        size:  28),
                    const SizedBox(height: 6),
                    Text(label,
                        style: TextStyle(
                          fontSize:   12,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                          color:      selected ? cs.primary : cs.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Accent colour grid ─────────────────────────────────────────────────────

class _AccentColorGrid extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;
  const _AccentColorGrid({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing:    12,
      runSpacing: 12,
      children: AppColorSchemes.accentColors.map((accent) {
        final selected = current == accent.value;
        final color    = Color(accent.value);
        return GestureDetector(
          onTap: () => onChanged(accent.value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width:  52, height: 52,
                decoration: BoxDecoration(
                  color:  color,
                  shape:  BoxShape.circle,
                  border: selected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 3)
                      : Border.all(color: Colors.transparent, width: 3),
                  boxShadow: selected
                      ? [BoxShadow(
                          color:       color.withValues(alpha: 0.5),
                          blurRadius:  10,
                          spreadRadius: 2)]
                      : null,
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 24)
                    : null,
              ),
              const SizedBox(height: 4),
              Text(accent.name,
                  style: TextStyle(
                    fontSize:   10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    color: selected
                        ? color
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Live preview ───────────────────────────────────────────────────────────

class _ThemePreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: cs.primaryContainer, shape: BoxShape.circle),
                child: Icon(Icons.check_rounded,
                    color: cs.onPrimaryContainer, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sample Task',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:      cs.onSurface)),
                    Text('Due today · High priority',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value:           0.65,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor:      AlwaysStoppedAnimation(cs.primary),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilledButton(onPressed: () {}, child: const Text('Primary')),
                FilledButton.tonal(
                    onPressed: () {}, child: const Text('Secondary')),
                OutlinedButton(
                    onPressed: () {}, child: const Text('Outline')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
