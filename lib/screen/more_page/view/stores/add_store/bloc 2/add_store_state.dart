import 'package:equatable/equatable.dart';

class AddStoreState extends Equatable {
  final Map<String, dynamic> formData;
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;
  final bool isEditMode;

  const AddStoreState({
    required this.formData,
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
    this.isEditMode = false,
  });

  AddStoreState copyWith({
    Map<String, dynamic>? formData,
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
    bool? isEditMode,
  }) {
    return AddStoreState(
      formData: formData ?? this.formData,
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
      isEditMode: isEditMode ?? this.isEditMode,
    );
  }

  @override
  List<Object?> get props => [
        formData,
        isLoading,
        successMessage,
        errorMessage,
        isEditMode,
      ];
}