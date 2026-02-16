import 'auth_service.dart';

class AdminAccessResult {
  AdminAccessResult({
    required this.isConfigured,
    required this.isAdmin,
    required this.allowlist,
  });

  final bool isConfigured;
  final bool isAdmin;
  final List<String> allowlist;
}

class AdminAccessService {
  AdminAccessService({
    AuthService? authService,
  }) : _authService = authService ?? AuthService();

  final AuthService _authService;

  Future<AdminAccessResult> checkAccess() async {
    final email = _authService.currentUser?.email?.trim().toLowerCase() ?? '';
    final doc = await _authService.firestore
        .collection('app_config')
        .doc('admins')
        .get();

    final data = doc.data();
    if (data == null || data['emails'] == null) {
      _debugLogs(email, [], false);
      return AdminAccessResult(
        isConfigured: false,
        isAdmin: false,
        allowlist: const [],
      );
    }

    final raw = data['emails'];
    final allowlist = raw is List
        ? raw.map((e) => e.toString().trim().toLowerCase()).toList()
        : <String>[];

    final isAdmin = email.isNotEmpty && allowlist.contains(email);
    _debugLogs(email, allowlist, isAdmin);
    return AdminAccessResult(
      isConfigured: true,
      isAdmin: isAdmin,
      allowlist: allowlist,
    );
  }

  void _debugLogs(String email, List<String> allowlist, bool isAdmin) {
    // Debug prints required by spec.
    // ignore: avoid_print
    print('loggedInEmail=$email');
    // ignore: avoid_print
    print('fetchedAllowlistEmails=$allowlist');
    // ignore: avoid_print
    print('isAdmin=$isAdmin');
  }
}
