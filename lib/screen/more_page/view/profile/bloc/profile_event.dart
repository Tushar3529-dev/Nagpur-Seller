part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch profile data from API
class ProfileFetchEvent extends ProfileEvent {
  /// If true, forces a refresh even if data exists in state
  final bool forceRefresh;

  const ProfileFetchEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Update profile (name and/or image path)
class ProfileUpdateEvent extends ProfileEvent {
  final String name;
  final String? imagePath;

  const ProfileUpdateEvent({required this.name, this.imagePath});

  @override
  List<Object?> get props => [name, imagePath];
}

class ProfileChangePasswordEvent extends ProfileEvent {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const ProfileChangePasswordEvent({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword, confirmPassword];
}

class ProfileResetEvent extends ProfileEvent {
  const ProfileResetEvent();
}
