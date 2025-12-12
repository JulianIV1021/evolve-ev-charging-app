abstract class AccountEvent {}

class SignInWithGoogleEvent extends AccountEvent {}

class SignInWithEmailPasswordEvent extends AccountEvent {
  final String email;
  final String password;

  SignInWithEmailPasswordEvent({required this.email, required this.password});
}

class SignUpWithEmailPasswordEvent extends AccountEvent {
  final String email;
  final String password;

  SignUpWithEmailPasswordEvent({required this.email, required this.password});
}

class SendPasswordResetEvent extends AccountEvent {
  final String email;

  SendPasswordResetEvent({required this.email});
}

class SignOutEvent extends AccountEvent {}

class ClearErrorEvent extends AccountEvent {}
