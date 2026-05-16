// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/model/store_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/repo/store_repo.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:collection/collection.dart';

class StoreSwitcherState extends Equatable {
  final List<Store> stores;
  final Store? selectedStore;
  final bool isLoading;

  const StoreSwitcherState({
    required this.stores,
    this.selectedStore,
    this.isLoading = false,
  });

  factory StoreSwitcherState.initial() => const StoreSwitcherState(
        stores: [],
        selectedStore: null,
      );

  StoreSwitcherState copyWith({
    List<Store>? stores,
    Store? selectedStore,
    bool? isLoading,
  }) {
    return StoreSwitcherState(
      stores: stores ?? this.stores,
      selectedStore: selectedStore ?? this.selectedStore,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [stores, selectedStore, isLoading];
}

class StoreSwitcherCubit extends Cubit<StoreSwitcherState> {
  final StoresRepo _repo;

  StoreSwitcherCubit(this._repo) : super(StoreSwitcherState.initial()) {
    loadStores();
  }

  Future<void> loadStores() async {
    emit(state.copyWith(isLoading: true));
    try {
      final response = await _repo.getStores(
        page: 1, 
        perPage: 50, // Keep 50 for switcher to show all usually
      );
      
      final storesResponse = StoresResponse.fromJson(response);
      final stores = storesResponse.data?.stores ?? [];
      
      // Filter for valid stores: not 'not_approved', not 'draft', and must be 'online'
      final validStores = stores.where((s) => 
        s.verificationStatus != 'not_approved' && 
        s.visibilityStatus != 'draft' &&
        s.status?.status?.toLowerCase() == 'online'
      ).toList();

      // Try to find the last selected store
      final lastSelectedStoreId = HiveStorage.selectedStoreId;
      var selectedStore = stores.firstWhereOrNull((s) => s.id == lastSelectedStoreId);

      // If last selected store is NOT valid (e.g. it's a draft or offline), try to pick a valid one
      if (selectedStore != null) {
         bool isValid = selectedStore.verificationStatus != 'not_approved' && 
                        selectedStore.visibilityStatus != 'draft' &&
                        selectedStore.status?.status?.toLowerCase() == 'online';
         if (!isValid) {
           selectedStore = validStores.isNotEmpty ? validStores.first : null;
           if (selectedStore != null) {
             HiveStorage.setSelectedStoreId(selectedStore.id); 
           } else {
             // If no valid store exists, clear the stored ID so UI can show "Add Store" or force selection
             HiveStorage.setSelectedStoreId(null);
           }
         }
      } else {
        selectedStore = validStores.isNotEmpty ? validStores.first : null;
        if (selectedStore != null) {
          HiveStorage.setSelectedStoreId(selectedStore.id);
        } else {
          HiveStorage.setSelectedStoreId(null);
        }
      }

      emit(state.copyWith(
        stores: stores,
        selectedStore: selectedStore,
        isLoading: false,
      ));
    } catch (e) {
      // If error occurs, we still want to set isLoading to false 
      // and ensure stores is at least the current list (even if empty)
      emit(state.copyWith(isLoading: false, stores: state.stores));
    }
  }

  void selectStore(Store store) {
    HiveStorage.setSelectedStoreId(store.id);
    emit(state.copyWith(selectedStore: store));
  }

  void clear() {
    emit(StoreSwitcherState.initial());
  }
}

