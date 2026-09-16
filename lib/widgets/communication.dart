import 'package:flutter/material.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';

// BADGE
class NotificationBadge extends StatelessWidget {
  final int count;

  const NotificationBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: AsanColorScheme.secondary,
        borderRadius: BorderRadius.circular(100),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AsanTextTheme.labelSmall.copyWith(
          color: AsanColorScheme.onSecondary,
          fontWeight: FontWeight.bold,
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
          'You have changes that won’t be saved if you close.',
          style: AsanTextTheme.bodyMedium,
        ),
        actions: [
          AsanTextButton.black(
            label: 'Keep Editing',
            onPressed: () => Navigator.pop(context, false),
          ),
          AsanTextButton.red(
            label: 'Discard',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}
