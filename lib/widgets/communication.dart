import 'package:flutter/material.dart';
import 'package:asan/styles/theme.dart';

// BADGE
class NotificationBadge extends StatelessWidget {
  final int count;

  const NotificationBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 17,
      height: 16,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: AsanColorScheme.secondary,
        borderRadius: BorderRadius.circular(100),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: AsanTextTheme.labelSmall.copyWith(
          color: AsanColorScheme.onSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          height: 14 / 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ALERT DIALOG
class AsanAlertDialog {
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard changes?', style: AsanTextTheme.headlineSmall),
        content: Text(
          'Your changes will be lost.',
          style: AsanTextTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AsanTextTheme.bodyMedium.copyWith(
                color: AsanColorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Discard',
              style: AsanTextTheme.bodyMedium.copyWith(
                color: AsanColorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
