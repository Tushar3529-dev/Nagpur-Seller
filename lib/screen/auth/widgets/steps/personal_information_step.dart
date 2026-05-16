import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/auth/bloc/verify-user/verify_user_bloc.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/utils/validator_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_phone_field.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class PersonalInformationStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController mobileController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final FocusNode nameFocusNode;
  final FocusNode mobileFocusNode;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final FocusNode confirmPasswordFocusNode;
  final Function(String code, String flag) onCountryChanged;
  final String selectedCountryCode;
  final String selectedCountryFlag;

  const PersonalInformationStep({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.mobileController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.nameFocusNode,
    required this.mobileFocusNode,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.confirmPasswordFocusNode,
    required this.onCountryChanged,
    required this.selectedCountryCode,
    required this.selectedCountryFlag,
  });

  @override
  State<PersonalInformationStep> createState() =>
      _PersonalInformationStepState();
}

class _PersonalInformationStepState extends State<PersonalInformationStep> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final Debouncer _emailDebouncer = Debouncer(milliseconds: 500);
  final Debouncer _phoneDebouncer = Debouncer(milliseconds: 500);

  String? _emailVerificationError;
  String? _phoneVerificationError;

  @override
  void initState() {
    super.initState();

    // Add listeners for email verification
    widget.emailController.addListener(_onEmailChanged);

    // Add listeners for phone verification
    widget.mobileController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _emailDebouncer.dispose();
    _phoneDebouncer.dispose();
    widget.emailController.removeListener(_onEmailChanged);
    widget.mobileController.removeListener(_onPhoneChanged);
    super.dispose();
  }

  void _onEmailChanged() {
    final email = widget.emailController.text.trim();

    // Clear error when user starts typing
    if (_emailVerificationError != null) {
      setState(() {
        _emailVerificationError = null;
      });
    }

    // Validate email format before making API call
    if (email.isNotEmpty) {
      // Basic email validation regex
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );

      if (emailRegex.hasMatch(email)) {
        _emailDebouncer.run(() {
          context.read<VerifyUserBloc>().add(VerifyUserEmail('email', email));
        });
      }
    }
  }

  void _onPhoneChanged() {
    final phone = widget.mobileController.text.trim();

    // Clear error when user starts typing
    if (_phoneVerificationError != null) {
      setState(() {
        _phoneVerificationError = null;
      });
    }

    // Validate phone: only digits and exactly 10 digits
    if (phone.isNotEmpty) {
      final phoneRegex = RegExp(r'^\d{10}$');

      if (phoneRegex.hasMatch(phone)) {
        _phoneDebouncer.run(() {
          context.read<VerifyUserBloc>().add(VerifyUserPhone('mobile', phone));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocListener<VerifyUserBloc, VerifyUserState>(
      listener: (context, state) {
        if (state is VerifyUserAlreadyExists) {
          setState(() {
            if (state.type == 'email') {
              _emailVerificationError = state.message;
            } else if (state.type == 'phone') {
              _phoneVerificationError = state.message;
            }
          });
        } else if (state is VerifyUserValid) {
          setState(() {
            if (state.type == 'email') {
              _emailVerificationError = null;
            } else if (state.type == 'phone') {
              _phoneVerificationError = null;
            }
          });
        } else if (state is VerifyUserError) {
          // Optionally handle errors, but don't show them as validation errors
          // since they might be network issues
        }
      },
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: l10n?.sellerName ?? 'Seller Name',
              isRequired: true,
              hint: AppLocalizations.of(context)!.enterName,
              controller: widget.nameController,
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  ValidatorUtils.validateEmpty(context, value),
              focusNode: widget.nameFocusNode,
            ),
            const SizedBox(height: 20),

            CustomPhoneField(
              label: l10n?.mobileNumber ?? "Mobile Number",
              isRequired: true,
              controller: widget.mobileController,
              focusNode: widget.mobileFocusNode,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            if (_phoneVerificationError != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  _phoneVerificationError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.emailAddress ?? 'Email Address',
              isRequired: true,
              hint: l10n?.enterYourEmailAddress ?? 'Enter Your Email Address',
              controller: widget.emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  ValidatorUtils.validateEmail(context, value),
              focusNode: widget.emailFocusNode,
            ),
            if (_emailVerificationError != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  _emailVerificationError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.password ?? 'Password',
              isRequired: true,
              hint:l10n?.enterPassword ?? 'Enter Password',
              controller: widget.passwordController,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) =>
                  ValidatorUtils.validatePassword(context, value),
              focusNode: widget.passwordFocusNode,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.confirmPassword ?? 'Confirm Password',
              isRequired: true,
              hint:l10n?.confirmYourPassword ?? 'Confirm Your Password',
              controller: widget.confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
              validator: (value) => ValidatorUtils.validateConfirmPassword(
                context,
                value,
                widget.passwordController.text,
              ),
              focusNode: widget.confirmPasswordFocusNode,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
