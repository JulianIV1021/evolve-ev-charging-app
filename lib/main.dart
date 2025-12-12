import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map_training/common/routes.dart';
import 'package:flutter_map_training/common/theme.dart';
import 'package:flutter_map_training/common/utils/logger.dart';
import 'package:flutter_map_training/features/account_feature/services/signup_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'features/account_feature/repository/account_repository.dart';
import 'features/account_feature/screens/auth_gate.dart';
import 'features/stations_feature/bloc/sessions_bloc.dart';
import 'features/stations_feature/bloc/sessions_event.dart';
import 'features/stations_feature/bloc/stations_bloc.dart';
import 'features/stations_feature/bloc/stations_event.dart';
import 'features/stations_feature/repository/station_repository.dart';
import 'features/stations_feature/repository/session_repository.dart';
import 'features/stations_feature/services/location_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupLogger();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const RepositoryHolder(
    child: StationsApp(),
  ));
}

class RepositoryHolder extends StatelessWidget {
  final Widget child;

  const RepositoryHolder({
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => StationRepositoryImpl(
            locationService: LocationServiceImpl(),
          ),
        ),
        RepositoryProvider(
          create: (context) => AccountRepositoryImpl(
            SignInServiceImpl(FirebaseAuth.instance),
          ),
        ),
        RepositoryProvider(
          create: (context) => SessionRepositoryImpl(
            auth: FirebaseAuth.instance,
            firestore: FirebaseFirestore.instance,
          ),
        ),
      ],
      child: Builder(builder: (context) => child),
    );
  }
}

class StationsApp extends StatelessWidget {
  const StationsApp({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => StationsBloc(
            RepositoryProvider.of<StationRepositoryImpl>(context),
          )..add(FetchStationsEvent()),
        ),
        BlocProvider(
          create: (context) => SessionsBloc(
            RepositoryProvider.of<SessionRepositoryImpl>(context),
          )..add(LoadSessionsEvent()),
        ),
      ],
      child: MaterialApp(
        title: 'EVOLVE',
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
        routes: {
          chargingScreenRoute: (context) =>
              routes[chargingScreenRoute]!(context),
          searchScreenRoute: (context) => routes[searchScreenRoute]!(context),
        },
        theme: lightTheme,
      ),
    );
  }
}
