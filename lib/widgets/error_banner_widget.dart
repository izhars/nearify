// widgets/error_banner_widget.dart
import 'package:flutter/material.dart';

class ErrorBannerWidget extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;

  const ErrorBannerWidget({
    super.key,
    required this.error,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Error',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    error,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: Colors.red.shade600,
                size: 20,
              ),
              onPressed: onDismiss,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Dismiss error',
            ),
          ],
        ),
      ),
    );
  }
}