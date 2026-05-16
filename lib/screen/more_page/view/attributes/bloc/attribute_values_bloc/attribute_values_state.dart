part of 'attribute_values_bloc.dart';

abstract class AttributeValuesState {}

class AttributeValuesInitial extends AttributeValuesState {}

class AttributeValuesLoading extends AttributeValuesState {}

class AttributeValuesLoaded extends AttributeValuesState {
  final AttributeValueData data;
  AttributeValuesLoaded(this.data);
}

class AttributeValuesFailure extends AttributeValuesState {
  final String error;
  final AttributeValueData? data;
  AttributeValuesFailure(this.error, {this.data});
}
