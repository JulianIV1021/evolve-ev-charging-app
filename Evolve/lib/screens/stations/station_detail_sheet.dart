import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../design_system/components/ev_button.dart';
import '../../design_system/haptics/haptics.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radius.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../../models/charger_model.dart';
import '../../models/station_model.dart';
import '../../providers/battery_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/navigation_providers.dart';
import '../../providers/station_providers.dart';

class StationDetailSheetContent extends ConsumerWidget {
  const StationDetailSheetContent({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationAsync = ref.watch(allStationsProvider).whenData(
          (list) => list.where((s) => s.id == stationId).firstOrNull,
        );
    final chargersAsync = ref.watch(chargersForStationProvider(stationId));

    return stationAsync.when(
      loading: () => const _SheetLoadingState(),
      error: (e, _) => _SheetErrorState(message: e.toString()),
      data: (station) {
        if (station == null) {
          return const _SheetErrorState(message: 'Station not found');
        }
        return chargersAsync.when(
          loading: () => _SheetBody(station: station, chargers: null),
          error: (e, _) => _SheetBody(station: station, chargers: const []),
          data: (chargers) => _SheetBody(station: station, chargers: chargers),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Main body
// ---------------------------------------------------------------------------

class _SheetBody extends ConsumerWidget {
  const _SheetBody({required this.station, required this.chargers});

  final StationModel station;
  final List<ChargerModel>? chargers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available =
        chargers?.where((c) => c.status == ChargerStatus.available).length ?? 0;
    final total = chargers?.length ?? 0;

    // Pre-warm effective profile (resolves phone battery SoC before tap)
    final effectiveProfile = ref.watch(effectiveEvProfileProvider);

    // Favorite state
    final favorites = ref.watch(favoritesProvider).value ?? [];
    final isFav = favorites.contains(station.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Station name + heart + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(station.name, style: AppTypography.title3),
              ),
              // Heart favorite button
              CupertinoButton(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                minimumSize: Size.zero,
                onPressed: () {
                  AppHaptics.mediumImpact();
                  ref.read(toggleFavoriteProvider)(station.id);
                },
                child: Icon(
                  isFav
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                  color: isFav
                      ? const Color(0xFFFF3B30)
                      : const Color(0xFF8E8E93),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _StatusBadge(station.status),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          // Address
          Text(
            station.address,
            style:
                AppTypography.subhead.copyWith(color: AppColors.textSecondary),
          ),

          if (station.amenities.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _AmenitiesRow(station.amenities),
          ],

          const SizedBox(height: AppSpacing.lg),

          // Stats row: power · price · availability
          _StationStatsRow(
            available: available,
            total: total,
            chargers: chargers,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Connector chips from live charger data
          if (chargers != null) _ConnectorRow(chargers!),

          const SizedBox(height: AppSpacing.xxl),

          // Primary CTA
          EvButton.primary(
            'Scan QR to Start',
            onPressed: () {
              AppHaptics.mediumImpact();
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.go('/shell/scan');
            },
          ),

          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: EvButton.ghost(
                  'Navigate',
                  onPressed: () {
                    AppHaptics.selectionClick();

                    final origin =
                        ref.read(userLocationProvider).valueOrNull ??
                            const LatLng(14.5995, 120.9842);

                    fetchRouteOptions(
                      ref,
                      origin: origin,
                      destination: station.latLng,
                      evProfile: effectiveProfile,
                      destinationStationId: station.id,
                    );

                    ref.read(destinationStationIdProvider.notifier).state =
                        station.id;
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.push('/route-options');
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: EvButton.ghost(
                  'Report Issue',
                  onPressed: () {
                    AppHaptics.selectionClick();
                    _showReportSheet(context, station.id);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReportSheet(BuildContext context, String stationId) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetCtx) => CupertinoActionSheet(
        title: const Text('Report an Issue'),
        message: const Text('What\'s the problem?'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetCtx),
            child: const Text('Charger not working'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetCtx),
            child: const Text('Station unreachable / blocked'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetCtx),
            child: const Text('Incorrect information'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetCtx),
            child: const Text('Other'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(sheetCtx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final StationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      StationStatus.available => ('Available', AppColors.success),
      StationStatus.busy => ('Busy', AppColors.warning),
      StationStatus.offline => ('Offline', AppColors.textTertiary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTypography.caption1.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Combined stats row: ⚡ 22 kW · ₱12/kWh · 2/4 Available
class _StationStatsRow extends StatelessWidget {
  const _StationStatsRow({
    required this.available,
    required this.total,
    required this.chargers,
  });

  final int available;
  final int total;
  final List<ChargerModel>? chargers;

  @override
  Widget build(BuildContext context) {
    final color = available > 0 ? AppColors.success : AppColors.textTertiary;

    // Compute price and power from charger list
    double? minPrice;
    double? maxPower;
    if (chargers != null && chargers!.isNotEmpty) {
      minPrice = chargers!.map((c) => c.pricePerKwh).reduce(
            (a, b) => a < b ? a : b,
          );
      maxPower = chargers!.map((c) => c.powerKw).reduce(
            (a, b) => a > b ? a : b,
          );
    }

    return Row(
      children: [
        Icon(CupertinoIcons.bolt_fill, size: 15, color: color),
        const SizedBox(width: 4),
        if (maxPower != null) ...[
          Text(
            '${maxPower.toStringAsFixed(0)} kW',
            style: AppTypography.callout
                .copyWith(color: AppColors.textSecondary),
          ),
          _Dot(),
        ],
        if (minPrice != null) ...[
          Text(
            '₱${minPrice.toStringAsFixed(0)}/kWh',
            style: AppTypography.callout
                .copyWith(color: AppColors.textSecondary),
          ),
          _Dot(),
        ],
        Text(
          total > 0 ? '$available/$total Available' : 'Checking…',
          style: AppTypography.callout
              .copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          '·',
          style: AppTypography.callout
              .copyWith(color: AppColors.textTertiary),
        ),
      );
}

class _ConnectorRow extends StatelessWidget {
  const _ConnectorRow(this.chargers);
  final List<ChargerModel> chargers;

  @override
  Widget build(BuildContext context) {
    final types = chargers.map((c) => c.connectorType).toSet().toList();
    if (types.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: types.map((t) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border:
                Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Text(
            t.displayName,
            style: AppTypography.caption1.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AmenitiesRow extends StatelessWidget {
  const _AmenitiesRow(this.amenities);
  final List<String> amenities;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: amenities.take(4).map((a) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.checkmark_circle_fill,
                size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(a,
                style: AppTypography.caption2
                    .copyWith(color: AppColors.textSecondary)),
          ],
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading / Error states
// ---------------------------------------------------------------------------

class _SheetLoadingState extends StatelessWidget {
  const _SheetLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xxxl),
      child: Center(child: CupertinoActivityIndicator()),
    );
  }
}

class _SheetErrorState extends StatelessWidget {
  const _SheetErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.exclamationmark_circle,
              size: 40, color: AppColors.error),
          const SizedBox(height: AppSpacing.sm),
          Text('Unable to load station',
              style:
                  AppTypography.headline.copyWith(color: AppColors.label)),
          const SizedBox(height: AppSpacing.xs),
          Text(message,
              style: AppTypography.subhead
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
