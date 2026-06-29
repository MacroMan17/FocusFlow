import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';

/// Splash screen — visible while Hive loads and settings are read.
/// The router's redirect handles navigation once settings are available.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger settings load (router redirect reacts when done)
    ref.watch(settingsNotifierProvider);

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── App icon ─────────────────────────────────────────────────
            Container(
              width:  100, height: 100,
              decoration: BoxDecoration(
                color:        cs.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size:  56,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 24),

            // ── App name ─────────────────────────────────────────────────
            Text(
              'FocusFlow',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color:      cs.primary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Stay focused. Stay on track.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),

            // ── Loading indicator ─────────────────────────────────────────
            SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color:       cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
