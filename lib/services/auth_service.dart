import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:asan/styles/theme.dart';
import 'package:asan/widgets/buttons.dart';
import 'package:asan/widgets/inputs.dart';

enum _AuthPage { onboarding, signUp, signIn, forgotPassword }

class AuthService extends StatefulWidget {
  const AuthService({required this.client, super.key});

  final SupabaseClient client;

  @override
  State<AuthService> createState() => _AuthServiceState();
}

class _AuthServiceState extends State<AuthService> {
  final _signUpUsernameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _forgotPasswordEmailController = TextEditingController();
  _AuthPage _page = _AuthPage.onboarding;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _message;
  bool _isError = false;
  String? _emailError;
  String? _usernameError;
  String? _passwordError;


  bool get _isSignUp => _page == _AuthPage.signUp;
  bool get _isForgotPassword => _page == _AuthPage.forgotPassword;

  TextEditingController get _emailController => switch (_page) {
    _AuthPage.signUp => _signUpEmailController,
    _AuthPage.signIn => _signInEmailController,
    _AuthPage.forgotPassword => _forgotPasswordEmailController,
    _AuthPage.onboarding => _signInEmailController,
  };
  TextEditingController get _passwordController => _isSignUp
      ? _signUpPasswordController
      : _signInPasswordController;

  @override
  void dispose() {
    _signUpUsernameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _forgotPasswordEmailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _signUpUsernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _usernameError = !_isSignUp || username.isNotEmpty
          ? null
          : 'Enter a username.';
      _emailError = email.contains('@') ? null : 'Enter a valid email address.';
      _passwordError = password.length >= 6
          ? null
          : 'Password must be at least 6 characters.';
    });
    if (_usernameError != null || _emailError != null || _passwordError != null) return;
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      if (_isSignUp) {
        final response = await widget.client.auth.signUp(
          email: email,
          password: password,
          data: {'username': username},
        );
        if (!mounted) return;
        setState(() {
          _message = response.session == null
              ? 'Check your email to confirm your account.'
              : 'Account created.';
          _isError = false;
        });
      } else {
        await widget.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message;
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _message = 'Enter your email address first.';
        _isError = true;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      await widget.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      setState(() {
        _message = 'Password reset instructions sent to your email.';
        _isError = false;
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.message;
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAuth(_AuthPage page) {
    setState(() {
      _page = page;
      _message = null;
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asan',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AsanColorScheme.primary,
          onPrimary: AsanColorScheme.onPrimary,
          secondary: AsanColorScheme.secondary,
          onSecondary: AsanColorScheme.onSecondary,
          surface: AsanColorScheme.surface,
          onSurface: AsanColorScheme.onSurface,
          error: AsanColorScheme.error,
          onError: AsanColorScheme.onError,
          surfaceContainerHighest: AsanColorScheme.container,
          onSurfaceVariant: AsanColorScheme.onContainer,
        ),
      ),
      home: Scaffold(
        backgroundColor: _page == _AuthPage.onboarding
            ? AsanColorScheme.primary
            : AsanColorScheme.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AsanSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _page == _AuthPage.onboarding
                    ? _buildOnboarding()
                    : _isForgotPassword
                        ? _buildForgotPasswordForm()
                        : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboarding() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 64),
        Center(
          child: Image.asset(
            'docs/assets/logos/black_logo.png',
            width: 192,
            height: 192,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Make meal plans easier,\nwith Asan',
          textAlign: TextAlign.center,
          style: AsanTextTheme.headlineSmall.copyWith(
            color: AsanColorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 64),
        SecondaryButton(
          label: 'Sign up',
          height: 50,
          onPressed: () => _openAuth(_AuthPage.signUp),
        ),
        const SizedBox(height: AsanSpacing.sm),
        PrimaryButton(
          label: 'Log in',
          height: 50,
          onPressed: () => _openAuth(_AuthPage.signIn),
        ),
      ],
    );
  }
  Widget _buildForgotPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: Image.asset('docs/assets/logos/green_filled_black_logo.png', width: 56, height: 56)),
        const SizedBox(height: AsanSpacing.md),
        Text('Reset your password', style: AsanTextTheme.headlineSmall),
        const SizedBox(height: AsanSpacing.sm),
        Text('Enter your account email and we’ll send you a reset link.', style: AsanTextTheme.bodyMedium),
        const SizedBox(height: AsanSpacing.lg),
        AsanTextField(
          label: 'Email',
          hintText: 'Enter your email address',
          key: const ValueKey('forgot-password-email'),
          labelStyle: AsanTextTheme.labelSmall.copyWith(color: AsanColorScheme.inactive, fontWeight: FontWeight.normal),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: AsanSpacing.lg),
        PrimaryButton(
          onPressed: _isLoading ? null : _sendResetEmail,
          height: 48,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Send reset link', style: AsanTextTheme.bodyMedium.copyWith(color: AsanColorScheme.onPrimary, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: AsanSpacing.sm),
        AsanTextButton(label: 'Back to log in', onPressed: _isLoading ? null : () => _openAuth(_AuthPage.signIn)),
        if (_message != null) ...[
          const SizedBox(height: AsanSpacing.md),
          Text(_message!, textAlign: TextAlign.center, style: AsanTextTheme.bodyMedium.copyWith(color: _isError ? Theme.of(context).colorScheme.error : AsanColorScheme.primary)),
        ],
      ],
    );
  }
  Widget _buildForm() {
    final title = _isSignUp ? 'Create your Asan account' : 'Log in to Asan';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [


        Center(
          child: Image.asset(
            'docs/assets/logos/green_filled_black_logo.png',
            width: 56,
            height: 56,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: AsanSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AsanTextTheme.headlineSmall,
        ),
        const SizedBox(height: AsanSpacing.sm),
        Text(
          _isSignUp
              ? 'Create an account to access your food data on every device.'
              : 'Log in to sync your pantry, groceries, recipes, and meal plan.',
          textAlign: TextAlign.center,
          style: AsanTextTheme.bodyMedium,
        ),
        const SizedBox(height: AsanSpacing.lg),
        if (_isSignUp) ...[
          AsanTextField(
            label: 'Username',
            hintText: 'Choose a username',
            key: const ValueKey('sign-up-username'),
            labelStyle: AsanTextTheme.labelSmall.copyWith(
              color: AsanColorScheme.inactive,
              fontWeight: FontWeight.normal,
            ),
            controller: _signUpUsernameController,
            autofillHints: const [AutofillHints.username],
            hasError: _usernameError != null,
            errorText: _usernameError,
            onChanged: (_) {
              if (_usernameError != null) setState(() => _usernameError = null);
            },
          ),
          const SizedBox(height: AsanSpacing.md),
        ],
        AsanTextField(
          label: 'Email',
          hintText: 'you@example.com',
          key: ValueKey(_isSignUp ? 'sign-up-email' : 'sign-in-email'),
          labelStyle: AsanTextTheme.labelSmall.copyWith(
            color: AsanColorScheme.inactive,
            fontWeight: FontWeight.normal,
          ),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          hasError: _emailError != null,
          errorText: _emailError,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
        ),
        const SizedBox(height: AsanSpacing.md),
        AsanTextField(
          label: 'Password',
          key: ValueKey(_isSignUp ? 'sign-up-password' : 'sign-in-password'),
          hintText: _isSignUp ? 'Create a password' : 'Enter your password',
          labelStyle: AsanTextTheme.labelSmall.copyWith(
            color: AsanColorScheme.inactive,
            fontWeight: FontWeight.normal,
          ),
          controller: _passwordController,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          hasError: _passwordError != null,
          errorText: _passwordError,
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
        ),
        if (!_isSignUp)
          Padding(
            padding: const EdgeInsets.only(top: AsanSpacing.sm),
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: 0.8,
                        alignment: Alignment.center,
                        child: CheckboxButton(
                          value: _rememberMe,
                          onChanged: _isLoading
                              ? null
                              : (value) => setState(() => _rememberMe = value),
                        ),
                      ),
                      const SizedBox(width: AsanSpacing.xs),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Remember me',
                          style: AsanTextTheme.labelSmall.copyWith(
                            color: _rememberMe
                                ? AsanColorScheme.secondary
                                : AsanColorScheme.inactive,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AsanTextButton(
                      label: 'Forgot password?',
                      color: AsanColorScheme.secondary,
                      padding: EdgeInsets.zero,
                      onPressed: _isLoading ? null : () => _openAuth(_AuthPage.forgotPassword),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AsanSpacing.lg),
        PrimaryButton(
          onPressed: _isLoading ? null : _submit,
          height: 48,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _isSignUp ? 'Create account' : 'Log in',
                  style: AsanTextTheme.bodyMedium.copyWith(
                    color: AsanColorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: AsanSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              _isSignUp ? 'Already have an account?' : 'Don\'t have an account?',
              style: AsanTextTheme.labelSmall.copyWith(
                color: AsanColorScheme.inactive,
              ),
            ),
            AsanTextButton(
              label: _isSignUp ? 'Log in' : 'Create an account',
              onPressed: _isLoading
                  ? null
                  : () => _openAuth(
                        _isSignUp ? _AuthPage.signIn : _AuthPage.signUp,
                      ),
            ),
          ],
        ),
        if (_message != null) ...[
          const SizedBox(height: AsanSpacing.md),
          Text(
            _message!,
            textAlign: TextAlign.center,
            style: AsanTextTheme.bodyMedium.copyWith(
              color: _isError
                  ? Theme.of(context).colorScheme.error
                  : AsanColorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}
