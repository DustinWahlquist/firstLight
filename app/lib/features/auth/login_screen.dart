import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  bool _passwordMode = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      if (mounted) setState(() => _sent = true);
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
      final url = Uri.parse('$supabaseUrl/auth/v1/recover');
      final httpClient = HttpClient();
      final request = await httpClient.postUrl(url);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set('apikey', supabaseAnonKey);
      request.write(jsonEncode({'email': email}));
      final response = await request.close();
      final body = await response.transform(const Utf8Decoder()).join();
      httpClient.close();

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent — check your inbox')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${response.statusCode}: $body')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
              if (_passwordMode) ...[
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
                      'Check your email for a magic link to sign in.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _sent = false),
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
