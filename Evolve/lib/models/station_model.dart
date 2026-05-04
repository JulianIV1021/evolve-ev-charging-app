import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'charger_model.dart';

enum StationStatus { available, busy, offline }

extension StationStatusX on StationStatus {
  String get displayName => switch (this) {
        StationStatus.available => 'Available',
        StationStatus.busy => 'Busy',
        StationStatus.offline => 'Offline',
      };
}

class StationModel extends Equatable {
  const StationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.status,
    this.chargers = const [],
    this.amenities = const [],
    this.imageUrl = '',
    this.distanceKm = 0.0,
  });

  final String id;
  final String name;
  final String address;
  final GeoPoint location;
  final StationStatus status;
  final List<ChargerModel> chargers;
  final List<String> amenities;
  final String imageUrl;
  final double distanceKm;

  LatLng get latLng => LatLng(location.latitude, location.longitude);

  int get availableCount =>
      chargers.where((c) => c.isAvailable).length;

  factory StationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return StationModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      address: d['address'] as String? ?? '',
      location: d['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      status: _parseStatus(d['status']),
      amenities: List<String>.from(d['amenities'] ?? []),
      imageUrl: d['imageUrl'] as String? ?? '',
    );
  }

  static StationStatus _parseStatus(dynamic v) {
    if (v == null) return StationStatus.offline;
    final s = v.toString().toLowerCase().trim();
    return switch (s) {
      'available' || 'active' || 'online' || 'open' || 'enabled' || 'ready' =>
        StationStatus.available,
      'busy' || 'occupied' || 'charging' || 'in_use' || 'inuse' || 'in use' =>
        StationStatus.busy,
      _ => StationStatus.offline,
    };
  }

  StationModel copyWith({
    List<ChargerModel>? chargers,
    double? distanceKm,
    StationStatus? status,
  }) {
    return StationModel(
      id: id,
      name: name,
      address: address,
      location: location,
      status: status ?? this.status,
      chargers: chargers ?? this.chargers,
      amenities: amenities,
      imageUrl: imageUrl,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  @override
  List<Object?> get props => [id, status, distanceKm, chargers.length];
}
