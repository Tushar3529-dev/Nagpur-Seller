import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/image_picker_utils.dart';
import 'package:hyper_local_seller/utils/validator_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_upload_area.dart';

class RequiredDocumentsStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(String, String) onFilePicked; // field, path
  final String? businessLicensePath;
  final String? articlesOfIncorporationPath;
  final String? nationalIdCardPath;
  final String? authorizedSignaturePath;

  const RequiredDocumentsStep({
    super.key,
    required this.formKey,
    required this.onFilePicked,
    this.businessLicensePath,
    this.articlesOfIncorporationPath,
    this.nationalIdCardPath,
    this.authorizedSignaturePath,
  });

  @override
  State<RequiredDocumentsStep> createState() => _RequiredDocumentsStepState();
}

class _RequiredDocumentsStepState extends State<RequiredDocumentsStep> {
  Future<void> _pickFile(String field) async {
    final path = await ImagePickerUtils.pickMedia(
      context,
      mediaType: MediaType.image,
    );
    if (path != null) {
      widget.onFilePicked(field, path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tertiary = theme.colorScheme.tertiary;
    final l10n = AppLocalizations.of(context);
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(
            l10n?.businessLicense ?? 'Business License',
            tertiary,
            isRequired: true,
          ),
          const SizedBox(height: 8),
          FormField<String>(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) => ValidatorUtils.validateFile(
              context,
              widget.businessLicensePath,
            ),
            builder: (state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomUploadArea(
                  hint: "+  ${l10n?.chooseFile ?? 'Choose File'} ",
                  fileName: widget.businessLicensePath,
                  onTap: () async {
                    await _pickFile('Business License');
                    state.didChange('picked');
                  },
                  onRemove: () {
                    widget.onFilePicked('Business License', '');
                    state.didChange(null);
                  },
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      state.errorText!,
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
            l10n?.articlesOfIncorporation ?? 'Articles of Incorporation',
            tertiary,
            isRequired: true,
          ),
          const SizedBox(height: 8),
          FormField<String>(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) => ValidatorUtils.validateFile(
              context,
              widget.articlesOfIncorporationPath,
            ),
            builder: (state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomUploadArea(
                  hint: "+  ${l10n?.chooseFile ?? 'Choose File'} ",
                  fileName: widget.articlesOfIncorporationPath,
                  onTap: () async {
                    await _pickFile('Articles of Incorporation');
                    state.didChange('picked');
                  },
                  onRemove: () {
                    widget.onFilePicked('Articles of Incorporation', '');
                    state.didChange(null);
                  },
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      state.errorText!,
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
            l10n?.nationalIdCard ?? 'National ID Card',
            tertiary,
            isRequired: true,
          ),
          const SizedBox(height: 8),
          FormField<String>(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) =>
                ValidatorUtils.validateFile(context, widget.nationalIdCardPath),
            builder: (state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomUploadArea(
                  hint: "+  ${l10n?.chooseFile ?? 'Choose File'} ",
                  fileName: widget.nationalIdCardPath,
                  onTap: () async {
                    await _pickFile('National ID Card');
                    state.didChange('picked');
                  },
                  onRemove: () {
                    widget.onFilePicked('National ID Card', '');
                    state.didChange(null);
                  },
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      state.errorText!,
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
            l10n?.authorizedSignature ?? 'Authorized Signature',
            tertiary,
            isRequired: true,
          ),
          const SizedBox(height: 8),
          FormField<String>(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) => ValidatorUtils.validateFile(
              context,
              widget.authorizedSignaturePath,
            ),
            builder: (state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomUploadArea(
                  hint: "+  ${l10n?.chooseFile ?? 'Choose File'} ",
                  fileName: widget.authorizedSignaturePath,
                  onTap: () async {
                    await _pickFile('Authorized Signature');
                    state.didChange('picked');
                  },
                  onRemove: () {
                    widget.onFilePicked('Authorized Signature', '');
                    state.didChange(null);
                  },
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      state.errorText!,
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
        ],
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
