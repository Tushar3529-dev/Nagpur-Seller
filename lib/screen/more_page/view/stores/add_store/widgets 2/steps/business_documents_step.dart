// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_state.dart';
import 'package:hyper_local_seller/utils/image_picker_utils.dart';
import 'package:hyper_local_seller/utils/validator_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_upload_area.dart';

class BusinessDocumentsStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const BusinessDocumentsStep({super.key, required this.formKey});

  @override
  State<BusinessDocumentsStep> createState() => _BusinessDocumentsStepState();
}

class _BusinessDocumentsStepState extends State<BusinessDocumentsStep> {
  final TextEditingController _taxNameController = TextEditingController();
  final TextEditingController _taxNumberController = TextEditingController();
  final FocusNode taxNameNode = FocusNode();
  final FocusNode taxNumberNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final formData = context.read<AddStoreBloc>().state.formData;
    _syncWithFormData(formData);

    _taxNameController.addListener(_updateBloc);
    _taxNumberController.addListener(_updateBloc);
  }

  @override
  void dispose() {
    taxNameNode.dispose();
    taxNumberNode.dispose();
    _taxNameController.dispose();
    _taxNumberController.dispose();
    super.dispose();
  }

  void _syncWithFormData(Map<String, dynamic> data) {
    if (data['tax_name'] != _taxNameController.text) {
      _taxNameController.text = data['tax_name'] ?? '';
    }
    if (data['tax_number'] != _taxNumberController.text) {
      _taxNumberController.text = data['tax_number'] ?? '';
    }
  }

  void _updateBloc() {
    context.read<AddStoreBloc>().add(
      UpdateStoreField({
        'tax_name': _taxNameController.text,
        'tax_number': _taxNumberController.text,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tertiary = theme.colorScheme.tertiary;
    final l10n = AppLocalizations.of(context);

    return BlocListener<AddStoreBloc, AddStoreState>(
      listenWhen: (previous, current) => previous.formData != current.formData,
      listener: (context, state) {
        _syncWithFormData(state.formData);
      },
      child: Form(
        key: widget.formKey,
        child: BlocBuilder<AddStoreBloc, AddStoreState>(
          builder: (context, state) {
            final addressProofFile = state.formData['address_proof'];
            final voidedCheckFile = state.formData['voided_check'];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(
                  l10n?.addressProof ?? "Address Proof",
                  tertiary,
                  isRequired: true,
                ),
                const SizedBox(height: 8),
                FormField<String>(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) =>
                      ValidatorUtils.validateFile(context, addressProofFile),
                  builder: (fieldState) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomUploadArea(
                        hint: l10n?.uploadImage ?? "+ Upload Image",
                        fileName: addressProofFile,
                        onTap: () async {
                          final path = await ImagePickerUtils.pickMedia(
                            context,
                            mediaType: MediaType.image,
                          );
                          if (path != null) {
                            context.read<AddStoreBloc>().add(
                              UpdateStoreField({'address_proof': path}),
                            );
                            fieldState.didChange(path);
                          }
                        },
                        onRemove: () {
                          context.read<AddStoreBloc>().add(
                            UpdateStoreField({'address_proof': null}),
                          );
                          fieldState.didChange(null);
                        },
                      ),
                      if (fieldState.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 12),
                          child: Text(
                            fieldState.errorText!,
                            style: const TextStyle(
                              color: AppColors.darkErrorColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _buildLabel(
                  l10n?.voidedCheck ?? "Voided Check",
                  tertiary,
                  isRequired: true,
                ),
                const SizedBox(height: 8),
                FormField<String>(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) =>
                      ValidatorUtils.validateFile(context, voidedCheckFile),
                  builder: (fieldState) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomUploadArea(
                        hint: l10n?.uploadImage ?? "+ Upload Image",
                        fileName: voidedCheckFile,
                        onTap: () async {
                          final path = await ImagePickerUtils.pickMedia(
                            context,
                            mediaType: MediaType.image,
                          );
                          if (path != null) {
                            context.read<AddStoreBloc>().add(
                              UpdateStoreField({'voided_check': path}),
                            );
                            fieldState.didChange(path);
                          }
                        },
                        onRemove: () {
                          context.read<AddStoreBloc>().add(
                            UpdateStoreField({'voided_check': null}),
                          );
                          fieldState.didChange(null);
                        },
                      ),
                      if (fieldState.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 12),
                          child: Text(
                            fieldState.errorText!,
                            style: TextStyle(
                              color: AppColors.darkErrorColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  label: l10n?.taxName ?? "Tax Name",
                  isRequired: true,
                  hint: "Eg. PAN",
                  controller: _taxNameController,
                  validator: (value) =>
                      ValidatorUtils.validateEmpty(context, value),
                  focusNode: taxNameNode,
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  label: l10n?.taxNumber ?? "Tax Number",
                  isRequired: true,
                  hint: "Eg. ABCDE1234F",
                  controller: _taxNumberController,
                  validator: (value) =>
                      ValidatorUtils.validateEmpty(context, value),
                  focusNode: taxNumberNode,
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}
