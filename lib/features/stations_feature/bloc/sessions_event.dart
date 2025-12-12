import '../models/ocm_station.dart';

abstract class SessionsEvent {}

class LoadSessionsEvent extends SessionsEvent {}

class StartSessionEvent extends SessionsEvent {
  final OcmStation station;
  StartSessionEvent(this.station);
}

class EndSessionEvent extends SessionsEvent {
  final String sessionId;
  EndSessionEvent(this.sessionId);
}
