import 'package:flutter/cupertino.dart';

import '../../design/tokens.dart';

/// Phase 1+ will replace this with the live station search screen.
class SearchPlaceholderScreen extends StatelessWidget {
  const SearchPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('Search')),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.search, size: 64, color: EvroColors.primary),
            SizedBox(height: EvroSpacing.md),
            Text('Search Stations', style: EvroTypography.title2),
            SizedBox(height: EvroSpacing.sm),
            Text(
              'Coming in Phase 2',
              style: TextStyle(color: EvroColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
