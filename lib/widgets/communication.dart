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
class AsanAlertDialog  extends StatelessWidget {
  final String title;
  final String content;
  final String cancelText;
  final String destructiveText;

  const AsanAlertDialog( {
    super.key,
    required this.title, 
    required this.content,
    required this.cancelText,
    required this.destructiveText,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    required String cancelText,
    required String destructiveText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AsanAlertDialog(
        title: title,
        content: content,
        cancelText: cancelText,
        destructiveText: destructiveText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AsanColorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(title, style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
      content: Text(content, style: AsanTextTheme.bodyMedium),
      actions: [
        AsanTextButton.black(
          label: cancelText,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText, style: TextStyle(color: AsanColorScheme.secondary, fontWeight: FontWeight.bold)),
        ),
        AsanTextButton.red(
          label: destructiveText,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(destructiveText, style: TextStyle(color: AsanColorScheme.error, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// PROGRESS INDICATOR
class AsanStepProgress extends StatelessWidget {
  final int stepCount;
  final int currentStep;
  final String title;

  const AsanStepProgress({
    super.key,
    required this.stepCount,
    required this.currentStep,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(stepCount, (index) {
            final isCompleted = index <= currentStep;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == stepCount - 1 ? 0 : AsanSpacing.xs,
                ),
                child: SizedBox(
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AsanColorScheme.primary
                          : AsanColorScheme.container,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AsanSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AsanTextTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Step ${currentStep + 1} of $stepCount',
              style: AsanTextTheme.labelSmall.copyWith(
                color: AsanColorScheme.inactive,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// EMPTY STATE
