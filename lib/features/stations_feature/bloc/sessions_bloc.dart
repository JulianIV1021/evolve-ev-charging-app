import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/charging_session.dart';
import '../repository/session_repository.dart';
import 'sessions_event.dart';
import 'sessions_state.dart';

class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {
  final SessionRepository repository;

  SessionsBloc(this.repository) : super(const SessionsState()) {
    on<LoadSessionsEvent>(_onLoad);
    on<StartSessionEvent>(_onStart);
    on<EndSessionEvent>(_onEnd);
  }

  Future<void> _onLoad(
    LoadSessionsEvent event,
    Emitter<SessionsState> emit,
  ) async {
    emit(state.copyWith(status: SessionsStatus.loading));
    await emit.forEach<List<ChargingSession>>(
      repository.sessionsStream(),
      onData: (sessions) => state.copyWith(
        status: SessionsStatus.ready,
        sessions: sessions,
        error: null,
      ),
      onError: (error, _) => state.copyWith(
        status: SessionsStatus.error,
        error: error.toString(),
      ),
    );
  }

  Future<void> _onStart(
    StartSessionEvent event,
    Emitter<SessionsState> emit,
  ) async {
    try {
      await repository.startSession(event.station);
    } catch (e) {
      emit(state.copyWith(status: SessionsStatus.error, error: e.toString()));
    }
  }

  Future<void> _onEnd(
    EndSessionEvent event,
    Emitter<SessionsState> emit,
  ) async {
    try {
      await repository.endSession(event.sessionId);
    } catch (e) {
      emit(state.copyWith(status: SessionsStatus.error, error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
