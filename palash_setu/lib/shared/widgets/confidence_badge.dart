import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ConfidenceBadge extends StatelessWidget {
  final String confidence; // 'high', 'medium', 'low'

  const ConfidenceBadge({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String label;

    switch (confidence.toLowerCase()) {
      case 'high':
        bg = AppTheme.confidenceHigh;
        label = 'High Reliability';
        break;
      case 'medium':
        bg = AppTheme.confidenceMedium;
        label = 'Medium Reliability';
        break;
      case 'low':
      default:
        bg = AppTheme.confidenceLow;
        label = 'Low Reliability';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bg, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            confidence == 'high'
                ? Icons.check_circle_rounded
                : (confidence == 'medium' ? Icons.warning_rounded : Icons.error_rounded),
            color: bg,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: bg,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
