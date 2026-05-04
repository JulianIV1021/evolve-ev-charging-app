import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/components/ev_button.dart';
import '../../design_system/haptics/haptics.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../../models/charger_model.dart';
import '../../models/filter_model.dart';
import '../../models/station_model.dart';
import '../../providers/station_providers.dart';
import '../../utils/app_logger.dart';

class FilterSheetContent extends ConsumerStatefulWidget {
  const FilterSheetContent({super.key});

  @override
  ConsumerState<FilterSheetContent> createState() =>
      _FilterSheetContentState();
}

class _FilterSheetContentState extends ConsumerState<FilterSheetContent> {
  late StationFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(stationFilterProvider);
  }

  void _apply() {
    AppHaptics.selectionClick();
    ref.read(stationFilterProvider.notifier).state = _draft;
    AppLogger.instance.info('filter_applied');
    Navigator.of(context).pop();
  }

  void _reset() {
    AppHaptics.selectionClick();
    setState(() => _draft = StationFilter.empty);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Charger type
          _SectionHeader('Charger Type'),
          CupertinoSlidingSegmentedControl<String>(
            groupValue: _draft.acOnly
                ? 'ac'
                : _draft.dcOnly
                    ? 'dc'
                    : 'all',
            onValueChanged: (v) {
              setState(() {
                _draft = _draft.copyWith(
                  acOnly: v == 'ac',
                  dcOnly: v == 'dc',
                );
              });
            },
            children: const {
              'all': Text('All'),
              'ac': Text('AC'),
              'dc': Text('DC'),
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // Availability
          _SectionHeader('Availability'),
          _AvailabilityToggles(
            selected: _draft.availabilityFilter,
            onChanged: (list) =>
                setState(() => _draft = _draft.copyWith(availabilityFilter: list)),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Connector types
          _SectionHeader('Connector Type'),
          _ConnectorChips(
            selected: _draft.connectorTypes,
            onChanged: (list) =>
                setState(() => _draft = _draft.copyWith(connectorTypes: list)),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Max price
          _SectionHeader(
              'Max Price  ₱${_draft.maxPricePerKwh?.toStringAsFixed(0) ?? 'Any'}/kWh'),
          CupertinoSlider(
            value: _draft.maxPricePerKwh ?? 50,
            min: 0,
            max: 100,
            activeColor: AppColors.accent,
            onChanged: (v) => setState(
              () => _draft = _draft.copyWith(maxPricePerKwh: v < 1 ? null : v),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Compatible only
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Compatible with my EV', style: AppTypography.callout),
              CupertinoSwitch(
                value: _draft.compatibleOnly,
                activeTrackColor: AppColors.accent,
                onChanged: (v) =>
                    setState(() => _draft = _draft.copyWith(compatibleOnly: v)),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          Row(
            children: [
              Expanded(
                child: EvButton.ghost(
                  'Reset',
                  onPressed: _reset,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: EvButton.primary('Apply Filters', onPressed: _apply),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(title, style: AppTypography.subhead),
      );
}

class _AvailabilityToggles extends StatelessWidget {
  const _AvailabilityToggles({required this.selected, required this.onChanged});
  final List<StationStatus> selected;
  final ValueChanged<List<StationStatus>> onChanged;

  @override
  Widget build(BuildContext context) {
    final statuses = [
      (StationStatus.available, 'Available', AppColors.success),
      (StationStatus.busy, 'Busy', AppColors.warning),
      (StationStatus.offline, 'Offline', AppColors.textTertiary),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      children: statuses.map((t) {
        final (status, label, color) = t;
        final isOn = selected.contains(status);
        return GestureDetector(
          onTap: () {
            AppHaptics.selectionClick();
            final next = isOn
                ? selected.where((s) => s != status).toList()
                : [...selected, status];
            onChanged(next);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isOn ? color.withValues(alpha: 0.15) : AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOn ? color : AppColors.separator,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.subhead.copyWith(
                color: isOn ? color : AppColors.textSecondary,
                fontWeight: isOn ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ConnectorChips extends StatelessWidget {
  const _ConnectorChips({required this.selected, required this.onChanged});
  final List<ConnectorType> selected;
  final ValueChanged<List<ConnectorType>> onChanged;

  @override
  Widget build(BuildContext context) {
    final connectors = [
      ConnectorType.type2,
      ConnectorType.chademo,
      ConnectorType.ccs2,
      ConnectorType.j1772,
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      children: connectors.map((c) {
        final isOn = selected.contains(c);
        return GestureDetector(
          onTap: () {
            AppHaptics.selectionClick();
            final next = isOn
                ? selected.where((s) => s != c).toList()
                : [...selected, c];
            onChanged(next);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isOn
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOn ? AppColors.accent : AppColors.separator,
              ),
            ),
            child: Text(
              c.displayName,
              style: AppTypography.subhead.copyWith(
                color: isOn ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isOn ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
