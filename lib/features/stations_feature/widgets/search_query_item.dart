import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map_training/features/stations_feature/bloc/bloc.dart';

import '../models/ocm_station.dart';

class SearchQueryItem extends StatelessWidget {
  final OcmStation station;

  const SearchQueryItem(this.station, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  station.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  station.address.isNotEmpty
                      ? station.address
                      : station.coordinatesLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.only(left: 8),
            onPressed: () {
              context.read<StationsBloc>().add(AddToRecentSearchesEvent(station));
              Navigator.of(context).pop(station);
            },
            icon: const Icon(Icons.directions_rounded),
          ),
        ],
      ),
    );
  }
}
