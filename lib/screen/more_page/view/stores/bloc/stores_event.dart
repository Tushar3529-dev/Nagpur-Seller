part of 'stores_bloc.dart';

abstract class StoresEvent {}

class LoadStoresInitial extends StoresEvent {
  final String? search;
  LoadStoresInitial({this.search});
}

class LoadMoreStores extends StoresEvent {}

class RefreshStores extends StoresEvent {}

class SearchStores extends StoresEvent {
  final String query;
  SearchStores(this.query);
}

class LoadStoreFilters extends StoresEvent {}

class ApplyStoreFilter extends StoresEvent {
  final String? status;
  final String? visibilityStatus;
  final String? verificationStatus;

  ApplyStoreFilter({
    this.status,
    this.visibilityStatus,
    this.verificationStatus,
  });
}

class DeleteStore extends StoresEvent {
  final int storeId;
  DeleteStore(this.storeId);
}

class ToggleStoreStatus extends StoresEvent {
  final int storeId;
  final String status;
  ToggleStoreStatus(this.storeId, this.status);
}

class ClearStores extends StoresEvent {}

class ClearStoresOperation extends StoresEvent {}

