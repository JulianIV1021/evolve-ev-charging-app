import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/ui/screens/home_screen/home_screen.dart';
import '../repository/account_repository.dart';
import 'evolve_auth_screen.dart';
import '../../../features/stations_feature/services/ocm_favorites_store.dart';
import '../../../features/stations_feature/bloc/sessions_event.dart';
import '../../../features/stations_feature/bloc/sessions_bloc.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accountRepository =
        RepositoryProvider.of<AccountRepositoryImpl>(context);

    return StreamBuilder<User?>(
      stream: accountRepository.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          _ensureUserDoc(snapshot.data!);
          // Load favorites for this user.
          OcmFavoritesStore.instance.loadForUser(snapshot.data!.uid);
          // Refresh charging sessions stream for the signed-in user.
          try {
            // ignore: use_build_context_synchronously
            BlocProvider.of<SessionsBloc>(context, listen: false)
                .add(LoadSessionsEvent());
          } catch (_) {
            // If SessionsBloc is not in scope, fail silently.
          }
          return const HomeScreen();
        }

        // Clear favorites when signed out.
        OcmFavoritesStore.instance.loadForUser(null);
        return const EvolveAuthScreen();
      },
    );
  }

  Future<void> _ensureUserDoc(User user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL,
        'phoneNumber': user.phoneNumber,
        'emailVerified': user.emailVerified,
        'providerIds': user.providerData.map((p) => p.providerId).toList(),
        'lastLogin': FieldValue.serverTimestamp(),
        'createdAt': user.metadata.creationTime ?? FieldValue.serverTimestamp(),
        'lastSignInTime': user.metadata.lastSignInTime,
      }, SetOptions(merge: true));
    } catch (_) {
      // Avoid blocking UI; favorites and auth still work even if this fails.
    }
  }
}
