import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map_training/common/ui/widgets/bottom_bar_item.dart';
import 'package:flutter_map_training/features/wallet_feature/bloc/bloc.dart';

import '../screens/home_screen/home_bloc.dart';
import '../screens/home_screen/home_event.dart';
import '../screens/home_screen/home_state.dart';

class ApplicationBottomBar extends StatelessWidget {
  const ApplicationBottomBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final homeBloc = BlocProvider.of<HomeBloc>(context, listen: true);
    final walletBloc = BlocProvider.of<WalletBloc>(context, listen: true);

    return BottomAppBar(
      elevation: 12,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        // bar goes exactly to the bottom – no SafeArea, no extra padding
        height: kBottomNavigationBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              BottomBarItem(
                icon: Icons.map,
                label: 'MAP',
                isSelected: homeBloc.state.currentScreen == AppScreen.map,
                onPressed: () {
                  homeBloc.add(SwitchTabEvent(AppScreen.map));
                },
              ),
              BottomBarItem(
                icon: Icons.star,
                label: 'FAVORITES',
                isSelected:
                    homeBloc.state.currentScreen == AppScreen.favorites,
                onPressed: () {
                  homeBloc.add(SwitchTabEvent(AppScreen.favorites));
                },
              ),
              const SizedBox(width: 42), // FAB notch spacer
              BottomBarItem(
                icon: Icons.wallet,
                label: walletBloc.state.status == WalletStatus.loaded
                    ? '\$${walletBloc.state.wallet?.balance ?? 0}'
                    : '...',
                isSelected:
                    homeBloc.state.currentScreen == AppScreen.wallet,
                onPressed: () {
                  homeBloc.add(SwitchTabEvent(AppScreen.wallet));
                },
              ),
              BottomBarItem(
                icon: Icons.account_circle_rounded,
                label: 'ACCOUNT',
                isSelected:
                    homeBloc.state.currentScreen == AppScreen.account,
                onPressed: () {
                  homeBloc.add(SwitchTabEvent(AppScreen.account));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
