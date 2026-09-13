import 'package:flutter/material.dart';

import 'package:asan/styles/theme.dart';

// =============================== COMMON BUTTONS ===============================

// PRIMARY
class PrimaryButton extends StatelessWidget {
  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final double height;

  const PrimaryButton({
    super.key,
    this.label,
    this.child,
    this.onPressed,
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild =
        child ??
        Text(
          label ?? '',
          style: AsanTextTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            height: 22 / 16,
            color: AsanColorScheme.onPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

    return Material(
      color: AsanColorScheme.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: buttonChild,
            ),
          ),
        ),
      ),
    );
  }
}

// SECONDARY

// OUTLINED
class AsanOutlinedButton extends StatelessWidget {
  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final double height;

  const AsanOutlinedButton({
    super.key,
    this.label,
    this.child,
    this.onPressed,
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild =
        child ??
        Text(
          label ?? '',
          style: AsanTextTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            height: 22 / 16,
            color: AsanColorScheme.secondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AsanColorScheme.secondary),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: buttonChild,
            ),
          ),
        ),
      ),
    );
  }
}

// TEXT

// =============================== ICON BUTTONS ===============================

// FILLED ICON
class FilledIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final bool isActive;

  const FilledIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? AsanColorScheme.primary : AsanColorScheme.container,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Center(
            child: IconTheme(
              data: const IconThemeData(
                size: 22,
                color: AsanColorScheme.secondary,
                weight: 700,
              ),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

// TONAL ICON BUTTONS

// square

// round

// STANDARD ICON
class StandardIconButton extends StatelessWidget {
  final Widget icon;
  final Widget? activeIcon;
  final bool isActive;
  final double size;

  const StandardIconButton({
    super.key,
    required this.icon,
    this.activeIcon,
    this.isActive = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(
        size: size,
        color: isActive ? AsanColorScheme.primary : AsanColorScheme.inactive,
        weight: 600,
      ),
      child: isActive ? (activeIcon ?? icon) : icon,
    );
  }
}

// =============================== SELECTION BUTTONS ===============================

// SEGMENTED BUTTON


// CHECHBOX


// RADIO


// FILTER CHIP
