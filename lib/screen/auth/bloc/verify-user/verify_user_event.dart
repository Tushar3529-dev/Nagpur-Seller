part of 'verify_user_bloc.dart';

@immutable
sealed class VerifyUserEvent {}

final class VerifyUserEmail extends VerifyUserEvent {
  final String type;
  final String value;

  VerifyUserEmail(this.type, this.value);
}

final class VerifyUserPhone extends VerifyUserEvent {
  final String type;
  final String value;

  VerifyUserPhone(this.type, this.value);
}
