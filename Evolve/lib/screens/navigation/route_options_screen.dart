import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/haptics/haptics.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../../models/route_option_model.dart';
import '../../providers/navigation_providers.dart';

class RouteOptionsScreen extends ConsumerStatefulWidget {
  const RouteOptionsScreen({super.key});

  @override
  ConsumerState<RouteOptionsScreen> createState() => _RouteOptionsScreenState();
}

class _RouteOptionsScreenState extends ConsumerState<RouteOptionsScreen> {
  RouteMode? _selectedMode;

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routeOptionsProvider);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFFFFFFFF),
        middle: Text(
          'Route Options',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
          ),
        ),
        leading: CupertinoNavigationBarBackButton(
          color: CupertinoColors.systemBlue,
        ),
      ),
      child: SafeArea(
        child: routesAsync.when(
          loading: () => const _LoadingState(),
          error: (e, _) => _ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(routeOptionsProvider),
          ),
          data: (routes) {
            if (routes.isEmpty) {
              return const _EmptyState();
            }
            if (_selectedMode == null && routes.isNotEmpty) {
              // Default select the greenest route
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _selectedMode = RouteMode.greenest);
                }
              });
            }
            return _RouteList(
              routes: routes,
              selectedMode: _selectedMode,
              onSelect: (mode) {
                AppHaptics.selectionClick();
                setState(() => _selectedMode = mode);
              },
              onConfirm: () => _onConfirm(routes),
            );
          },
        ),
      ),
    );
  }

  void _onConfirm(List<RouteOption> routes) {
    final selected = routes.firstWhere(
      (r) => r.mode == _selectedMode,
      orElse: () => routes.first,
    );
    AppHaptics.mediumImpact();
    ref.read(selectedRouteProvider.notifier).state = selected;
    context.push('/navigation-flow');
  }
}

// ---------------------------------------------------------------------------
// Route list
// ---------------------------------------------------------------------------

class _RouteList extends StatelessWidget {
  const _RouteList({
    required this.routes,
    required this.selectedMode,
    required this.onSelect,
    required this.onConfirm,
  });

  final List<RouteOption> routes;
  final RouteMode? selectedMode;
  final ValueChanged<RouteMode> onSelect;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: routes.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) {
              final r = routes[i];
              return _RouteCard(
                route: r,
                isSelected: selectedMode == r.mode,
                onTap: () => onSelect(r.mode),
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.all(16),
          child: CupertinoButton(
            color: const Color(0xFFF5A623),
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(vertical: 16),
            onPressed: selectedMode == null ? null : onConfirm,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.location_fill,
                    color: CupertinoColors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  selectedMode == null ? 'Select a Route' : 'Start Navigation',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Single route card
// ---------------------------------------------------------------------------

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.isSelected,
    required this.onTap,
  });

  final RouteOption route;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, icon, accentColor) = _modeStyle(route.mode);
    final etaMins = route.eta.inMinutes;
    final distStr = route.distanceKm.toStringAsFixed(1);
    final energyStr = route.estimatedEnergyKwh.toStringAsFixed(1);
    final socPct = (route.estimatedArrivalSocPercent * 100).toInt();

    final (iconBg, borderColor) = _cardColors(route.mode, isSelected, accentColor);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 22, color: accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        Text(
                          '$etaMins min · $distStr km',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: accentColor,
                      size: 22,
                    ),
                ],
              ),
            ),

            // Divider
            Container(height: 0.5, color: const Color(0xFFE5E5EA)),

            // Stats row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  _Stat(
                    icon: CupertinoIcons.bolt_fill,
                    label: '$energyStr kWh',
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _Stat(
                    icon: CupertinoIcons.battery_25,
                    label: 'Arrive $socPct%',
                    color: socPct < 15 ? AppColors.error : AppColors.textSecondary,
                  ),
                  if (route.chargingStops.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.lg),
                    _Stat(
                      icon: CupertinoIcons.exclamationmark_triangle_fill,
                      label: 'Stop needed',
                      color: AppColors.warning,
                    ),
                  ],
                  if (route.mode == RouteMode.greenest) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.leaf_arrow_circlepath,
                              size: 12, color: Color(0xFF34C759)),
                          SizedBox(width: 4),
                          Text(
                            'Most eco-friendly',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF34C759),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, IconData, Color) _modeStyle(RouteMode mode) {
    return switch (mode) {
      RouteMode.fastest => ('Fastest', CupertinoIcons.timer, const Color(0xFFF5A623)),
      RouteMode.cheapest => ('Most Efficient', CupertinoIcons.arrow_down_circle_fill, const Color(0xFF34C759)),
      RouteMode.greenest => ('Greenest Route', CupertinoIcons.leaf_arrow_circlepath, const Color(0xFF34C759)),
    };
  }

  (Color, Color) _cardColors(RouteMode mode, bool isSelected, Color accentColor) {
    final iconBg = switch (mode) {
      RouteMode.fastest => const Color(0xFFFFF3DC),
      RouteMode.cheapest => const Color(0xFFE8F5E9),
      RouteMode.greenest => const Color(0xFFE8F5E9),
    };
    Color borderColor;
    if (!isSelected) {
      borderColor = const Color(0xFFE5E5EA);
    } else if (mode == RouteMode.greenest) {
      borderColor = const Color(0xFF34C759);
    } else {
      borderColor = CupertinoColors.systemBlue;
    }
    return (iconBg, borderColor);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style:
                  AppTypography.caption1.copyWith(color: color)),
        ],
      );
}


// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: 16),
            const SizedBox(height: AppSpacing.md),
            Text('Calculating routes…',
                style: AppTypography.callout
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.exclamationmark_circle,
                  size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Failed to load routes',
                  style: AppTypography.headline.copyWith(color: AppColors.label)),
              const SizedBox(height: AppSpacing.xs),
              Text(message,
                  style: AppTypography.subhead
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.xl),
                CupertinoButton(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(14),
                  onPressed: onRetry,
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.map, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text('No routes found',
                  style: AppTypography.headline.copyWith(color: AppColors.label)),
              const SizedBox(height: AppSpacing.xs),
              Text('Could not find a route to this station.',
                  style: AppTypography.subhead
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
