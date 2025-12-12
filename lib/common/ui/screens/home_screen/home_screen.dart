import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map_training/common/ui/screens/home_screen/home_state.dart';
import 'package:flutter_map_training/features/account_feature/bloc/account_bloc.dart';
import 'package:flutter_map_training/features/stations_feature/screens/stations_screen.dart';

import '../../../../features/account_feature/repository/account_repository.dart';
import '../../../../features/account_feature/screens/account_screen.dart';
import '../../../../features/stations_feature/screens/favorites_screen.dart';
import '../../widgets/app_bottom_bar.dart';
import '../../widgets/app_floating_action_button.dart';
import 'home_bloc.dart';
import '../../../../features/stations_feature/services/pending_charging_intent_store.dart';
import '../../../../features/stations_feature/screens/charging_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => HomeBloc(),
        ),
        BlocProvider(
          create: (context) => AccountBloc(
            RepositoryProvider.of<AccountRepositoryImpl>(context),
          ),
        ),
      ],
      child: Builder(builder: (context) {
        return ValueListenableBuilder(
          valueListenable: PendingChargingIntentStore.instance.notifier,
          builder: (context, pending, _) {
            final hideNav = pending != null;
            return Scaffold(
              body: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  switch (state.currentScreen) {
                    case AppScreen.map:
                      return const StationsScreen();
                    case AppScreen.favorites:
                      return const FavoritesScreen();
                    case AppScreen.sessions:
                      return const ChargingHistoryScreen();
                    case AppScreen.account:
                      return const AccountScreen();
                  }
                },
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              floatingActionButton:
                  hideNav ? null : const AppFloatingActionButton(),
              bottomNavigationBar:
                  hideNav ? null : const ApplicationBottomBar(),
              extendBody: true,
            );
          },
        );
      }),
    );
  }
}
