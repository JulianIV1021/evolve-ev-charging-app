import 'package:flutter/cupertino.dart';

/// Shown on cold start while Firebase resolves the auth session.
/// GoRouter's redirect automatically navigates away once [_AuthChangeNotifier]
/// fires its first event.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: Center(
        child: Image(
          image: AssetImage('assets/app_logo.png'),
          width: 120,
          height: 120,
        ),
      ),
    );
  }
}
