part of 'verify_user_bloc.dart';

@immutable
sealed class VerifyUserState {}

final class VerifyUserInitial extends VerifyUserState {}

final class VerifyUserLoading extends VerifyUserState {
  final String type; // 'email' or 'phone'
  VerifyUserLoading(this.type);
}

final class VerifyUserValid extends VerifyUserState {
  final String type;
  final String value;
  VerifyUserValid(this.type, this.value);
}

final class VerifyUserAlreadyExists extends VerifyUserState {
  final String type;
  final String value;
  final String message; // e.g. "Email already exists"
  VerifyUserAlreadyExists(this.type, this.value, this.message);
}

final class VerifyUserError extends VerifyUserState {
  final String type;
  final String message;
  VerifyUserError(this.type, this.message);
}