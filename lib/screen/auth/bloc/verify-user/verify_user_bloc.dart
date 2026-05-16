import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/auth/repo/auth_repo.dart';

part 'verify_user_event.dart';
part 'verify_user_state.dart';

class VerifyUserBloc extends Bloc<VerifyUserEvent, VerifyUserState> {
  final AuthRepository authRepository;

  VerifyUserBloc({required this.authRepository}) : super(VerifyUserInitial()) {
    on<VerifyUserEmail>(_onVerifyEmail);
    on<VerifyUserPhone>(_onVerifyPhone);
  }

  Future<void> _onVerifyEmail(
    VerifyUserEmail event,
    Emitter<VerifyUserState> emit,
  ) async {
    await _verify(event.type, event.value, emit);
  }

  Future<void> _onVerifyPhone(
    VerifyUserPhone event,
    Emitter<VerifyUserState> emit,
  ) async {
    await _verify(event.type, event.value, emit);
  }

  Future<void> _verify(
    String type,
    String value,
    Emitter<VerifyUserState> emit,
  ) async {
    if (value.trim().isEmpty) {
      emit(VerifyUserValid(type, value)); // or emit error — your choice
      return;
    }

    emit(VerifyUserLoading(type));

    try {
      final response = await authRepository.verifyUser(type, value);

      // Assuming response follows the structure you showed
      final bool exists = response['data']?['exists'] == true;

      if (exists) {
        final String message = type == 'email'
            ? 'Email already exists'
            : 'Phone number already exists';

        emit(VerifyUserAlreadyExists(type, value, message));
      } else {
        emit(VerifyUserValid(type, value));
      }
    } catch (e) {
      String errorMsg = e.toString().replaceFirst('Exception: ', '');

      // Clean up common backend messages if needed
      if (errorMsg.contains('User not found')) {
        // If API says "User not found" → means available
        emit(VerifyUserValid(type, value));
      } else {
        emit(
          VerifyUserError(
            type,
            errorMsg.isNotEmpty ? errorMsg : 'Something went wrong',
          ),
        );
      }
    }
  }
}
