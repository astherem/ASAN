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
            color: AsanColorScheme.onPrimary,
          ),
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
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Center(child: buttonChild),
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
            color: AsanColorScheme.secondary,
          ),
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
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Center(child: buttonChild),
          ),
        ),
      ),
    );
  }
}

// TEXT
class AsanTextButton extends StatelessWidget {
  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final Color color;

  const AsanTextButton({
    super.key,
    this.label,
    this.child,
    this.onPressed,
    this.color = AsanColorScheme.primary,
  }) : assert(label != null || child != null);

  const AsanTextButton.green({
    super.key,
    this.label,
    this.child,
    this.onPressed,
  }) : color = AsanColorScheme.primary,
       assert(label != null || child != null);

  const AsanTextButton.black({
    super.key,
    this.label,
    this.child,
    this.onPressed,
  }) : color = AsanColorScheme.secondary,
       assert(label != null || child != null);

  const AsanTextButton.red({super.key, this.label, this.child, this.onPressed})
    : color = AsanColorScheme.error,
      assert(label != null || child != null);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.all(8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const RoundedRectangleBorder(),
      ),
      child:
          child ??
          Text(
            label!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AsanTextTheme.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
    );
  }
}

// =============================== ICON BUTTONS ===============================

// FILLED ICON
class FilledIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final bool isActive;
  final int badgeCount;

  const FilledIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isActive = false,
    this.badgeCount = 0,
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
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              IconTheme(
                data: const IconThemeData(
                  size: 22,
                  color: AsanColorScheme.secondary,
                  weight: 700,
                ),
                child: icon,
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: _ButtonBadge(count: badgeCount),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ButtonBadge extends StatelessWidget {
  final int count;

  const _ButtonBadge({required this.count});

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
class CheckboxButton extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const CheckboxButton({super.key, this.value = false, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _SelectionButton(
      value: value,
      isCheckbox: true,
      onChanged: onChanged,
    );
  }
}

// RADIO
class RadioButton extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const RadioButton({super.key, this.value = false, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _SelectionButton(
      value: value,
      isCheckbox: false,
      onChanged: onChanged,
    );
  }
}

class _SelectionButton extends StatelessWidget {
  final bool value;
  final bool isCheckbox;
  final ValueChanged<bool>? onChanged;

  const _SelectionButton({
    required this.value,
    required this.isCheckbox,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final shape = isCheckbox
        ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
        : const CircleBorder();

    return Semantics(
      checked: value,
      enabled: onChanged != null,
      button: true,
      child: Material(
        color: value ? AsanColorScheme.secondary : Colors.transparent,
        shape: shape,
        child: InkWell(
          onTap: onChanged == null ? null : () => onChanged!(!value),
          customBorder: shape,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? AsanColorScheme.secondary : Colors.transparent,
              shape: isCheckbox ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isCheckbox ? BorderRadius.circular(4) : null,
              border: value
                  ? null
                  : Border.all(color: AsanColorScheme.inactive),
            ),
            child: value
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: AsanColorScheme.surface,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

// FILTER CHIP
class AsanFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onPressed;

  const AsanFilterChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AsanColorScheme.secondary : AsanColorScheme.container,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AsanTextTheme.bodyMedium.copyWith(
                  color: isSelected
                      ? AsanColorScheme.surface
                      : AsanColorScheme.inactive,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: AsanSpacing.xs),
                const Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: AsanColorScheme.surface,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback? onRemoved;

  const ActiveFilterChip({super.key, required this.label, this.onRemoved});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AsanColorScheme.secondary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onRemoved,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AsanTextTheme.labelSmall.copyWith(
                  color: AsanColorScheme.surface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AsanSpacing.xs),
              const Icon(
                Icons.close_rounded,
                size: 16,
                color: AsanColorScheme.surface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
