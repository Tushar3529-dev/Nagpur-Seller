// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_state.dart';
import 'package:hyper_local_seller/utils/image_picker_utils.dart';
import 'package:hyper_local_seller/utils/validator_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_upload_area.dart';

class LogoBannerStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const LogoBannerStep({super.key, required this.formKey});

  @override
  State<LogoBannerStep> createState() => _LogoBannerStepState();
}

class _LogoBannerStepState extends State<LogoBannerStep> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tertiary = theme.colorScheme.tertiary;

    final l10n = AppLocalizations.of(context);
    return Form(
      key: widget.formKey,
      child: BlocBuilder<AddStoreBloc, AddStoreState>(
        builder: (context, state) {
          final logoFileName = state.formData['store_logo'];
          final bannerFileName = state.formData['store_banner'];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(l10n?.storeLogo ?? "Store Logo", tertiary, isRequired: true),
              const SizedBox(height: 8),
              FormField<String>(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) =>
                    ValidatorUtils.validateFile(context, logoFileName),
                builder: (fieldState) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomUploadArea(
                      hint: l10n?.dragAndDropHint ?? "Drag & Drop your files or Browse",
                      fileName: logoFileName,
                      onTap: () async {
                        final path = await ImagePickerUtils.pickMedia(
                          context,
                          mediaType: MediaType.image,
                          maxSizeMb: 1.0,
                        );
                        if (path != null) {
                          context.read<AddStoreBloc>().add(
                            UpdateStoreField({'store_logo': path}),
                          );
                          fieldState.didChange(path);
                        }
                      },
                      onRemove: () {
                        context.read<AddStoreBloc>().add(
                          UpdateStoreField({'store_logo': null}),
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
              const SizedBox(height: 24),
              _buildLabel(l10n?.storeBanner ?? "Store Banner", tertiary),
              const SizedBox(height: 8),
              CustomUploadArea(
                hint: l10n?.dragAndDropHint ?? "Drag & Drop your files or Browse",
                fileName: bannerFileName,
                onTap: () async {
                  final path = await ImagePickerUtils.pickMedia(
                    context,
                    mediaType: MediaType.image,
                    maxSizeMb: 1.0,
                  );
                  if (path != null) {
                    context.read<AddStoreBloc>().add(
                      UpdateStoreField({'store_banner': path}),
                    );
                  }
                },
                onRemove: () {
                  context.read<AddStoreBloc>().add(
                    UpdateStoreField({'store_banner': null}),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          );
        },
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
