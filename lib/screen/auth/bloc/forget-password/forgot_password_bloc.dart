import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/auth/bloc/forget-password/forgot_password_event.dart';
import 'package:hyper_local_seller/screen/auth/bloc/forget-password/forgot_password_state.dart';
import 'package:hyper_local_seller/screen/auth/repo/auth_repo.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthRepository authRepository;

  ForgotPasswordBloc(this.authRepository) : super(ForgotPasswordInitial()) {
    on<ForgotPasswordSubmitted>(_onForgotPasswordSubmitted);
  }

  Future<void> _onForgotPasswordSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(ForgotPasswordLoading());

    try {
      final response = await authRepository.forgotPassword(event.email);

      // Extract message from response
      String message = 'Password reset link has been sent to your email';
      if (response is Map<String, dynamic> && response.containsKey('message')) {
        message = response['message'].toString();
      }

      emit(ForgotPasswordSuccess(message));
    } catch (e) {
      emit(ForgotPasswordFailure(e.toString()));
    }
  }
}
