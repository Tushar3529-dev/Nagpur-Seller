import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/more_page/view/profile/model/profile_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/profile/repo/profile_repo.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepo _profileRepo;
  UserProfile? _cachedProfile;

  ProfileBloc({ProfileRepo? profileRepo})
    : _profileRepo = profileRepo ?? ProfileRepo(),
      super(ProfileInitial()) {
    on<ProfileFetchEvent>(_onFetchProfile);
    on<ProfileUpdateEvent>(_onUpdateProfile);
    on<ProfileChangePasswordEvent>(_onChangePassword);
    on<ProfileResetEvent>(_onResetProfile);
  }

  UserProfile? get cachedProfile => _cachedProfile;

  Future<void> _onChangePassword(
    ProfileChangePasswordEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfilePasswordUpdating());
    try {
      final response = await _profileRepo.changePassword(
        event.currentPassword,
        event.newPassword,
        event.confirmPassword,
      );
      emit(
        ProfilePasswordUpdateSuccess(
          response['message'] ?? 'Password updated successfully',
        ),
      );
    } catch (e) {
      emit(ProfileError(e.toString().replaceAll('Exception:', '').trim()));
    }
  }

  Future<void> _onFetchProfile(
    ProfileFetchEvent event,
    Emitter<ProfileState> emit,
  ) async {
    // Skip fetch if data already exists in state (avoid redundant calls)
    if (_cachedProfile != null &&
        state is ProfileLoaded &&
        !event.forceRefresh) {
      return;
    }

    emit(ProfileLoading());
    try {
      final response = await _profileRepo.getUserProfile();
      final profile = UserProfile.fromJson(response);
      _cachedProfile = profile;

      // Store user data in HiveStorage for UserHelper access
      await _storeUserData(response, profile);

      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString().replaceAll('Exception:', '').trim()));
    }
  }

  Future<void> _onUpdateProfile(
    ProfileUpdateEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileUpdating(currentProfile: _cachedProfile));
    try {
      final response = await _profileRepo.updateProfile(
        userName: event.name,
        profileImagePath: event.imagePath,
      );
      final profile = UserProfile.fromJson(response);
      _cachedProfile = profile;

      // Update stored user data
      await _storeUserData(response, profile);

      emit(ProfileUpdateSuccess(profile, 'Profile updated successfully'));
    } catch (e) {
      emit(ProfileError(e.toString().replaceAll('Exception:', '').trim()));
    }
  }

  /// Static method to fetch profile and store in UserHelper (used by Splash/Login)
  static Future<void> fetchAndStoreProfile() async {
    try {
      final repo = ProfileRepo();
      final response = await repo.getUserProfile();
      final profile = UserProfile.fromJson(response);

      await _storeUserData(response, profile);
    } catch (e) {
      // Silently fail - profile data will be fetched when user opens profile page
      // ignore: avoid_print
      print('Failed to fetch profile on app start: $e');
    }
  }

  void _onResetProfile(ProfileResetEvent event, Emitter<ProfileState> emit) {
    _cachedProfile = null;
    emit(ProfileInitial());
  }

  /// Saves the user for UserHelper/PermissionChecker. Merges over the stored
  /// user and the raw `data` map rather than using [Data.toJson] alone, so
  /// fields the model doesn't parse, such as `role`/`roles` from login, aren't
  /// dropped on every profile refresh. Logout clears the stored user.
  static Future<void> _storeUserData(
    dynamic response,
    UserProfile profile,
  ) async {
    if (profile.data == null) return;
    final rawData = response is Map ? response['data'] : null;
    final Map<dynamic, dynamic> userDataToSave = {
      ...?HiveStorage.userData,
      if (rawData is Map) ...rawData,
      ...profile.data!.toJson(),
    };
    if (profile.assignedPermissions != null) {
      userDataToSave['assigned_permissions'] = profile.assignedPermissions;
    }
    await HiveStorage.setUserData(userDataToSave);
  }
}
