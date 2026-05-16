part of 'screen_size_bloc.dart';

abstract class ScreenSizeEvent extends Equatable {
  const ScreenSizeEvent();

  @override
  List<Object> get props => [];
}

class ScreenSizeChanged extends ScreenSizeEvent {
  final Size size;

  const ScreenSizeChanged(this.size);

  @override
  List<Object> get props => [size];
}
