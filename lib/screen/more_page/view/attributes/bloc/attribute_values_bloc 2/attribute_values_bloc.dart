import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/model/attribute_values_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/repo/attributes_repo.dart';

part 'attribute_values_event.dart';
part 'attribute_values_state.dart';

class AttributeValuesBloc
    extends Bloc<AttributeValuesEvent, AttributeValuesState> {
  final AttributesRepo _repo;

  AttributeValuesBloc(this._repo) : super(AttributeValuesInitial()) {
    on<LoadAttributeValues>(_onLoadAttributeValues);
    on<AddAttributeValue>(_onAddAttributeValue);
    on<UpdateAttributeValue>(_onUpdateAttributeValue);
    on<DeleteAttributeValue>(_onDeleteAttributeValue);
    on<AttributeValuesReset>(_onReset);
  }

  Future<void> _onLoadAttributeValues(
    LoadAttributeValues event,
    Emitter<AttributeValuesState> emit,
  ) async {
    emit(AttributeValuesLoading());
    try {
      final response = await _repo.getAttributeValues(event.attributeId);
      final valuesResponse = AttributeValuesResponse.fromJson(response);
      if (valuesResponse.data != null) {
        emit(AttributeValuesLoaded(valuesResponse.data!));
      } else {
        emit(AttributeValuesFailure("No data found"));
      }
    } catch (e) {
      emit(_getFailureState(e.toString()));
    }
  }

  Future<void> _onAddAttributeValue(
    AddAttributeValue event,
    Emitter<AttributeValuesState> emit,
  ) async {
    try {
      await _repo.addAttributeValue(event.data);
      add(LoadAttributeValues(event.attributeId));
    } catch (e) {
      emit(_getFailureState(e.toString()));
    }
  }

  Future<void> _onUpdateAttributeValue(
    UpdateAttributeValue event,
    Emitter<AttributeValuesState> emit,
  ) async {
    try {
      await _repo.updateAttributeValue(event.valueId, event.data);
      add(LoadAttributeValues(event.attributeId));
    } catch (e) {
      emit(_getFailureState(e.toString()));
    }
  }

  Future<void> _onDeleteAttributeValue(
    DeleteAttributeValue event,
    Emitter<AttributeValuesState> emit,
  ) async {
    try {
      await _repo.deleteAttributeValue(event.valueId);
      add(LoadAttributeValues(event.attributeId));
    } catch (e) {
      emit(_getFailureState(e.toString()));
    }
  }

  void _onReset(
      AttributeValuesReset event,
      Emitter<AttributeValuesState> emit,
      ) {
    emit(AttributeValuesInitial());
  }

  AttributeValuesFailure _getFailureState(String error) {
    AttributeValueData? previousData;
    if (state is AttributeValuesLoaded) {
      previousData = (state as AttributeValuesLoaded).data;
    } else if (state is AttributeValuesFailure) {
      previousData = (state as AttributeValuesFailure).data;
    }

    // Remove "Exception: " prefix if present
    String cleanError = error.startsWith('Exception: ')
        ? error.replaceFirst('Exception: ', '')
        : error;

    return AttributeValuesFailure(cleanError, data: previousData);
  }
}
