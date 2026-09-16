import 'package:flutter/material.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';

// BADGE
class AsanBadge extends StatelessWidget {
  final int count;

  const AsanBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: AsanColorScheme.secondary,
        borderRadius: BorderRadius.circular(100),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: AsanTextTheme.labelSmall.copyWith(
          color: AsanColorScheme.surface,
          fontSize: 9,
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
