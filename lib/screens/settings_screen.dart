import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:asan/data/local_storage.dart';
import 'package:asan/models/filters.dart';
import 'package:asan/styles/theme.dart';

import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/communication.dart';
import 'package:asan/widgets/containment.dart';
import 'package:asan/widgets/inputs.dart';
import 'package:asan/widgets/navigations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({this.client, this.storage, this.onDefaultServingsChanged, this.onFoodPreferencesChanged, this.onFirstDayOfWeekChanged, super.key});

  final SupabaseClient? client;
  final LocalStorage? storage;
  final ValueChanged<int>? onDefaultServingsChanged;
  final ValueChanged<Map<String, List<String>>>? onFoodPreferencesChanged;
  final ValueChanged<String>? onFirstDayOfWeekChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, Set<String>> _preferences = {
    'cuisines': <String>{},
    'diets': <String>{},
    'first_day_of_week': <String>{},
    'serving_size': <String>{},
  };
  final Map<String, bool> _expandedSections = {
    'Cuisines': false,
    'Dietary restrictions': false,
    'First day of the week': false,
    'Serving size': false,
  };
  static const _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  Uint8List? _profileImage;
  String? _localUsername;
  String? _localEmail;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final local = widget.storage?.loadProfilePreferences() ?? {};
    _localUsername = local['profile_username'] as String?;
    _localEmail = local['profile_email'] as String?;
    final encodedImage = local['profile_image'] as String?;
    final metadataPreferences = widget.client?.auth.currentUser?.userMetadata?['preferences'];
    final saved = metadataPreferences is Map
        ? Map<String, dynamic>.from(metadataPreferences)
        : local;
    for (final key in _preferences.keys) {
      final values = saved[key];
      if (values is List) _preferences[key]!.addAll(values.whereType<String>());
    }
    if (encodedImage != null) {
      try {
        _profileImage = base64Decode(encodedImage);
      } catch (_) {
        _profileImage = null;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggle(String key, String value, {bool singleSelect = false}) async {
    setState(() {
      final values = _preferences[key]!;
      if (singleSelect) {
        values
          ..clear()
          ..add(value);
      } else {
        values.contains(value) ? values.remove(value) : values.add(value);
      }
      _saving = true;
    });
    final payload = {
      for (final entry in _preferences.entries)
        entry.key: entry.value.toList()..sort(),
    };
    if (key == 'cuisines' || key == 'diets') {
      widget.onFoodPreferencesChanged?.call({
        'cuisines': payload['cuisines']!,
        'diets': payload['diets']!,
      });
    }
    if (key == 'first_day_of_week') {
      widget.onFirstDayOfWeekChanged?.call(value);
    }
    try {
      final local = widget.storage?.loadProfilePreferences() ?? {};
      local.remove('allergens');
      await widget.storage?.saveProfilePreferences({...local, ...payload});
      if (widget.client?.auth.currentUser != null) {
        await widget.client!.auth.updateUser(UserAttributes(data: {'preferences': payload}));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not sync preferences. They are saved on this device.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await AsanAlertDialog.show(
      context,
      title: 'Log out?',
      content: 'Are you sure you want to log out?',
      cancelText: 'Cancel',
      destructiveText: 'Log out',
    );

    if (shouldLogout == true) await widget.client!.auth.signOut();
  }

  Future<void> _editProfile() async {
    final user = widget.client?.auth.currentUser;
    final metadata = user?.userMetadata ?? {};
    final update = await showDialog<_ProfileUpdate>(
      context: context,
      useSafeArea: false,
      barrierDismissible: false,
      builder: (_) => _EditProfileDialog(
        initialUsername: metadata['username'] as String? ?? _localUsername ?? '',
        initialEmail: user?.email ?? _localEmail ?? '',
        initialImage: _profileImage,
      ),
    );
    if (update == null) return;
    final local = widget.storage?.loadProfilePreferences() ?? {};
    local['profile_username'] = update.username;
    local['profile_email'] = update.email;
    if (update.image != null) {
      local['profile_image'] = base64Encode(update.image!);
    }
    await widget.storage?.saveProfilePreferences(local);
    _localUsername = update.username;
    _localEmail = update.email;
    if (widget.client != null) {
      await widget.client!.auth.updateUser(
        UserAttributes(
          email: update.email == user?.email ? null : update.email,
          data: {
            ...metadata,
            'username': update.username,
            // Clear profile keys written by older versions of the app.
            'name': null,
            'full_name': null,
          },
        ),
      );
    }
    if (mounted) {
      setState(() => _profileImage = update.image ?? _profileImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.client?.auth.currentUser;
    final username = user?.userMetadata?['username'] as String? ?? _localUsername;
    final email = user?.email ?? _localEmail;
    return Scaffold(
      appBar: const AsanAppBar(screenTitle: 'Settings'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AsanSpacing.lg,
            0,
            AsanSpacing.lg,
            AsanSpacing.lg,
          ),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _editProfile,
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: ClipOval(
                      child: _profileImage == null
                          ? Container(
                              color: AsanColorScheme.container,
                              child: const Icon(Symbols.person_rounded, size: 48, weight: 600, color: AsanColorScheme.inactive),
                            )
                          : Image.memory(_profileImage!, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(width: AsanSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username ?? (user == null ? 'Settings' : 'Welcome to Asan'),
                        style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (email?.isNotEmpty == true) ...[
                        const SizedBox(height: AsanSpacing.xs),
                        Text(email!, style: AsanTextTheme.bodyMedium.copyWith(color: AsanColorScheme.inactive), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: AsanSpacing.sm),
                      PrimaryButton(label: 'Edit Profile', onPressed: _editProfile),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AsanSpacing.lg),
            _section(title: 'Food and dietary restrictions', children: [
              _choices('Cuisines', 'cuisines', asanCuisines, icon: Symbols.globe_rounded),
              _choices('Dietary restrictions', 'diets', asanDiets, icon: Symbols.eco_rounded),
            ]),
            const SizedBox(height: AsanSpacing.md),
            _section(title: 'Meal plan preferences', children: [
              _choices('First day of the week', 'first_day_of_week', _days, icon: Symbols.today_rounded, singleSelect: true),
              _choices('Serving size', 'serving_size', const [], icon: Symbols.people_outline_rounded, singleSelect: true),
            ]),
            if (_saving) ...[
              const SizedBox(height: AsanSpacing.sm),
              Text('Saving preferences…', style: AsanTextTheme.labelSmall),
            ],
            if (widget.client != null) ...[
              const SizedBox(height: AsanSpacing.lg),
              Material(
                color: AsanColorScheme.error,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _confirmLogout,
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Center(
                      child: Text(
                        'Log out',
                        style: AsanTextTheme.bodyMedium.copyWith(
                          color: AsanColorScheme.onError,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: AsanSpacing.sm, bottom: AsanSpacing.sm),
        child: Text(title, style: AsanTextTheme.labelSmall.copyWith(color: AsanColorScheme.inactive, fontWeight: FontWeight.bold)),
      ),
      Material(
        color: AsanColorScheme.container,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AsanSpacing.md),
          child: Column(children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) ...[
                const AsanDivider(color: AsanColorScheme.inactive),
              ],
            ],
          ]),
        ),
      ),
    ],
  );

  Widget _choices(String title, String key, List<String> options, {required IconData icon, bool singleSelect = false}) {
    final isExpanded = _expandedSections[title]!;
    final selected = key == 'serving_size'
        ? _preferences[key]!.toList()
        : options.where(_preferences[key]!.contains).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AsanSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: () => setState(() => _expandedSections[title] = !isExpanded),
          child: Row(children: [
            Icon(icon, size: 18, weight: 600, color: AsanColorScheme.secondary),
            const SizedBox(width: AsanSpacing.sm),
            Expanded(child: Text(title, style: AsanTextTheme.bodyMedium.copyWith(color: AsanColorScheme.onContainer, fontWeight: FontWeight.bold))),
            Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, weight: 600, color: AsanColorScheme.onContainer),
          ]),
        ),
        if (!isExpanded) ...[
          const SizedBox(height: AsanSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              selected.isEmpty ? (key == 'diets' ? 'None' : 'Any') : selected.join(' · '),
              style: AsanTextTheme.labelSmall.copyWith(
                color: key == 'cuisines' ||
                        key == 'diets' ||
                        selected.isEmpty ||
                        key == 'first_day_of_week' ||
                        key == 'serving_size'
                    ? AsanColorScheme.inactive
                    : AsanColorScheme.onContainer,
              ),
            ),
          ),
        ],
        if (isExpanded) ...[
          const SizedBox(height: AsanSpacing.sm),
          if (key == 'first_day_of_week')
            AsanDropdownMenu(
              label: 'First day of the week',
              items: options,
              value: selected.isEmpty ? null : selected.first,
              hintText: 'Select a day',
              onChanged: (value) {
                if (value != null) _toggle(key, value, singleSelect: true);
              },
            )
          else if (key == 'serving_size')
            Row(
              children: [
                TonalIconButton.round(
                  icon: const Icon(Symbols.remove_rounded, size: 16, weight: 600),
                  color: _servingCount <= 1
                      ? AsanColorScheme.inactive
                      : AsanColorScheme.secondary,
                  backgroundColor: AsanColorScheme.container,
                  size: 32,
                  showShadow: false,
                  onPressed: _servingCount > 1
                      ? () => _setServingCount(_servingCount - 1)
                      : null,
                ),
                const SizedBox(width: AsanSpacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AsanSpacing.sm),
                  child: Text(
                    '$_servingCount ${_servingCount == 1 ? 'serving' : 'servings'}',
                    style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AsanSpacing.xs),
                TonalIconButton.round(
                  icon: const Icon(Symbols.add_rounded, size: 20, weight: 600),
                  color: AsanColorScheme.secondary,
                  backgroundColor: AsanColorScheme.container,
                  size: 36,
                  showShadow: false,
                  onPressed: () => _setServingCount(_servingCount + 1),
                ),
              ],
            )
          else
            Wrap(spacing: AsanSpacing.sm, runSpacing: AsanSpacing.sm, children: options.map((value) => AsanFilterChip(
              label: value,
              isSelected: _preferences[key]!.contains(value),
              onPressed: () => _toggle(key, value, singleSelect: singleSelect),
            )).toList()),
        ],
      ]),
    );
  }

  int get _servingCount {
    final values = _preferences['serving_size']!;
    return int.tryParse(values.isEmpty ? '' : values.first) ?? 1;
  }

  void _setServingCount(int value) {
    widget.onDefaultServingsChanged?.call(value);
    _toggle('serving_size', '$value', singleSelect: true);
  }

}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.initialUsername,
    required this.initialEmail,
    required this.initialImage,
  });

  final String initialUsername;
  final String initialEmail;
  final Uint8List? initialImage;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  final _imagePicker = ImagePicker();
  Uint8List? _image;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _emailController = TextEditingController(text: widget.initialEmail);
    _image = widget.initialImage;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _image = bytes);
  }

  Future<void> _showImageSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AsanColorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AsanSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Profile Photo',
                  style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: AsanSpacing.lg),
              PrimaryButton(
                label: 'Take a Photo',
                icon: const Icon(Symbols.photo_camera_rounded, size: 22, weight: 600, fill: 1),
                onPressed: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: AsanSpacing.md),
              SecondaryButton(
                label: 'Choose from Gallery',
                icon: const Icon(Symbols.image_rounded, size: 22, weight: 600, fill: 1),
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null) await _pickImage(source);
  }

  Future<void> _showImageActions() async {
    final changePhoto = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AsanColorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AsanSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Symbols.photo_camera_rounded, fill: 1, weight: 600),
                title: Text('Change photo', style: AsanTextTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                onTap: () => Navigator.pop(context, true),
              ),
              ListTile(
                leading: const Icon(Symbols.delete_rounded, fill: 1, weight: 600, color: AsanColorScheme.error),
                title: Text('Remove photo', style: AsanTextTheme.bodyMedium.copyWith(
                  color: AsanColorScheme.error, fontWeight: FontWeight.bold,
                )),
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || changePhoto == null) return;
    if (changePhoto) {
      await _showImageSourcePicker();
    } else {
      setState(() => _image = null);
    }
  }

  Future<void> _onPhotoPressed() =>
      _image == null ? _showImageSourcePicker() : _showImageActions();

  bool get _hasChanges =>
      _usernameController.text.trim() != widget.initialUsername.trim() ||
      _emailController.text.trim() != widget.initialEmail.trim() ||
      !_sameImage(_image, widget.initialImage);

  bool _sameImage(Uint8List? first, Uint8List? second) {
    if (identical(first, second)) return true;
    if (first == null || second == null || first.length != second.length) {
      return false;
    }
    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }
    return true;
  }

  Future<void> _handleClose() async {
    if (!_hasChanges) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final shouldDiscard = await AsanAlertDialog.show(
      context,
      title: 'Discard Changes?',
      content: 'You have changes that won\'t be saved if you close. Are you sure you want to discard them?',
      cancelText: 'Cancel',
      destructiveText: 'Discard',
    );
    if (shouldDiscard == true && mounted) Navigator.pop(context);
  }

  void _save() => Navigator.pop(
    context,
    _ProfileUpdate(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      image: _image,
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _handleClose();
        },
        child: Dialog.fullscreen(
        child: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: FullScreenDialogHeader(
              screenTitle: 'Edit profile',
              onBackPressed: _handleClose,
            ),
            body: Column(
              children: [
                Expanded(child: ListView(
              padding: const EdgeInsets.all(AsanSpacing.lg),
              children: [
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 128,
                        height: 128,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 8,
                              top: 8,
                              child: ClipOval(
                                child: SizedBox(
                                  width: 112,
                                  height: 112,
                                  child: _image == null
                                      ? const ColoredBox(
                                          color: AsanColorScheme.container,
                                          child: Icon(Symbols.person_rounded, size: 48, weight: 600, color: AsanColorScheme.inactive),
                                        )
                                      : Image.memory(_image!, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Material(
                                color: AsanColorScheme.container,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _onPhotoPressed,
                                  child: const SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Icon(Symbols.photo_camera_rounded, size: 21, weight: 600, color: AsanColorScheme.secondary),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _image == null ? 'Add Profile Photo' : 'Edit Profile Photo',
                        style: AsanTextTheme.labelSmall.copyWith(
                          color: AsanColorScheme.inactive,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AsanSpacing.md),
                AsanTextField(
                  label: 'Username',
                  controller: _usernameController,
                  autofillHints: const [AutofillHints.username],
                ),
                const SizedBox(height: AsanSpacing.md),
                AsanTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
              ],
              )),
                Padding(
                  padding: const EdgeInsets.all(AsanSpacing.lg),
                  child: PrimaryButton(label: 'Save', onPressed: _save),
                ),
              ],
            ),
          ),
        ),
      ));
}

class _ProfileUpdate {
  const _ProfileUpdate({
    required this.username,
    required this.email,
    required this.image,
  });

  final String username;
  final String email;
  final Uint8List? image;
}
