part of 'add_store_bloc.dart';

abstract class AddStoreEvent {}

class InitializeEditStore extends AddStoreEvent {
  final Store store;
  InitializeEditStore(this.store);
}

class UpdateStoreField extends AddStoreEvent {
  final Map<String, dynamic> fields;
  UpdateStoreField(this.fields);
}

class SubmitStore extends AddStoreEvent {
  final bool isEdit;
  final int? storeId;
  SubmitStore({required this.isEdit, this.storeId});
}

class DeleteStore extends AddStoreEvent {
  final int storeId;
  DeleteStore(this.storeId);
}

class ToggleStoreStatus extends AddStoreEvent {
  final int storeId;
  final String status;
  ToggleStoreStatus(this.storeId, this.status);
}

class ClearAddStoreState extends AddStoreEvent {}
class ResetMessages extends AddStoreEvent {}