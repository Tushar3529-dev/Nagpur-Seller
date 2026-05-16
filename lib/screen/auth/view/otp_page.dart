import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_bloc.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_event.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_state.dart';
import 'package:hyper_local_seller/screen/auth/widgets/auth_header.dart';
import 'package:hyper_local_seller/screen/auth/widgets/otp_input.dart';
import 'package:hyper_local_seller/screen/more_page/view/profile/bloc/profile_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/service/master_api_service.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/config/constant.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

class OtpPage extends StatefulWidget {
  final String? verificationId;
  final String? phoneNumber;

  const OtpPage({super.key, this.verificationId, this.phoneNumber});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  int _secondsRemaining = 60;
  Timer? _timer;
  String _enteredOtp = '';
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _canResend = false;
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenType = context.screenType;

    return CustomScaffold(
      showAppbar: false,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            showCustomSnackbar(
              context: context,
              message: state.error,
              isError: true,
            );
          } else if (state is AuthSuccess || state is AuthOTPVerified) {
            // IMPORTANT: Refresh all data BEFORE navigating.
            MasterApiService.callNeededApisOnLogin(context);
            context.go(AppRoutes.home);
            showCustomSnackbar(
              context: context,
              message: state is AuthSuccess
                  ? state.message
                  : "Login Successful",
            );
          } else if (state is AuthOTPSent) {
            // OTP resent successfully
            showCustomSnackbar(
              context: context,
              message: "OTP sent successfully",
            );
            _startTimer();
          }
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  const AuthHeader(
                    title: '',
                    subtitle: '',
                    showBackButton: true,
                  ),
                  Padding(
                    padding: UIUtils.pagePadding(screenType),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: UIUtils.gapLG(screenType)),
                        Text(
                          l10n?.enterOtp ?? "Enter OTP",
                          style: TextStyle(
                            fontFamily: AppConstants.fontFamily,
                            fontWeight: UIUtils.bold,
                            fontSize: UIUtils.appTitle(screenType),
                            color: isDark
                                ? AppColors.darkFontColor
                                : AppColors.lightFontColor,
                          ),
                        ),
                        SizedBox(height: UIUtils.gapSM(screenType)),
                        if (widget.phoneNumber != null)
                          Text(
                            "OTP sent to ${widget.phoneNumber}",
                            style: TextStyle(
                              fontFamily: AppConstants.fontFamily,
                              fontSize: UIUtils.body(screenType),
                              color: Colors.grey,
                            ),
                          ),
                        SizedBox(height: UIUtils.gapXL(screenType)),
                        OtpInput(
                          onCompleted: (otp) {
                            setState(() {
                              _enteredOtp = otp;
                            });
                          },
                        ),
                        SizedBox(height: UIUtils.gapLG(screenType)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!_canResend) ...[
                              Text(
                                l10n?.resendOtpIn ?? "Resend OTP in",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontFamily: AppConstants.fontFamily,
                                  fontSize: UIUtils.body(screenType),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$_secondsRemaining s",
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: UIUtils.bold,
                                  fontFamily: AppConstants.fontFamily,
                                  fontSize: UIUtils.body(screenType),
                                ),
                              ),
                            ] else ...[
                              TextButton(
                                onPressed: () {
                                  if (widget.phoneNumber != null) {
                                    context.read<AuthBloc>().add(
                                      AuthPhoneSendOTPRequested(
                                        widget.phoneNumber!,
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  l10n?.resendOtp ?? "Resend OTP",
                                  style: TextStyle(
                                    color: AppColors.primaryColor,
                                    fontWeight: UIUtils.bold,
                                    fontFamily: AppConstants.fontFamily,
                                    fontSize: UIUtils.body(screenType),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: UIUtils.gapXL(screenType)),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            return PrimaryButton(
                              text: l10n?.verifyOtp ?? "VERIFY OTP",
                              backgroundColor: _enteredOtp.length == 6
                                  ? AppColors.primaryColor
                                  : Colors.grey,
                              onPressed:
                                  (_enteredOtp.length != 6 ||
                                      state is AuthLoading ||
                                      widget.verificationId == null)
                                  ? null
                                  : () {
                                      context.read<AuthBloc>().add(
                                        AuthPhoneVerifyOTPRequested(
                                          verificationId:
                                              widget.verificationId!,
                                          otp: _enteredOtp,
                                          phoneNumber: widget.phoneNumber,
                                        ),
                                      );
                                    },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Full-screen loading overlay
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthLoading) {
                  return Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: const Center(child: CustomLoadingIndicator()),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
