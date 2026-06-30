import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Quote Card — matches screenshot:
//   dark teal bg, mountain silhouette via gradient, large ❝ mark,
//   italic quote text, cyan "Daily inspiration" label, shooting-star accent
// ─────────────────────────────────────────────────────────────────────────────

const _kTeal = Color(0xFF00C896);
class QuoteCard extends ConsumerWidget {
  const QuoteCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(dailyQuoteProvider);

    return quoteAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (quote) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            // Dark teal gradient — matches screenshot's landscape bg
            gradient: const LinearGradient(
              colors: [
                Color(0xFF001A14),
                Color(0xFF002E22),
                Color(0xFF004230),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: _kTeal.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: _kTeal.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Mountain silhouette — subtle dark shape at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0x4A001A14)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Horizon glow
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _kTeal.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Large decorative quote mark
                    Text(
                      '❝❝',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 34,
                        color: _kTeal.withValues(alpha: 0.7),
                        height: 0.9,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Quote text — 18sp italic
                    Text(
                      quote,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: Color(0xE6FFFFFF), // 90%
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // "✦ Daily inspiration" label
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 13, color: _kTeal),
                        const SizedBox(width: 5),
                        Text(
                          'Daily inspiration',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kTeal,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
