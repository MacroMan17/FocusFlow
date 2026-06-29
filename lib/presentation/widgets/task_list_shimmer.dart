import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TaskListShimmer extends StatelessWidget {
  final int itemCount;
  const TaskListShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final base = cs.surfaceContainerHighest;
    final high = cs.surfaceContainerLow;

    return Shimmer.fromColors(
      baseColor:      base,
      highlightColor: high,
      child: ListView.separated(
        padding:          const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount:        itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _ShimmerCard(index: i),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final int index;
  const _ShimmerCard({required this.index});

  @override
  Widget build(BuildContext context) {
    // Vary widths slightly to look natural
    final titleWidth  = index % 3 == 0 ? 0.7 : index % 3 == 1 ? 0.55 : 0.8;
    final hasSubtitle = index % 2 == 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox placeholder
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title line
                Container(
                  height: 14,
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * titleWidth,
                  ),
                  decoration: BoxDecoration(
                    color:        Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 11,
                    width:  double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.45,
                    ),
                    decoration: BoxDecoration(
                      color:        Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // Badge row
                Row(
                  children: [
                    Container(
                      width: 40, height: 10,
                      decoration: BoxDecoration(
                        color:        Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 60, height: 10,
                      decoration: BoxDecoration(
                        color:        Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
