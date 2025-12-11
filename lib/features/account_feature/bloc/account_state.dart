import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountState extends Equatable {
  final UserCredential? userCredential;
  final bool isLoading;
  final String? errorMessage;

  const AccountState({
    this.userCredential,
    this.isLoading = false,
    this.errorMessage,
  });

  AccountState copyWith({
    UserCredential? userCredential,
    bool isSignedOut = false,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AccountState(
      userCredential: isSignedOut ? null : userCredential ?? this.userCredential,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        userCredential,
        isLoading,
        errorMessage,
      ];
}
