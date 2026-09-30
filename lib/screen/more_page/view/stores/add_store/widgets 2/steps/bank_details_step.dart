import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_state.dart';
import 'package:hyper_local_seller/utils/validator_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_dropdown.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class BankDetailsStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const BankDetailsStep({super.key, required this.formKey});

  @override
  State<BankDetailsStep> createState() => _BankDetailsStepState();
}

class _BankDetailsStepState extends State<BankDetailsStep> {
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _branchCodeController = TextEditingController();
  final TextEditingController _holderNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _routingNumberController =
      TextEditingController();

  String? _selectedAccountType = 'savings';

  final FocusNode bankNameNode = FocusNode();
  final FocusNode branchCodeNode = FocusNode();
  final FocusNode holderNameNode = FocusNode();
  final FocusNode accountNumberNode = FocusNode();
  final FocusNode routingNumberNode = FocusNode();
  
  bool _isSyncing = false;

  @override
  void dispose() {
    bankNameNode.dispose();
    branchCodeNode.dispose();
    holderNameNode.dispose();
    _bankNameController.dispose();
    _branchCodeController.dispose();
    _holderNameController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    accountNumberNode.dispose();
    routingNumberNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final formData = context.read<AddStoreBloc>().state.formData;
    _syncWithFormData(formData);

    _bankNameController.addListener(_updateBloc);
    _branchCodeController.addListener(_updateBloc);
    _holderNameController.addListener(_updateBloc);
    _accountNumberController.addListener(_updateBloc);
    _routingNumberController.addListener(_updateBloc);
  }

  void _syncWithFormData(Map<String, dynamic> data) {
    _isSyncing = true;
    if (data['bank_name'] != _bankNameController.text) {
      _bankNameController.text = data['bank_name'] ?? '';
    }
    if (data['bank_branch_code'] != _branchCodeController.text) {
      _branchCodeController.text = data['bank_branch_code'] ?? '';
    }
    if (data['account_holder_name'] != _holderNameController.text) {
      _holderNameController.text = data['account_holder_name'] ?? '';
    }
    if (data['account_number']?.toString() != _accountNumberController.text) {
      _accountNumberController.text = data['account_number']?.toString() ?? '';
    }
    if (data['routing_number']?.toString() != _routingNumberController.text) {
      _routingNumberController.text = data['routing_number']?.toString() ?? '';
    }
    if (data['bank_account_type'] != _selectedAccountType) {
      setState(() {
        _selectedAccountType = data['bank_account_type'] ?? 'savings';
      });
    }
    _isSyncing = false;
  }

  void _updateBloc() {
    if (_isSyncing) return;
    context.read<AddStoreBloc>().add(
      UpdateStoreField({
        'bank_name': _bankNameController.text,
        'bank_branch_code': _branchCodeController.text,
        'account_holder_name': _holderNameController.text,
        'account_number': _accountNumberController.text,
        'routing_number': _routingNumberController.text,
        'bank_account_type': _selectedAccountType,
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
              label: l10n?.bankName ?? "Bank Name",
              isRequired: true,
              hint: "HDFC BANK",
              controller: _bankNameController,
              validator: (value) => ValidatorUtils.validateEmpty(context, value),
              focusNode: bankNameNode,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.bankBranchCode ?? "Bank Branch Code",
              isRequired: true,
              hint: "646",
              controller: _branchCodeController,
              validator: (value) => ValidatorUtils.validateEmpty(context, value),
              focusNode: branchCodeNode,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.accountHolderName ?? "Account Holder Name",
              isRequired: true,
              hint: "John Doe",
              controller: _holderNameController,
              validator: (value) => ValidatorUtils.validateEmpty(context, value),
              focusNode: holderNameNode,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.accountNumber ?? "Account Number",
              isRequired: true,
              hint: "1202 5236 5258 2024",
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              validator: (value) => ValidatorUtils.validateEmpty(context, value),
              focusNode: accountNumberNode,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.routingNumber ?? "Routing Number",
              isRequired: true,
              hint: "12",
              keyboardType: TextInputType.number,
              controller: _routingNumberController,
              validator: (value) => ValidatorUtils.validateEmpty(context, value),
              focusNode: routingNumberNode,
            ),
            const SizedBox(height: 20),
            CustomDropdown<String>(
              label: l10n?.bankAccountType ?? "Bank Account Type",
              value: _selectedAccountType,
              items: [
                CustomDropdownItem(label: l10n?.checking ?? "Checking", value: "checking"),
                CustomDropdownItem(label: l10n?.savings ?? "Savings", value: "savings"),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedAccountType = val;
                });
                _updateBloc(); // important: save to bloc immediately
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
