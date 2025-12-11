import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map_training/features/stations_feature/bloc/bloc.dart';
import 'package:flutter_map_training/features/stations_feature/widgets/search_bar.dart';
import 'package:flutter_map_training/features/stations_feature/widgets/search_query_item.dart';
import '../models/ocm_station.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stationBloc = context.watch<StationsBloc>();
    final query = stationBloc.state.searchQuery.trim();
    final recent = stationBloc.state.recentSearches;
    final results = query.isEmpty
        ? <OcmStation>[]
        : stationBloc.state.stations
            .where((element) =>
                element.name.toLowerCase().contains(query.toLowerCase()) ||
                element.address.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const Hero(
                  tag: 'SearchBar',
                  child: Material(
                    child: SearchBarWidget(
                      autofocus: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      if (recent.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Recent searches',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context
                                    .read<StationsBloc>()
                                    .add(ClearRecentSearchesEvent()),
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...recent.map((s) => SearchQueryItem(s)).toList(),
                        const SizedBox(height: 16),
                      ],
                      if (query.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            recent.isEmpty
                                ? 'Type something to search'
                                : 'Start typing to search stations',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Results',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (results.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('No results'),
                          )
                        else
                          ...results.map((s) => SearchQueryItem(s)).toList(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
