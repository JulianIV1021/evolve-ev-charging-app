import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';
import '../repository/account_repository.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accountRepository =
        RepositoryProvider.of<AccountRepositoryImpl>(context);

    return StreamBuilder<User?>(
      stream: accountRepository.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return BlocProvider(
          create: (context) => AccountBloc(accountRepository),
          child: _SignedInAccountView(user: user),
        );
      },
    );
  }
}

class _SignedInAccountView extends StatelessWidget {
  final User user;

  const _SignedInAccountView({required this.user});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF00C853).withOpacity(0.1),
              backgroundImage:
                  user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null
                  ? const Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xFF00C853),
                    )
                  : null,
            ),
            const SizedBox(height: 24),
            _buildInfoCard(
              icon: Icons.person,
              label: 'Name',
              value: user.displayName ?? 'Not set',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.email,
              label: 'Email',
              value: user.email ?? 'Not set',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.verified_user,
              label: 'Email Verified',
              value: user.emailVerified ? 'Yes' : 'No',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  context.read<AccountBloc>().add(SignOutEvent());
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00C853)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
