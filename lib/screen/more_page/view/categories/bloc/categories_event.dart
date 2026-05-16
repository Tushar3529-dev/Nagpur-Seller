part of 'categories_bloc.dart';

abstract class CategoriesEvent {}

class LoadCategoriesInitial extends CategoriesEvent {
  final String? slug;
  final String? search;
  LoadCategoriesInitial({this.slug, this.search});
}

class LoadMoreCategories extends CategoriesEvent {}

class RefreshCategories extends CategoriesEvent {}

class SearchCategories extends CategoriesEvent {
  final String query;
  SearchCategories(this.query);
}

class ClearCategories extends CategoriesEvent {}