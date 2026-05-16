import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_state.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/repo/add_store_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/model/store_model.dart';
import 'package:hyper_local_seller/utils/image_picker_utils.dart';

part 'add_store_event.dart';

class AddStoreBloc extends Bloc<AddStoreEvent, AddStoreState> {
  final AddStoreRepository repository;

  AddStoreBloc(this.repository) : super(AddStoreState(formData: {})) {
    // 1. Update form fields
    on<UpdateStoreField>((event, emit) {
      final currentFormData = state.formData;
      bool isChanged = false;

      event.fields.forEach((key, value) {
        if (currentFormData[key] != value) {
          isChanged = true;
        }
      });

      if (isChanged) {
        final newFormData = Map<String, dynamic>.from(currentFormData)
          ..addAll(event.fields);
        emit(state.copyWith(formData: newFormData));
      }
    });

    // 2. Clear state
    on<ClearAddStoreState>((event, emit) {
      emit(AddStoreState(formData: {}));
    });

    on<ResetMessages>((event, emit) {
      emit(state.copyWith(successMessage: null, errorMessage: null));
    });

    // 3. Initialize edit mode
    on<InitializeEditStore>((event, emit) async {
      emit(state.copyWith(isLoading: true, isEditMode: true));

      final initialData = {
        'name': event.store.name,
        'contact_email': event.store.contactEmail,
        'contact_number': event.store.contactNumber,
        'address': event.store.address,
        'latitude': event.store.latitude,
        'longitude': event.store.longitude,
        'country': event.store.country,
        'city': event.store.city,
        'state': event.store.state,
        'zipcode': event.store.zipcode,
        'landmark': event.store.landmark,
        'tax_name': event.store.taxName,
        'tax_number': event.store.taxNumber,
        'bank_name': event.store.bankName,
        'bank_branch_code': event.store.bankBranchCode,
        'account_holder_name': event.store.accountHolderName,
        'account_number': event.store.accountNumber,
        'routing_number': event.store.routingNumber,
        'bank_account_type': event.store.bankAccountType,
      };

      if (event.store.logo != null && event.store.logo!.isNotEmpty) {
        final logoPath = await ImagePickerUtils.downloadImageToFile(
          event.store.logo!,
        );
        if (logoPath != null) {
          initialData['store_logo'] = logoPath;
        }
      }

      if (event.store.banner != null && event.store.banner!.isNotEmpty) {
        final bannerPath = await ImagePickerUtils.downloadImageToFile(
          event.store.banner!,
        );
        if (bannerPath != null) {
          initialData['store_banner'] = bannerPath;
        }
      }

      if (event.store.addressProof != null && event.store.addressProof!.isNotEmpty) {
        final addressPath = await ImagePickerUtils.downloadImageToFile(
          event.store.addressProof!,
        );
        if (addressPath != null) {
          initialData['address_proof'] = addressPath;
        }
      }

      if (event.store.voidedCheck != null && event.store.voidedCheck!.isNotEmpty) {
        final voidedCheckPath = await ImagePickerUtils.downloadImageToFile(
          event.store.voidedCheck!,
        );
        if (voidedCheckPath != null) {
          initialData['voided_check'] = voidedCheckPath;
        }
      }



      emit(state.copyWith(formData: initialData, isLoading: false));
    });

    // 4. Submit store (Add/Edit)
    on<SubmitStore>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      try {
        final Map<String, dynamic> fields = Map.from(state.formData);
        final Map<String, dynamic> files = {};

        final fileKeys = [
          'store_logo',
          'store_banner',
          'address_proof',
          'voided_check',
        ];
        for (var key in fileKeys) {
          if (fields.containsKey(key) &&
              fields[key] != null &&
              fields[key] is String &&
              !fields[key].startsWith('http')) {
            files[key] = await MultipartFile.fromFile(fields[key]);
          }
          fields.remove(key);
        }

        if (event.isEdit) {
          fields['_method'] = 'POST';
        }

        final formData = FormData.fromMap({...fields, ...files});

        if (event.isEdit) {
          await repository.updateStore(event.storeId!, formData);
          emit(
            state.copyWith(
              isLoading: false,
              successMessage: "Store updated successfully",
            ),
          );
        } else {
          await repository.createStore(formData);
          emit(
            state.copyWith(
              isLoading: false,
              successMessage: "Store registered successfully",
            ),
          );
        }
      } catch (e) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    });

    // 5. Delete store
    on<DeleteStore>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      try {
        await repository.deleteStore(event.storeId);
        emit(
          state.copyWith(
            isLoading: false,
            successMessage: "Store deleted successfully",
          ),
        );
      } catch (e) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    });

    // 6. Toggle status
    on<ToggleStoreStatus>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      try {
        await repository.updateStoreStatus(event.storeId, event.status);
        emit(
          state.copyWith(
            isLoading: false,
            successMessage: "Store status updated to ${event.status}",
          ),
        );
      } catch (e) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    });
  }
}
