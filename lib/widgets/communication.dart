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
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16, maxHeight: 16),
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
  final bool primaryAction;

  const AsanAlertDialog( {
    super.key,
    required this.title, 
    required this.content,
    required this.cancelText,
    required this.destructiveText,
    this.primaryAction = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    required String cancelText,
    required String destructiveText,
    bool primaryAction = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AsanAlertDialog(
        title: title,
        content: content,
        cancelText: cancelText,
        destructiveText: destructiveText,
        primaryAction: primaryAction,
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
      actionsAlignment: MainAxisAlignment.end,
      actionsPadding: const EdgeInsets.fromLTRB(AsanSpacing.lg, 0, AsanSpacing.lg, AsanSpacing.lg),
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AsanTextButton.black(
              label: cancelText,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(width: AsanSpacing.lg),
            primaryAction
                ? AsanTextButton(
                    label: destructiveText,
                    onPressed: () => Navigator.of(context).pop(true),
                  )
                : AsanTextButton.red(
              label: destructiveText,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
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
class AsanEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Widget? actionIcon;
  final VoidCallback? onAction;

  const AsanEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon = const Icon(Icons.add_rounded, weight: 600),
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AsanSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: AsanColorScheme.inactive),
            const SizedBox(height: AsanSpacing.lg),
            Text(title, style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: AsanSpacing.sm),
            Text(
              message,
              style: AsanTextTheme.bodyMedium.copyWith(color: AsanColorScheme.inactive),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AsanSpacing.lg),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: PrimaryButton(
                  label: actionLabel!,
                  icon: actionIcon,
                  onPressed: onAction!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// SNACKBAR
class AsanSnackBar {
  const AsanSnackBar._();

  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    showOn(messenger, message: message, actionLabel: actionLabel, onAction: onAction);
  }

  static void showOn(
    ScaffoldMessengerState messenger, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: AsanTextTheme.labelSmall.copyWith(
                    color: AsanColorScheme.onSurface,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: AsanSpacing.sm),
                AsanTextButton(label: actionLabel, onPressed: onAction),
              ],
            ],
          ),
          backgroundColor: AsanColorScheme.surface,
          behavior: SnackBarBehavior.floating,
          elevation: 8,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(AsanSpacing.md),
        ),
      );
  }
}
