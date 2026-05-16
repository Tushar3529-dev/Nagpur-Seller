import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/constant.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/profile/bloc/profile_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/profile/model/profile_model.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/image_picker_utils.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  XFile? _selectedImage;
  String? _currentProfileImageUrl;
  bool _isPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProfileBloc>().state;
    if (state is ProfileLoaded) {
      _populateFields(state.profile);
    } else if (state is ProfileUpdateSuccess) {
      // ← important fallback
      _populateFields(state.updatedProfile);
    }
  }

  void _populateFields(UserProfile profile) {
    final data = profile.data;
    if (data != null) {
      _nameController.text = data.name ?? '';
      _emailController.text = data.email ?? '';
      _mobileController.text = data.mobile ?? '';
      _currentProfileImageUrl = data.profileImage;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final String? compressedPath = await ImagePickerUtils.pickMedia(
      context,
      mediaType: MediaType.image,
      maxSizeMb: 2.0,
    );

    if (compressedPath != null) {
      setState(() {
        _selectedImage = XFile(compressedPath);
      });
    }
  }

  void _onUpdate() async {
    if (!DemoGuard.shouldProceed(context)) return;

    if (_nameController.text.trim().isEmpty) {
      showCustomSnackbar(
        context: context,
        message:
            AppLocalizations.of(context)?.nameRequired ?? "Name is required",
        isError: true,
      );
      return;
    }

    context.read<ProfileBloc>().add(
      ProfileUpdateEvent(
        name: _nameController.text.trim(),
        imagePath: _selectedImage?.path,
      ),
    );
  }

  void _onChangePassword() async {
    if (!DemoGuard.shouldProceed(context)) return;

    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      showCustomSnackbar(
        context: context,
        message:
            AppLocalizations.of(context)?.fillAllPasswordFields ??
            "Please fill all password fields",
        isError: true,
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      showCustomSnackbar(
        context: context,
        message:
            AppLocalizations.of(context)?.passwordsDoNotMatch ??
            "Passwords do not match",
        isError: true,
      );
      return;
    }

    context.read<ProfileBloc>().add(
      ProfileChangePasswordEvent(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenType = context.screenType;

    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          final data = state.profile.data;
          if (data != null) {
            _nameController.text = data.name ?? '';
            _emailController.text = data.email ?? '';
            _mobileController.text = data.mobile ?? '';
            _currentProfileImageUrl = data.profileImage;
          }
        } else if (state is ProfileUpdateSuccess) {
          showCustomSnackbar(context: context, message: state.message);
          final data = state.updatedProfile.data;
          if (data != null) {
            _nameController.text = data.name ?? '';
            _currentProfileImageUrl = data.profileImage;
            _selectedImage = null;
          }
        } else if (state is ProfilePasswordUpdateSuccess) {
          showCustomSnackbar(context: context, message: state.message);
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        } else if (state is ProfileError) {
          showCustomSnackbar(
            context: context,
            message: state.message,
            isError: true,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ProfileLoading;
        final isUpdating = state is ProfileUpdating;
        final isChangingPassword = state is ProfilePasswordUpdating;

        return CustomScaffold(
          title: l10n?.profileEdit ?? "Profile Edit",
          centerTitle: true,
          showAppbar: true,
          body: isLoading
              ? const Center(child: CustomLoadingIndicator())
              : _buildBody(
                  context,
                  l10n,
                  isDark,
                  screenType,
                  isUpdating,
                  isChangingPassword,
                ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations? l10n,
    bool isDark,
    ScreenType screenType,
    bool isUpdating,
    bool isChangingPassword,
  ) {
    return SingleChildScrollView(
      padding: UIUtils.pagePadding(screenType),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: UIUtils.gapMD(screenType)),

            // Profile Image
            Center(child: _buildProfileImage(screenType)),
            SizedBox(height: UIUtils.gapXL(screenType)),

            // ─── Card 1: Profile Info ───
            _buildCardContainer(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Field
                  CustomTextField(
                    label: l10n?.name ?? "Name",
                    isRequired: true,
                    controller: _nameController,
                    hint: l10n?.enterName ?? "Enter your name",
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n?.nameRequired ?? "Name is required";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: UIUtils.gapMD(screenType)),

                  // Email Field (Read-only)
                  CustomTextField(
                    label: l10n?.email ?? "Email",
                    controller: _emailController,
                    hint: l10n?.emailAddress ?? "Email Address",
                    enabled: false,
                    readOnly: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n?.emailCannotBeChanged ?? "Email cannot be changed",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontFamily: AppConstants.fontFamily,
                    ),
                  ),
                  SizedBox(height: UIUtils.gapMD(screenType)),

                  // Mobile Field (Read-only)
                  CustomTextField(
                    label: l10n?.mobileNumber ?? "Mobile Number",
                    controller: _mobileController,
                    hint: l10n?.mobileNumber ?? "Mobile Number",
                    enabled: false,
                    readOnly: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n?.mobileCannotBeChanged ?? "Mobile cannot be changed",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontFamily: AppConstants.fontFamily,
                    ),
                  ),

                  // Update Button
                  SizedBox(height: UIUtils.gapXL(screenType)),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: isUpdating
                          ? l10n?.updating ?? "Updating..."
                          : l10n?.update ?? "Update",
                      onPressed: isUpdating || isChangingPassword
                          ? () {}
                          : _onUpdate,
                      backgroundColor: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: UIUtils.gapXL(screenType)),

            // ─── Card 2: Update Password ───
            _buildCardContainer(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Title
                  Text(
                    l10n?.updatePassword ?? "Update Password",
                    style: TextStyle(
                      fontSize: UIUtils.tileTitle(screenType),
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.tertiary,
                      fontFamily: AppConstants.fontFamily,
                    ),
                  ),
                  SizedBox(height: UIUtils.gapMD(screenType)),

                  // Current Password
                  CustomTextField(
                    label: l10n?.currentPassword ?? "Current Password",
                    controller: _currentPasswordController,
                    hint:
                        l10n?.enterCurrentPassword ??
                        "Enter your current password",
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: UIUtils.gapMD(screenType)),

                  // New Password
                  CustomTextField(
                    label: l10n?.newPassword ?? "New Password",
                    controller: _newPasswordController,
                    hint: l10n?.enterNewPassword ?? "Enter your new password",
                    obscureText: !_isNewPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isNewPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: UIUtils.gapMD(screenType)),

                  // Confirm Password
                  CustomTextField(
                    label: l10n?.confirmPassword ?? "Confirm Password",
                    controller: _confirmPasswordController,
                    hint:
                        l10n?.confirmNewPassword ?? "Confirm your new password",
                    obscureText: !_isConfirmPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),

                  // Change Password Button
                  SizedBox(height: UIUtils.gapXL(screenType)),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      text: isChangingPassword
                          ? l10n?.changing ?? "Changing..."
                          : l10n?.changePassword ?? "Change Password",
                      onPressed: isUpdating || isChangingPassword
                          ? () {}
                          : _onChangePassword,
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: UIUtils.gapXL(screenType)),
          ],
        ),
      ),
    );
  }

  /// Shared card wrapper — keeps both cards visually identical.
  Widget _buildCardContainer({required bool isDark, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: child,
    );
  }

  Widget _buildProfileImage(ScreenType screenType) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: _selectedImage != null
              ? FileImage(File(_selectedImage!.path))
              : (_currentProfileImageUrl != null &&
                    _currentProfileImageUrl!.isNotEmpty)
              ? NetworkImage(_currentProfileImageUrl!) as ImageProvider
              : null,
          child:
              (_selectedImage == null &&
                  (_currentProfileImageUrl == null ||
                      _currentProfileImageUrl!.isEmpty))
              ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
