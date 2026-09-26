import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';

// TEXT FIELD
class AsanTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool hasError;
  final String? errorText;
  final bool required;
  final bool expandsWithContent;
  final Widget? labelAction;
  final double horizontalPadding;

  const AsanTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.hasError = false,
    this.errorText,
    this.required = false,
    this.expandsWithContent = false,
    this.labelAction,
    this.horizontalPadding = AsanSpacing.sm,
  });

  @override
  State<AsanTextField> createState() => _AsanTextFieldState();
}

class _AsanTextFieldState extends State<AsanTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode()..addListener(_updateState);
    _controller.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_updateState);
    _focusNode
      ..removeListener(_updateState)
      ..dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _focusNode.hasFocus;
    final hasBorder = isActive || widget.hasError;
    final textColor = _controller.text.isEmpty
        ? AsanColorScheme.inactive
        : AsanColorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: AsanTextTheme.labelSmall.copyWith(
                color: AsanColorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.required) ...[
              const SizedBox(width: AsanSpacing.xs),
              Text(
                '(Required)',
                style: AsanTextTheme.labelSmall.copyWith(
                  color: AsanColorScheme.inactive,
                ),
              ),
            ],
            if (widget.labelAction != null) ...[
              const Spacer(),
              widget.labelAction!,
            ],
          ],
        ),
        const SizedBox(height: AsanSpacing.sm),
        Container(
          constraints: widget.expandsWithContent
              ? const BoxConstraints(minHeight: 38)
              : const BoxConstraints.tightFor(height: 38),
          padding: EdgeInsets.symmetric(
            horizontal: widget.horizontalPadding,
            vertical: AsanSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: hasBorder
                ? AsanColorScheme.surface
                : AsanColorScheme.container,
            borderRadius: BorderRadius.circular(AsanSpacing.sm),
            border: hasBorder
                ? Border.all(
                    color: isActive
                      ? AsanColorScheme.primary
                      : AsanColorScheme.error,
                  )
                : null,
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            keyboardType: widget.keyboardType,
            minLines: widget.expandsWithContent ? 1 : 1,
            maxLines: widget.expandsWithContent ? null : 1,
            style: AsanTextTheme.bodyMedium.copyWith(color: textColor),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AsanTextTheme.bodyMedium.copyWith(
                color: AsanColorScheme.inactive,
              ),
              border: InputBorder.none,
              isCollapsed: true,
            ),
            cursorColor: AsanColorScheme.primary,
            textAlignVertical: TextAlignVertical.center,
          ),
        ),
        if (widget.hasError && widget.errorText != null) ...[
          const SizedBox(height: AsanSpacing.xs),
          Text(
            widget.errorText!,
            style: AsanTextTheme.labelSmall.copyWith(color: AsanColorScheme.error),
          ),
        ],
      ],
    );
  }
}

// SEARCH BAR
class AsanSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final String initialQuery;

  const AsanSearchBar({
    super.key,
    required this.hintText,
    this.onChanged,
    this.initialQuery = '',
  });

  @override
  State<AsanSearchBar> createState() => _AsanSearchBarState();
}

class _AsanSearchBarState extends State<AsanSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool get _isActive => _focusNode.hasFocus || _controller.text.isNotEmpty;

  @override
  void initState() {
    super.initState();

    _controller.text = widget.initialQuery;

    _focusNode.addListener(_updateState);
    _controller.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _isActive;

    return Container(
      height: 38,
      padding: const EdgeInsets.all(AsanSpacing.sm),
      decoration: BoxDecoration(
        color: isActive ? AsanColorScheme.surface : AsanColorScheme.container,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: AsanColorScheme.primary) : null,
      ),
      child: Row(
        children: [
          IconTheme(
            data: IconThemeData(
              size: 22,
              color: isActive
                  ? AsanColorScheme.primary
                  : AsanColorScheme.inactive,
            ),
            child: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: AsanSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              style: AsanTextTheme.bodyMedium.copyWith(
                color: AsanColorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AsanTextTheme.bodyMedium.copyWith(
                  color: AsanColorScheme.inactive,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),

          if (_controller.text.isNotEmpty) ...[
            const SizedBox(width: AsanSpacing.sm),

            SizedBox(
              width: 22,
              height: 22,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: IconTheme(
                  data: const IconThemeData(
                    size: 22,
                    color: AsanColorScheme.primary,
                  ),
                  child: const Icon(Symbols.close_rounded),
                ),
                onPressed: _clearSearch,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// IMAGE PICKER
class AsanImagePicker extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  const AsanImagePicker({
    super.key,
    required this.imageBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: AsanColorScheme.container,
                  child: imageBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Symbols.add_photo_alternate_rounded,
                              size: 72,
                              color: AsanColorScheme.inactive,
                            ),
                            const SizedBox(height: AsanSpacing.sm),
                            Text(
                              'Add Recipe Image',
                              style: AsanTextTheme.labelSmall.copyWith(
                                color: AsanColorScheme.inactive,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Image.memory(imageBytes!, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          if (imageBytes != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: TonalIconButton.round(
                icon: const Icon(Symbols.edit_rounded, size: 16),
                onPressed: onTap,
              ),
            ),
        ],
      ),
    );
  }
}
