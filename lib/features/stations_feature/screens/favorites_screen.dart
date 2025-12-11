import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/ocm_station.dart';
import '../services/station_focus_bus.dart';
import '../services/ocm_favorites_store.dart';
import 'package:flutter_map_training/common/ui/screens/home_screen/home_bloc.dart';
import 'package:flutter_map_training/common/ui/screens/home_screen/home_event.dart';
import 'package:flutter_map_training/common/ui/screens/home_screen/home_state.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ValueListenableBuilder<Map<int, OcmStation>>(
          valueListenable: OcmFavoritesStore.instance.favorites,
          builder: (context, favs, _) {
            final items = favs.values.toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Favorites',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const Text('No favorites yet')
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final station = items[index];
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          title: Text(
                            station.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            station.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.star, color: Colors.amber),
                            onPressed: () =>
                                OcmFavoritesStore.instance.toggle(station),
                          ),
                          onTap: () {
                            // Switch to map tab and ask it to focus/open the sheet.
                            context
                                .read<HomeBloc>()
                                .add(SwitchTabEvent(AppScreen.map));
                            StationFocusBus.instance.focus(station);
                          },
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
