import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:go_router/go_router.dart';

import '../../design_system/haptics/haptics.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../../models/station_model.dart';
import '../../providers/station_providers.dart';

const _kRecentKey = 'recent_station_ids';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  List<String> _recentIds = [];

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _recentIds = prefs.getStringList(_kRecentKey) ?? [];
    });
  }

  Future<void> _saveRecent(String stationId) async {
    final ids = List<String>.from(_recentIds);
    ids.remove(stationId);
    ids.insert(0, stationId);
    if (ids.length > 5) ids.removeLast();
    setState(() => _recentIds = ids);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kRecentKey, ids);
  }

  void _openStation(StationModel station) {
    AppHaptics.lightImpact();
    _saveRecent(station.id);
    // Dismiss keyboard first so it doesn't consume the navigation frame.
    FocusScope.of(context).unfocus();
    // Switch to Stations tab.
    context.go('/shell/stations');
    // Wait long enough for the tab switch + map render to settle before
    // signalling the map screen to pan and open the detail sheet.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      ref.read(selectedStationIdProvider.notifier).state = station.id;
    });
  }

  List<StationModel> _filter(List<StationModel> stations) {
    if (_query.isEmpty) return stations;
    final q = _query.toLowerCase();
    return stations
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.address.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final allStations =
        ref.watch(allStationsProvider).valueOrNull ?? [];
    final results = _filter(allStations);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // ── Search bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: CupertinoSearchTextField(
                controller: _controller,
                placeholder: 'Search stations, addresses…',
                onChanged: (v) => setState(() => _query = v),
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
            ),

            // ── Results ───────────────────────────────────────────────
            Expanded(
              child: _query.isEmpty
                  ? _IdleBody(
                      recentIds: _recentIds,
                      allStations: allStations,
                      onTap: _openStation,
                    )
                  : results.isEmpty
                      ? _EmptyResults(query: _query)
                      : _ResultsList(
                          stations: results,
                          onTap: _openStation,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Idle state: recent searches + all stations
// ---------------------------------------------------------------------------

class _IdleBody extends StatelessWidget {
  const _IdleBody({
    required this.recentIds,
    required this.allStations,
    required this.onTap,
  });

  final List<String> recentIds;
  final List<StationModel> allStations;
  final ValueChanged<StationModel> onTap;

  @override
  Widget build(BuildContext context) {
    if (recentIds.isEmpty && allStations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.search,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Search for a charging station near you',
                style: AppTypography.subhead
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final recents = recentIds
        .map((id) => allStations.where((s) => s.id == id).firstOrNull)
        .whereType<StationModel>()
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        if (recents.isNotEmpty) ...[
          _SectionHeader('Recent'),
          ...recents.map((s) => _StationRow(station: s, onTap: onTap)),
          const SizedBox(height: AppSpacing.lg),
        ],
        _SectionHeader('All Stations'),
        ...allStations.map((s) => _StationRow(station: s, onTap: onTap)),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Results list
// ---------------------------------------------------------------------------

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.stations, required this.onTap});

  final List<StationModel> stations;
  final ValueChanged<StationModel> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      itemCount: stations.length,
      itemBuilder: (_, i) =>
          _StationRow(station: stations[i], onTap: onTap),
    );
  }
}

// ---------------------------------------------------------------------------
// Single station result row
// ---------------------------------------------------------------------------

class _StationRow extends StatelessWidget {
  const _StationRow({required this.station, required this.onTap});

  final StationModel station;
  final ValueChanged<StationModel> onTap;

  @override
  Widget build(BuildContext context) {
    final (dotColor, statusLabel) = switch (station.status) {
      StationStatus.available => (AppColors.success, 'Available'),
      StationStatus.busy => (AppColors.warning, 'Busy'),
      StationStatus.offline => (AppColors.textTertiary, 'Offline'),
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
        onTap(station);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            // Availability dot
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            // Name + address
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    style: AppTypography.callout
                        .copyWith(
                            color: AppColors.label,
                            fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    station.address,
                    style: AppTypography.footnote
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Distance badge (if available)
            if (station.distanceKm > 0)
              Text(
                '${station.distanceKm.toStringAsFixed(1)} km',
                style: AppTypography.caption1
                    .copyWith(color: AppColors.textTertiary),
              )
            else
              Text(
                statusLabel,
                style: AppTypography.caption1.copyWith(
                    color: dotColor, fontWeight: FontWeight.w500),
              ),
            const Icon(CupertinoIcons.chevron_right,
                size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
            top: AppSpacing.md, bottom: AppSpacing.sm),
        child: Text(
          title.toUpperCase(),
          style: AppTypography.caption1.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.search,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No stations found for "$query"',
                style: AppTypography.subhead
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
