import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

const _kTeal = Color(0xFF00695C);
const _kTeal400 = Color(0xFF26A69A);

class QuoteCard extends ConsumerWidget {
  const QuoteCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(dailyQuoteProvider);
    final tt = Theme.of(context).textTheme;

    return quoteAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (quote) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        child: Container(
          decoration: BoxDecoration(
            // Dark teal background gradient
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00352C), // deep teal
                Color(0xFF00251E), // darker
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            // Elevation shadow
            boxShadow: [
              BoxShadow(
                color: _kTeal.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left accent bar with glow ────────────────────
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _kTeal400,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kTeal400.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),

                // ── Quote content ────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Decorative quote mark
                        Text(
                          '❝',
                          style: TextStyle(
                            fontSize: 28,
                            color: _kTeal400.withValues(alpha: 0.5),
                            height: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Quote text
                        Text(
                          quote,
                          style: tt.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontStyle: FontStyle.italic,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Label row
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 11,
                              color: _kTeal400.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Daily inspiration',
                              style: tt.labelSmall?.copyWith(
                                color: _kTeal400.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
