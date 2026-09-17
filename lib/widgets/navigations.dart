import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/communication.dart';

// APP BAR
class AsanAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String screenTitle;
  final Widget? icon;
  final VoidCallback? onIconPressed;
  final double actionRightPadding;
  final PreferredSizeWidget? bottom;
  final bool forceElevated;
  final Color backgroundColor;
  final Color foregroundColor;

  const AsanAppBar({
    super.key,
    required this.screenTitle,
    this.icon,
    this.onIconPressed,
    this.actionRightPadding = AsanSpacing.lg,
    this.bottom,
    this.forceElevated = false,
    this.backgroundColor = AsanColorScheme.surface,
    this.foregroundColor = AsanColorScheme.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: forceElevated
            ? const [
                BoxShadow(
                  color: AsanColorScheme.shadow,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: AppBar(
        centerTitle: false,
        titleSpacing: AsanSpacing.lg,
        toolbarHeight: kToolbarHeight,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: backgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        clipBehavior: Clip.none,
        title: Text(screenTitle, style: AsanTextTheme.headlineSmall.copyWith(color: foregroundColor)),
        bottom: bottom == null
            ? null
            : PreferredSize(
                preferredSize: bottom!.preferredSize,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AsanSpacing.lg),
                  child: bottom!,
                ),
              ),
        actions: icon == null
            ? null
            : [
                Padding(
                  padding: EdgeInsets.only(right: actionRightPadding),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                    icon: IconTheme(
                      data: IconThemeData(
                        size: 32,
                        color: AsanColorScheme.secondary,
                        weight: 600,
                      ),
                      child: icon!,
                    ),
                    onPressed: onIconPressed,
                  ),
                ),
              ],
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

// FULLSCREEN DIALOG HEADER
class FullScreenDialogHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final String screenTitle;
  final VoidCallback? onBackPressed;

  const FullScreenDialogHeader({
    super.key,
    required this.screenTitle,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AsanSpacing.md),
      child: SizedBox(
        height: 34,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: AsanSpacing.md,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
                icon: const Icon(
                  Symbols.chevron_left_rounded,
                  size: 34,
                  weight: 600,
                ),
                onPressed:
                    onBackPressed ??
                    () {
                      Navigator.pop(context);
                    },
              ),
            ),
            Center(
              child: Text(
                screenTitle,
                style: AsanTextTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(34 + (AsanSpacing.md * 2));
}

// NAVIGATION BAR
class AsanNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final int groceriesBadgeCount;

  const AsanNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.groceriesBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: const BoxDecoration(
        color: AsanColorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(color: AsanColorScheme.shadow, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavigationItem(
              label: 'Recipes',
              icon: const Icon(Symbols.import_contacts_rounded, size: 30),
              activeIcon: const Icon(
                Symbols.import_contacts_rounded,
                size: 30,
                fill: 1,
              ),
              isSelected: selectedIndex == 0,
              onPressed: () => onDestinationSelected(0),
            ),
          ),
          Expanded(
            child: _NavigationItem(
              label: 'Meals',
              icon: const Icon(Symbols.calendar_today_rounded),
              activeIcon: const Icon(Symbols.calendar_today_rounded, fill: 1),
              isSelected: selectedIndex == 1,
              onPressed: () => onDestinationSelected(1),
            ),
          ),
          Expanded(
            child: _NavigationItem(
              label: 'Pantry',
              icon: const Icon(Symbols.inventory_2_rounded),
              activeIcon: const Icon(Symbols.inventory_2_rounded, fill: 1),
              isSelected: selectedIndex == 2,
              onPressed: () => onDestinationSelected(2),
            ),
          ),
          Expanded(
            child: _NavigationItem(
              label: 'Groceries',
              icon: const Icon(Symbols.shopping_cart_rounded),
              activeIcon: const Icon(Symbols.shopping_cart_rounded, fill: 1),
              isSelected: selectedIndex == 3,
              badgeCount: groceriesBadgeCount,
              onPressed: () => onDestinationSelected(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final String label;
  final Widget icon;
  final Widget? activeIcon;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onPressed;

  const _NavigationItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    required this.isSelected,
    required this.onPressed,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AsanColorScheme.primary
        : AsanColorScheme.inactive;

    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              StandardIconButton(
                icon: icon,
                activeIcon: activeIcon,
                isActive: isSelected,
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: AsanBadge(count: badgeCount),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AsanTextTheme.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
