import 'package:equatable/equatable.dart';

enum AccountStatus { initial, loading, authenticated, unauthenticated, error }

class AccountState extends Equatable {
  final AccountStatus status;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AccountState({
    this.status = AccountStatus.initial,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  AccountState copyWith({
    AccountStatus? status,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AccountState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [status, isLoading, errorMessage, successMessage];
}
