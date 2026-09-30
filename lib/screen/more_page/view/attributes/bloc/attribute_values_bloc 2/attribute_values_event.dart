part of 'attribute_values_bloc.dart';

abstract class AttributeValuesEvent {}

class LoadAttributeValues extends AttributeValuesEvent {
  final int attributeId;
  LoadAttributeValues(this.attributeId);
}

class AddAttributeValue extends AttributeValuesEvent {
  final int attributeId;
  final Map<String, dynamic> data;
  AddAttributeValue(this.attributeId, this.data);
}

class UpdateAttributeValue extends AttributeValuesEvent {
  final int attributeId;
  final int valueId;
  final Map<String, dynamic> data;
  UpdateAttributeValue(this.attributeId, this.valueId, this.data);
}

class DeleteAttributeValue extends AttributeValuesEvent {
  final int attributeId;
  final int valueId;

  DeleteAttributeValue(this.attributeId, this.valueId);
}

class AttributeValuesReset extends AttributeValuesEvent {}
