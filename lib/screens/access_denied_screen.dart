import 'package:flutter/material.dart';
import '../services/admin_access_service.dart';
import '../services/auth_service.dart';

class AccessDeniedScreen extends StatefulWidget {
  const AccessDeniedScreen({super.key});

  @override
  State<AccessDeniedScreen> createState() => _AccessDeniedScreenState();
}

class _AccessDeniedScreenState extends State<AccessDeniedScreen> {
  final _auth = AuthService();
  final _access = AdminAccessService();
  bool _checking = false;
  String? _message;

  Future<void> _recheck() async {
    setState(() => _checking = true);
    final result = await _access.checkAccess();
    if (!mounted) return;
    if (!result.isConfigured) {
      setState(() {
        _message = 'Admin list not configured in Firestore';
      });
    } else if (result.isAdmin) {
      Navigator.pushReplacementNamed(context, '/admin');
      return;
    } else {
      setState(() {
        _message = 'You are not authorized to access Admin Panel.';
      });
    }
    setState(() => _checking = false);
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/admin-login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('You are not authorized to access Admin Panel.'),
              if (_message != null) ...[
                const SizedBox(height: 8),
                Text(_message!),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _signOut,
                child: const Text('Sign out'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _checking ? null : _recheck,
                child: _checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Re-check Access'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
