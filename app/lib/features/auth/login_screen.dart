import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_code_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  bool _resetSent = false;
  bool _passwordMode = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// Verifies an emailed code. [type] is OtpType.email for sign-in codes
  /// and OtpType.recovery for password reset codes.
  Future<bool> _verifyCode(OtpType type) async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the code from your email')),
      );
      return false;
    }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: code,
        type: type,
      );
      return true;
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifySignInCode() async {
    // A session from a sign-in code routes to the feed automatically.
    await _verifyCode(OtpType.email);
  }

  Future<void> _verifyResetCode() async {
    final ok = await _verifyCode(OtpType.recovery);
    if (ok && mounted) context.go('/reset-password');
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'firstlight://login-callback',
      );
      if (mounted) {
        setState(() {
          _sent = true;
          _codeController.clear();
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email first')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'firstlight://login-callback',
      );
      if (mounted) {
        setState(() {
          _resetSent = true;
          _codeController.clear();
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDevLinkDialog(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste magic link'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'https://...supabase.co/auth/v1/verify?token=...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final url = controller.text.trim();
              final uri = Uri.tryParse(url);
              final token = uri?.queryParameters['token'];
              final typeStr = uri?.queryParameters['type'] ?? 'magiclink';
              if (token == null || token.isEmpty) return;
              Navigator.of(ctx).pop();
              setState(() => _loading = true);
              try {
                final type = typeStr == 'recovery'
                    ? OtpType.recovery
                    : OtpType.magiclink;
                await Supabase.instance.client.auth.verifyOTP(
                  tokenHash: token,
                  type: type,
                );
              } on AuthException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text(e.message)),
                  );
                }
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'First Light',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Turn real birds into trading cards.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) =>
                    _passwordMode ? _signInWithPassword() : _sendMagicLink(),
              ),
              if (_passwordMode && _resetSent) ...[
                const SizedBox(height: 16),
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'We emailed you a password reset code.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AuthCodeField(
                  controller: _codeController,
                  onSubmitted: (_) => _verifyResetCode(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _verifyResetCode,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify code'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _resetSent = false),
                  child: const Text('Back to sign in'),
                ),
              ] else if (_passwordMode) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  onSubmitted: (_) => _signInWithPassword(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _signInWithPassword,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _passwordMode = false;
                        _passwordController.clear();
                      }),
                      child: const Text('Use magic link'),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _resetPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
              ] else if (_sent) ...[
                const SizedBox(height: 16),
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'We emailed you a sign-in code.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AuthCodeField(
                  controller: _codeController,
                  onSubmitted: (_) => _verifySignInCode(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _verifySignInCode,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify code'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _sent = false;
                    _codeController.clear();
                  }),
                  child: const Text('Use a different email'),
                ),
              ] else ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _sendMagicLink,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Magic Link'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _passwordMode = true),
                  child: const Text('Sign in with password'),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'New to First Light?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/signup'),
                    child: const Text('Create account'),
                  ),
                ],
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _showDevLinkDialog(context),
                  child: const Text('Dev: paste magic link'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
