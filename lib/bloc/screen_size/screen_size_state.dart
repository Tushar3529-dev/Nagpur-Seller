part of 'screen_size_bloc.dart';

class ScreenSizeState extends Equatable {
  final ScreenType screenType;
  final Size size;

  const ScreenSizeState({
    required this.screenType,
    required this.size,
  });

  factory ScreenSizeState.initial() {
    return const ScreenSizeState(
      screenType: ScreenType.mobile,
      size: Size.zero,
    );
  }

  ScreenSizeState copyWith({
    ScreenType? screenType,
    Size? size,
  }) {
    return ScreenSizeState(
      screenType: screenType ?? this.screenType,
      size: size ?? this.size,
    );
  }

  @override
  List<Object> get props => [screenType, size];
}
