import 'package:equatable/equatable.dart';
import '../models/charging_session.dart';

enum SessionsStatus { loading, ready, error }

class SessionsState extends Equatable {
  final SessionsStatus status;
  final List<ChargingSession> sessions;
  final String? error;

  const SessionsState({
    this.status = SessionsStatus.loading,
    this.sessions = const [],
    this.error,
  });

  SessionsState copyWith({
    SessionsStatus? status,
    List<ChargingSession>? sessions,
    String? error,
  }) {
    return SessionsState(
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, sessions, error];

  ChargingSession? get activeSession {
    try {
      return sessions.firstWhere((s) => s.status == 'active');
    } catch (_) {
      return null;
    }
  }
}
