part of 'attributes_bloc.dart';

abstract class AttributesEvent {}

class LoadAttributesInitial extends AttributesEvent {
  final String? search;
  LoadAttributesInitial({this.search});
}

class LoadMoreAttributes extends AttributesEvent {}

class RefreshAttributes extends AttributesEvent {}

class SearchAttributes extends AttributesEvent {
  final String query;
  SearchAttributes(this.query);
}

class AddAttribute extends AttributesEvent {
  final Map<String, dynamic> data;
  AddAttribute(this.data);
}

class UpdateAttribute extends AttributesEvent {
  final int id;
  final Map<String, dynamic> data;
  UpdateAttribute(this.id, this.data);
}

class DeleteAttribute extends AttributesEvent {
  final int id;
  DeleteAttribute(this.id);
}

class ClearAttributeOperationState extends AttributesEvent {}

class AttributesReset extends AttributesEvent {}
