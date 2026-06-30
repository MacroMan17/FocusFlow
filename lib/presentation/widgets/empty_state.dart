import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kPad + 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon in gradient circle
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0x336C63FF),
                    Color(0x1A00E5FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: kDivider),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, size: 40, color: kPrimary),
            ).animate().scale(
                  duration: 450.ms,
                  curve: Curves.elasticOut,
                ),

            const SizedBox(height: 24),

            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: kText,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 380.ms, delay: 100.ms),

            const SizedBox(height: kTextGap),

            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: kTextSec,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 380.ms, delay: 180.ms),

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(actionLabel!),
              )
                  .animate()
                  .fadeIn(duration: 380.ms, delay: 260.ms)
                  .slideY(begin: 0.1, curve: Curves.easeOut),
            ],
          ],
        ),
      ),
    );
  }
}
