part of 'home_page_bloc.dart';

abstract class HomePageEvent {}

class FetchHomePageData extends HomePageEvent {
  final int? storeId;
  FetchHomePageData({this.storeId});
}

class HomePageReset extends HomePageEvent {
  HomePageReset();
}
