import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_state.dart';
import 'package:hyper_local_seller/utils/validator_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_phone_field.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class BasicDetailsStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const BasicDetailsStep({super.key, required this.formKey});

  @override
  State<BasicDetailsStep> createState() => _BasicDetailsStepState();
}

class _BasicDetailsStepState extends State<BasicDetailsStep> {
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode storeNameNode = FocusNode();
  final FocusNode emailNode = FocusNode();
  final FocusNode phoneNode = FocusNode();
  
  bool _isSyncing = false;

  @override
  void dispose() {
    storeNameNode.dispose();
    emailNode.dispose();
    phoneNode.dispose();
    _storeNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final formData = context.read<AddStoreBloc>().state.formData;
    _syncWithFormData(formData);

    _storeNameController.addListener(_updateBloc);
    _emailController.addListener(_updateBloc);
    _phoneController.addListener(_updateBloc);
  }

  void _syncWithFormData(Map<String, dynamic> data) {
    _isSyncing = true;
    if (data['name'] != _storeNameController.text) {
      _storeNameController.text = data['name'] ?? '';
    }
    if (data['contact_email'] != _emailController.text) {
      _emailController.text = data['contact_email'] ?? '';
    }
    if (data['contact_number'] != _phoneController.text) {
      _phoneController.text = data['contact_number'] ?? '';
    }
    _isSyncing = false;
  }

  void _updateBloc() {
    if (_isSyncing) return;
    context.read<AddStoreBloc>().add(
      UpdateStoreField({
        'name': _storeNameController.text,
        'contact_email': _emailController.text,
        'contact_number': _phoneController.text,
        'mobile': _phoneController.text,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<AddStoreBloc, AddStoreState>(
      listenWhen: (previous, current) => previous.formData != current.formData,
      listener: (context, state) {
        _syncWithFormData(state.formData);
      },
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: l10n?.storeName ?? "Store Name",
              isRequired: true,
              hint: l10n?.enterNickName ?? "Enter Nickname",
              controller: _storeNameController,
              validator: (value) => ValidatorUtils.validateEmpty(context, value),
              focusNode: storeNameNode,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.contactEmail ?? "Contact Email",
              isRequired: true,
              hint: l10n?.enterEmail ?? "Enter Email",
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => ValidatorUtils.validateEmail(context, value),
              focusNode: emailNode,
            ),
            const SizedBox(height: 20),
            CustomPhoneField(
              label: l10n?.mobileNumber ?? "Mobile Number",
              isRequired: true,
              controller: _phoneController,
              focusNode: phoneNode,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
