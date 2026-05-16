import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

part 'screen_size_event.dart';
part 'screen_size_state.dart';

class ScreenSizeBloc extends Bloc<ScreenSizeEvent, ScreenSizeState> {
  ScreenSizeBloc() : super(ScreenSizeState.initial()) {
    on<ScreenSizeChanged>(_onScreenSizeChanged);
  }

  void _onScreenSizeChanged(
    ScreenSizeChanged event,
    Emitter<ScreenSizeState> emit,
  ) {
    final width = event.size.width;
    // Breakpoint: 600 or 768. 
    // Generally tablets start > 600. 
    // Let's use 768 as a safe tablet breakpoint or stick to 600 as per common Flutter standards.
    // The user's `responsive.dart` used 600. I will stick to 600 for consistency.
    final screenType = width >= 600 ? ScreenType.tablet : ScreenType.mobile;
    
    emit(state.copyWith(
      screenType: screenType,
      size: event.size,
    ));
  }
}
