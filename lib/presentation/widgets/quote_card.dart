import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Quote Card
// Spec: 18sp italic / 85% opacity, author 14sp Medium / 60% opacity
//       4dp left accent border, dark glass background, teal glow
// ─────────────────────────────────────────────────────────────────────────────

class QuoteCard extends ConsumerWidget {
  const QuoteCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(dailyQuoteProvider);

    return quoteAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (quote) {
        // Split "quote — Author" if present
        String quoteText = quote;
        String? author;
        final dashIdx = quote.lastIndexOf('—');
        if (dashIdx > 0 && dashIdx < quote.length - 1) {
          quoteText = quote.substring(0, dashIdx).trim();
          author = quote.substring(dashIdx + 1).trim();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(kPad, 0, kPad, 0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF), // glass
              borderRadius: BorderRadius.circular(kCardRadius),
              border: Border.all(color: kDivider),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 4dp left accent border with glow ──────────
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: kAccent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(kCardRadius),
                        bottomLeft: Radius.circular(kCardRadius),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kAccent.withValues(alpha: 0.45),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),

                  // ── Quote body ─────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quote text: 18sp / Regular / Italic / 85% opacity
                          Text(
                            '"$quoteText"',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              color: Color(0xD9FFFFFF), // 85%
                              height: 28 / 18,
                            ),
                          ),

                          // Author: 14sp / Medium / 60% opacity
                          if (author != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '— $author',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0x99FFFFFF), // 60%
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
