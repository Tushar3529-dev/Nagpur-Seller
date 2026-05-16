part of 'home_page_bloc.dart';

abstract class HomePageState {}

class HomePageInitial extends HomePageState {}

class HomePageLoading extends HomePageState {}

class HomePageLoaded extends HomePageState {
  final HomePageData data;
  HomePageLoaded(this.data);
}

class HomePageError extends HomePageState {
  final String message;
  HomePageError(this.message);
}
