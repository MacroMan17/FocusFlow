import 'package:flutter/material.dart';
import '../../core/enums/priority_enum.dart';

class PriorityBadge extends StatelessWidget {
  final Priority priority;
  final bool compact;

  const PriorityBadge({super.key, required this.priority, this.compact = false});

  Color _color(BuildContext context) {
    switch (priority) {
      case Priority.high:
        return Colors.red.shade400;
      case Priority.medium:
        return Colors.orange.shade400;
      case Priority.low:
        return Colors.blue.shade400;
      case Priority.none:
        return Colors.grey.shade400;
    }
  }

  IconData get _icon {
    switch (priority) {
      case Priority.high:
        return Icons.keyboard_double_arrow_up_rounded;
      case Priority.medium:
        return Icons.keyboard_arrow_up_rounded;
      case Priority.low:
        return Icons.keyboard_arrow_down_rounded;
      case Priority.none:
        return Icons.remove_rounded;
    }
  }

  String get _label {
    switch (priority) {
      case Priority.high:   return 'High';
      case Priority.medium: return 'Medium';
      case Priority.low:    return 'Low';
      case Priority.none:   return 'None';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    if (compact) {
      return Icon(_icon, size: 16, color: color);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          _label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
