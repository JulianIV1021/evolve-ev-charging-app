import 'package:flutter/cupertino.dart';

import '../../design/tokens.dart';

/// Phase 1 will replace this with the live Google Maps station screen.
class StationsPlaceholderScreen extends StatelessWidget {
  const StationsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Stations')),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.map, size: 64, color: EvroColors.primary),
            SizedBox(height: EvroSpacing.md),
            Text('Station Map', style: EvroTypography.title2),
            SizedBox(height: EvroSpacing.sm),
            Text(
              'Coming in Phase 1',
              style: TextStyle(color: EvroColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
