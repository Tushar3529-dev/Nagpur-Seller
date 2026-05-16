part of 'brands_bloc.dart';

abstract class BrandsEvent {}

class LoadBrandsInitial extends BrandsEvent {
  final String? search;
  LoadBrandsInitial({this.search});
}

class LoadMoreBrands extends BrandsEvent {}

class RefreshBrands extends BrandsEvent {}

class SearchBrands extends BrandsEvent {
  final String query;
  SearchBrands(this.query);
}

class ClearBrands extends BrandsEvent {}

