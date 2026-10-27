import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/bloc/delivery_boy_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/model/delivery_boy_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/model/delivery_zone_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/repo/delivery_zone_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class AddEditRiderPage extends StatefulWidget {
  final DeliveryBoy? rider;
  const AddEditRiderPage({super.key, this.rider});
  @override
  State<AddEditRiderPage> createState() => _AddEditRiderPageState();
}

class _AddEditRiderPageState extends State<AddEditRiderPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  List<DeliveryZone> _zones = [];
  int? _zoneId;
  bool _loadingZones = true;
  String? _zonesError;
  bool _saving = false;
  Map<String, String> _errors = {};
  @override
  void initState() {
    super.initState();
    final rider = widget.rider;
    _name.text = rider?.name ?? '';
    _email.text = rider?.email ?? '';
    _mobile.text = rider?.mobile ?? '';
    _zoneId = rider?.deliveryZoneId;
    _loadZones();
  }

  Future<void> _loadZones() async {
    setState(() {
      _loadingZones = true;
      _zonesError = null;
    });
    try {
      final repo = context.read<DeliveryZoneRepo>();
      final zones = <DeliveryZone>[];
      var page = 1;
      while (true) {
        final response = DeliveryZoneResponse.fromJson(
          await repo.getDeliveryZone(page: page, perPage: 100),
        );
        zones.addAll(response.data?.zones ?? []);
        if (page >= (response.data?.lastPage ?? 1)) break;
        page++;
      }
      if (!mounted) return;
      setState(() {
        _zones = zones.where((zone) => zone.status == 'active').toList();
        if (!_zones.any((zone) => zone.id == _zoneId)) _zoneId = null;
        _loadingZones = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingZones = false;
        _zonesError = error is ApiException ? error.message : '';
      });
    }
  }

  void _save() {
    if (_saving || !DeliveryBoyBloc.canManage || _loadingZones) return;
    setState(() => _errors = {});
    if (!_formKey.currentState!.validate() ||
        !DemoGuard.shouldProceed(context)) {
      return;
    }
    setState(() => _saving = true);
    final bloc = context.read<DeliveryBoyBloc>();
    final rider = widget.rider;
    if (rider == null) {
      bloc.add(
        CreateRider(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          mobile: _mobile.text.trim(),
          password: _password.text,
          deliveryZoneId: _zoneId!,
        ),
      );
    } else {
      bloc.add(
        UpdateRider(
          rider.id,
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          mobile: _mobile.text.trim(),
          password: _password.text,
          deliveryZoneId: _zoneId!,
        ),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final edit = widget.rider != null;
    Widget serverError(String key) => _errors[key] == null
        ? const SizedBox.shrink()
        : Text(
            _errors[key]!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          );
    return CustomScaffold(
      showAppbar: true,
      centerTitle: true,
      title: edit
          ? l10n?.riderEditTitle ?? 'Edit Delivery Boy'
          : l10n?.riderAddTitle ?? 'Add Delivery Boy',
      body: BlocListener<DeliveryBoyBloc, DeliveryBoyState>(
        listenWhen: (previous, current) =>
            _saving &&
            previous.busyRiderIds.contains(widget.rider?.id ?? -1) &&
            !current.busyRiderIds.contains(widget.rider?.id ?? -1),
        listener: (context, state) {
          if (state.actionMessage != null) {
            showCustomSnackbar(context: context, message: state.actionMessage!);
            context.read<DeliveryBoyBloc>().add(ClearMessages());
            context.pop(true);
          } else {
            setState(() {
              _saving = false;
              _errors = state.fieldErrors;
            });
            showCustomSnackbar(
              context: context,
              isError: true,
              message: state.errorStatusCode == 403
                  ? l10n?.riderNoManagePermission ??
                        "You don't have permission to manage delivery boys"
                  : state.errorMessage?.isNotEmpty == true
                  ? state.errorMessage!
                  : l10n?.somethingWentWrong ?? 'Something went wrong',
            );
            context.read<DeliveryBoyBloc>().add(ClearMessages());
          }
        },
        child: SingleChildScrollView(
          padding: UIUtils.pagePadding(context.screenType),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!edit)
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n?.riderCreationNotice ??
                          'After creation, the platform admin must verify the rider before they can log in.',
                    ),
                  ),
                CustomTextField(
                  controller: _name,
                  label: l10n?.riderFullName ?? 'Full name',
                  isRequired: true,
                  enabled: !_saving,
                  onChanged: (_) => setState(() => _errors.remove('full_name')),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n?.riderNameRequired ?? 'Full name is required'
                      : null,
                ),
                serverError('full_name'),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _email,
                  label: l10n?.email ?? 'Email',
                  isRequired: true,
                  enabled: !_saving,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() => _errors.remove('email')),
                  validator: (value) =>
                      value == null ||
                          !RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(value.trim())
                      ? l10n?.riderValidEmail ?? 'Enter a valid email address'
                      : null,
                ),
                serverError('email'),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _mobile,
                  label: l10n?.mobileNumber ?? 'Mobile Number',
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() => _errors.remove('mobile')),
                ),
                serverError('mobile'),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _password,
                  label: l10n?.password ?? 'Password',
                  isRequired: !edit,
                  enabled: !_saving,
                  obscureText: true,
                  onChanged: (_) => setState(() => _errors.remove('password')),
                  validator: (value) {
                    if (!edit && (value == null || value.isEmpty)) {
                      return l10n?.passwordRequired ?? 'Password is required';
                    }
                    if (value != null && value.isNotEmpty && value.length < 8) {
                      return l10n?.passwordTooShort ??
                          'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                serverError('password'),
                if (edit)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l10n?.riderPasswordHelper ??
                          'Leave empty to keep current password. Changing it logs the rider out.',
                    ),
                  ),
                const SizedBox(height: 16),
                if (_loadingZones)
                  const Center(child: CustomLoadingIndicator())
                else if (_zonesError != null)
                  Column(
                    children: [
                      Text(
                        _zonesError!.isNotEmpty
                            ? _zonesError!
                            : l10n?.somethingWentWrong ??
                                  'Something went wrong',
                      ),
                      TextButton(
                        onPressed: _loadZones,
                        child: Text(l10n?.tryAgain ?? 'Try Again'),
                      ),
                    ],
                  )
                else
                  DropdownButtonFormField<int>(
                    initialValue: _zoneId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n?.riderDeliveryZone ?? 'Delivery zone',
                      errorText: _errors['delivery_zone_id'],
                    ),
                    items: _zones
                        .map(
                          (zone) => DropdownMenuItem(
                            value: zone.id,
                            child: Text(zone.name),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() {
                            _zoneId = value;
                            _errors.remove('delivery_zone_id');
                          }),
                    validator: (value) => value == null
                        ? l10n?.riderZoneRequired ?? 'Select a delivery zone'
                        : null,
                  ),
                const SizedBox(height: 24),
                if (_saving)
                  const Center(child: CustomLoadingIndicator())
                else
                  PrimaryButton(
                    text: l10n?.riderSave ?? 'Save',
                    onPressed:
                        DeliveryBoyBloc.canManage &&
                            !_loadingZones &&
                            _zonesError == null
                        ? _save
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
