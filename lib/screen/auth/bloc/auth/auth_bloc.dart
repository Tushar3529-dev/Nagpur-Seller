import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_event.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_state.dart';
import 'package:hyper_local_seller/screen/auth/repo/auth_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/profile/bloc/profile_bloc.dart';
import 'package:hyper_local_seller/service/phone_auth.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/subscription_reminder_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final FirebasePhoneAuthService phoneAuthService;

  AuthBloc(this.authRepository, this.phoneAuthService) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthPhoneSendOTPRequested>(_onPhoneSendOTPRequested);
    on<AuthPhoneVerifyOTPRequested>(_onPhoneVerifyOTPRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.login(email: event.email, password: event.password);
      // Fetch and store user profile after successful login
      await ProfileBloc.fetchAndStoreProfile();
      emit(const AuthSuccess(message: "Login Successful"));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll("Exception:", "").trim()));
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await authRepository.signUp(
        name: event.name,
        email: event.email,
        phone: event.phone,
        password: event.password,
        address: event.address,
        city: event.city,
        state: event.state,
        landmark: event.landmark,
        zipcode: event.zipcode,
        country: event.country,
        latitude: event.latitude,
        longitude: event.longitude,
        businessLicensePath: event.businessLicensePath,
        articlesOfIncorporationPath: event.articlesOfIncorporationPath,
        nationalIdCardPath: event.nationalIdCardPath,
        authorizedSignaturePath: event.authorizedSignaturePath,
      );
      final message = (response is Map && response.containsKey('message')) 
          ? response['message'].toString() 
          : "Account Created Successfully";
      emit(AuthSuccess(message: message));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll("Exception:", "").trim()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      SubscriptionReminderService().hideReminderOverlay();
      SubscriptionReminderService().resetSession();
      await authRepository.logout();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onPhoneSendOTPRequested(
    AuthPhoneSendOTPRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      if (HiveStorage.isCustomSms) {
        final response = await authRepository.customSendOtp(phone: event.phoneNumber);
        if (response['success'] == true) {
           if (!emit.isDone) {
             emit(AuthOTPSent(
               verificationId: "customSms",
               phoneNumber: event.phoneNumber,
             ));
           }
        } else {
           if (!emit.isDone) {
             emit(AuthFailure(response['message']?.toString() ?? "Failed to send OTP"));
           }
        }
        return;
      }

      final verificationId = await phoneAuthService.sendOTP(
        phoneNumber: event.phoneNumber,
        onError: (error) {
          if (!emit.isDone) {
            emit(AuthFailure(error));
          }
        },
        onAutoVerify: () {
          if (!emit.isDone) {
            emit(const AuthOTPVerified(message: "Auto verified successfully"));
          }
        },
      );

      if (!emit.isDone) {
        emit(AuthOTPSent(
          verificationId: verificationId,
          phoneNumber: event.phoneNumber,
        ));
      }
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll("Exception:", "").trim()));
    }
  }

  Future<void> _onPhoneVerifyOTPRequested(
    AuthPhoneVerifyOTPRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      if (HiveStorage.isCustomSms) {
         final response = await authRepository.customVerifyOtp(
            phone: event.phoneNumber ?? "",
            otp: event.otp,
         );
         if (response['success'] == true) {
            await ProfileBloc.fetchAndStoreProfile();
            emit(const AuthSuccess(message: "Login Successful"));
         } else {
            emit(AuthFailure(response['message']?.toString() ?? "OTP verification failed"));
         }
         return;
      }

      final userCredential = await phoneAuthService.verifyOTP(
        verificationId: event.verificationId,
        otp: event.otp,
      );

      if (userCredential.user != null) {
        // Get the ID Token from Firebase User
        final idToken = await userCredential.user!.getIdToken();
        
        if (idToken != null) {
          // Call backend callback with this token
          await authRepository.phoneCallback(idToken: idToken);
          
          // After successful backend callback, fetch and store profile
          await ProfileBloc.fetchAndStoreProfile();
          emit(const AuthSuccess(message: "Login Successful"));
        } else {
          emit(const AuthFailure("Failed to get ID token from Firebase"));
        }
      } else {
        emit(const AuthFailure("OTP verification failed"));
      }
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll("Exception:", "").trim()));
    }
  }
}
