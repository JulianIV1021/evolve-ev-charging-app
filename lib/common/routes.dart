
import 'package:flutter/cupertino.dart';
import '../features/stations_feature/screens/charging_screen.dart';
import '../features/stations_feature/screens/search_screen.dart';

const String chargingScreenRoute = '/charging_screen_route';
const String searchScreenRoute = '/search_screen_route';

Map<String, WidgetBuilder> routes = {
  chargingScreenRoute: (context) => const ChargingScreen(
        stationId: 'demo',
        stationName: 'Demo Station',
        coordinates: '0, 0',
        connectorLabel: 'Type 2 AC',
      ),
  searchScreenRoute: (context) => const SearchScreen(),
};
