import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/admin_access_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _auth = AuthService();
  final _access = AdminAccessService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await _auth.signInWithEmailPassword(
        _email.text.trim(),
        _password.text.trim(),
      );
      if (!mounted) return;
      await _evaluateAdminAccess();
    } catch (e) {
      _showSnack('Login failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _signUp() async {
    setState(() => _loading = true);
    try {
      await _auth.signUpWithEmailPassword(
        _email.text.trim(),
        _password.text.trim(),
      );
      if (!mounted) return;
      _showSnack('Account created');
      await _evaluateAdminAccess();
    } catch (e) {
      _showSnack('Sign up failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _evaluateAdminAccess() async {
    final result = await _access.checkAccess();
    if (!mounted) return;
    if (!result.isConfigured) {
      _showSnack('Admin list not configured in Firestore');
      Navigator.pushReplacementNamed(context, '/access-denied');
      return;
    }
    if (result.isAdmin) {
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      Navigator.pushReplacementNamed(context, '/access-denied');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Log In'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : _signUp,
              child: const Text('Create Account (Sign Up)'),
            ),
          ],
        ),
      ),
    );
  }
}
