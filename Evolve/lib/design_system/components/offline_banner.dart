import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none));
});

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Drop this at the top of any screen to show an offline banner when needed.
/// Wrap it in an `AnimatedSize` or just place it in a `Column`.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);

    return connectivityAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (isOnline) {
        if (isOnline) return const SizedBox.shrink();
        return _BannerContent();
      },
    );
  }
}

class _BannerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: AppColors.warning,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(CupertinoIcons.wifi_slash,
                size: 16, color: CupertinoColors.white),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'No internet connection — some features may be unavailable',
                style: AppTypography.caption1.copyWith(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
