import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/components/ev_button.dart';
import '../../design_system/components/ev_text_field.dart';
import '../../design_system/haptics/haptics.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/radius.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';
import '../../models/charger_model.dart';
import '../../models/ev_profile_model.dart';
import '../../utils/app_logger.dart';

class VehicleProfileScreen extends ConsumerStatefulWidget {
  const VehicleProfileScreen({super.key});

  @override
  ConsumerState<VehicleProfileScreen> createState() =>
      _VehicleProfileScreenState();
}

class _VehicleProfileScreenState
    extends ConsumerState<VehicleProfileScreen> {
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _capacityController = TextEditingController();
  final _maxPowerController = TextEditingController();

  List<ConnectorType> _connectorTypes = [];
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _capacityController.dispose();
    _maxPowerController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loaded = true);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data()?['evProfile'] as Map<String, dynamic>?;

      if (data != null && mounted) {
        final profile = EVProfile.fromMap(data);
        setState(() {
          _makeController.text = profile.vehicleMake;
          _modelController.text = profile.vehicleModel;
          _capacityController.text =
              profile.batteryCapacityKwh.toStringAsFixed(0);
          _maxPowerController.text =
              profile.maxChargingPowerKw.toStringAsFixed(0);
          _connectorTypes = [...profile.connectors];
          _loaded = true;
        });
      } else if (mounted) {
        setState(() => _loaded = true);
      }
    } catch (e) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _save() async {
    final make = _makeController.text.trim();
    final model = _modelController.text.trim();
    final capacityStr = _capacityController.text.trim();
    final maxPowerStr = _maxPowerController.text.trim();

    if (make.isEmpty || model.isEmpty || capacityStr.isEmpty || maxPowerStr.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    final capacity = double.tryParse(capacityStr);
    if (capacity == null || capacity <= 0) {
      _showError('Enter a valid battery capacity.');
      return;
    }

    final maxPower = double.tryParse(maxPowerStr);
    if (maxPower == null || maxPower <= 0) {
      _showError('Enter a valid max charging power.');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    AppHaptics.mediumImpact();

    try {
      final profile = EVProfile(
        vehicleMake: make,
        vehicleModel: model,
        batteryCapacityKwh: capacity,
        maxChargingPowerKw: maxPower,
        connectors: _connectorTypes,
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'evProfile': profile.toMap(),
      });

      AppLogger.instance.info('ev_profile_saved', {'make': make, 'model': model});
      if (mounted) {
        AppHaptics.notificationSuccess();
        if (context.canPop()) context.pop();
      }
    } catch (e) {
      AppLogger.instance.error('ev_profile_save_failed', {'error': e.toString()});
      if (mounted) _showError('Failed to save. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleConnector(ConnectorType type) {
    AppHaptics.selectionClick();
    setState(() {
      if (_connectorTypes.contains(type)) {
        _connectorTypes = _connectorTypes.where((c) => c != type).toList();
      } else {
        _connectorTypes = [..._connectorTypes, type];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('My Vehicle'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: SafeArea(
        child: !_loaded
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // Icon header
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.car_detailed,
                          size: 36, color: AppColors.accent),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Make
                  _FieldLabel('Make'),
                  EvTextField(
                    controller: _makeController,
                    placeholder: 'e.g. Tesla',
                    autocorrect: false,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Model
                  _FieldLabel('Model'),
                  EvTextField(
                    controller: _modelController,
                    placeholder: 'e.g. Model 3 Long Range',
                    autocorrect: false,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Battery capacity
                  _FieldLabel('Battery Capacity (kWh)'),
                  EvTextField(
                    controller: _capacityController,
                    placeholder: 'e.g. 75',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Max charging power
                  _FieldLabel('Max Charging Power (kW)'),
                  EvTextField(
                    controller: _maxPowerController,
                    placeholder: 'e.g. 150',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Connector types
                  _FieldLabel('Compatible Connectors'),
                  const SizedBox(height: AppSpacing.sm),
                  _ConnectorSelector(
                    selected: _connectorTypes,
                    onToggle: _toggleConnector,
                  ),

                  const SizedBox(height: AppSpacing.xxxl),

                  _saving
                      ? const Center(child: CupertinoActivityIndicator())
                      : EvButton.primary('Save Vehicle', onPressed: _save),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text(label.toUpperCase(),
            style: AppTypography.caption1.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
      );
}

class _ConnectorSelector extends StatelessWidget {
  const _ConnectorSelector({
    required this.selected,
    required this.onToggle,
  });
  final List<ConnectorType> selected;
  final ValueChanged<ConnectorType> onToggle;

  @override
  Widget build(BuildContext context) {
    final all = [
      ConnectorType.type2,
      ConnectorType.chademo,
      ConnectorType.ccs2,
      ConnectorType.j1772,
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: all.map((c) {
        final isOn = selected.contains(c);
        return GestureDetector(
          onTap: () => onToggle(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isOn
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isOn ? AppColors.accent : AppColors.separator,
                width: isOn ? 1.5 : 1,
              ),
            ),
            child: Text(
              c.displayName,
              style: AppTypography.callout.copyWith(
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
