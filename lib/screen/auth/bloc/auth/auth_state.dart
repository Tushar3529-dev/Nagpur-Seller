import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String message;
  const AuthSuccess({this.message = "Success"});
  @override
  List<Object?> get props => [message];
}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure(this.error);

  @override
  List<Object?> get props => [error];
}

/// Credentials were valid, but the seller has not approved this system user's
/// login yet. Retrying [AuthLoginRequested] is how approval is checked.
class AuthApprovalPending extends AuthState {
  final String message;
  final String email;
  final DateTime? requestedAt;

  /// When the server last answered "pending"; makes each retry a new state.
  final DateTime checkedAt;

  const AuthApprovalPending({
    required this.message,
    required this.email,
    required this.checkedAt,
    this.requestedAt,
  });

  @override
  List<Object?> get props => [message, email, requestedAt, checkedAt];
}

class AuthOTPSent extends AuthState {
  final String verificationId;
  final String phoneNumber;
  final String message;

  const AuthOTPSent({
    required this.verificationId,
    required this.phoneNumber,
    this.message = "OTP Sent Successfully",
  });

  @override
  List<Object?> get props => [verificationId, phoneNumber];
}

class AuthOTPVerified extends AuthState {
  final String message;

  const AuthOTPVerified({this.message = "OTP Verified Successfully"});

  @override
  List<Object?> get props => [message];
}
