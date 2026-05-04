import 'package:flutter/cupertino.dart';

import '../../design/tokens.dart';

/// Phase 5 will replace this with the full session history screen.
class ActivityPlaceholderScreen extends StatelessWidget {
  const ActivityPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Activity')),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.list_bullet,
              size: 64,
              color: EvroColors.primary,
            ),
            SizedBox(height: EvroSpacing.md),
            Text('Session History', style: EvroTypography.title2),
            SizedBox(height: EvroSpacing.sm),
            Text(
              'Coming in Phase 5',
              style: TextStyle(color: EvroColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
