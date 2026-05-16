part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileUpdating extends ProfileState {
  final UserProfile? currentProfile;

  const ProfileUpdating({this.currentProfile});

  @override
  List<Object?> get props => [currentProfile];
}

class ProfileUpdateSuccess extends ProfileState {
  final UserProfile updatedProfile;
  final String message;

  const ProfileUpdateSuccess(this.updatedProfile, this.message);

  @override
  List<Object> get props => [updatedProfile, message];
}

class ProfilePasswordUpdating extends ProfileState {}

class ProfilePasswordUpdateSuccess extends ProfileState {
  final String message;

  const ProfilePasswordUpdateSuccess(this.message);

  @override
  List<Object> get props => [message];
}
