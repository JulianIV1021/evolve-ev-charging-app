import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'approval_gate.dart';
import 'auth/login_screen.dart';

// Legacy auth gate — not used in the new GoRouter flow.
// Auth state is now handled by GoRouter redirect in navigation/app_router.dart.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        final user = snap.data;
        if (user == null) return const LoginScreen();
        return const ApprovalGate();
      },
    );
  }
}
