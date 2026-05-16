import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_state.dart';
import 'package:hyper_local_seller/utils/validator_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_bloc.dart';

class LocationDetailsStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const LocationDetailsStep({super.key, required this.formKey});

  @override
  State<LocationDetailsStep> createState() => _LocationDetailsStepState();
}

class _LocationDetailsStepState extends State<LocationDetailsStep> {
  final TextEditingController _countryController = TextEditingController(
    text: "India",
  );
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();

  final FocusNode countryNode = FocusNode();
  final FocusNode addressNode = FocusNode();
  final FocusNode landmarkNode = FocusNode();
  final FocusNode cityNode = FocusNode();
  final FocusNode stateNode = FocusNode();
  final FocusNode zipCodeNode = FocusNode();

  bool _isLoading = false;
  bool _isSyncing = false;

  @override
  void dispose() {
    countryNode.dispose();
    addressNode.dispose();
    landmarkNode.dispose();
    cityNode.dispose();
    stateNode.dispose();
    zipCodeNode.dispose();
    _countryController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _latController.dispose();
    _longController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final formData = context.read<AddStoreBloc>().state.formData;
    _syncWithFormData(formData);

    _countryController.addListener(_updateBloc);
    _addressController.addListener(_updateBloc);
    _landmarkController.addListener(_updateBloc);
    _cityController.addListener(_updateBloc);
    _stateController.addListener(_updateBloc);
    _zipCodeController.addListener(_updateBloc);
  }

  void _syncWithFormData(Map<String, dynamic> data) {
    _isSyncing = true;
    if (data['country'] != _countryController.text) {
      _countryController.text = data['country'] ?? 'India';
    }
    if (data['address'] != _addressController.text) {
      _addressController.text = data['address'] ?? '';
    }
    if (data['landmark'] != _landmarkController.text) {
      _landmarkController.text = data['landmark'] ?? '';
    }
    if (data['city'] != _cityController.text) {
      _cityController.text = data['city'] ?? '';
    }
    if (data['state'] != _stateController.text) {
      _stateController.text = data['state'] ?? '';
    }
    if (data['zipcode'] != _zipCodeController.text) {
      _zipCodeController.text = data['zipcode'] ?? '';
    }

    final latStr = data['latitude']?.toString() ?? '';
    if (latStr != _latController.text) {
      _latController.text = latStr;
    }

    final longStr = data['longitude']?.toString() ?? '';
    if (longStr != _longController.text) {
      _longController.text = longStr;
    }
    _isSyncing = false;
  }

  void _updateBloc() {
    if (_isSyncing) return;
    context.read<AddStoreBloc>().add(
      UpdateStoreField({
        'country': _countryController.text,
        'address': _addressController.text,
        'landmark': _landmarkController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zipcode': _zipCodeController.text,
      }),
    );
  }

  Future<void> _autoFetchLocation() async {
    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showError(
              AppLocalizations.of(context)?.locationPermissionDenied ??
                  'Location permission denied',
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showError(
            AppLocalizations.of(context)?.locationPermissionPermanentlyDenied ??
                'Location permissions are permanently denied',
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _addressController.text = [
            place.street,
            place.subLocality,
            place.locality,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          _landmarkController.text = place.subLocality ?? '';
          _cityController.text = place.locality ?? '';
          _stateController.text = place.administrativeArea ?? '';
          _zipCodeController.text = place.postalCode ?? '';
          _countryController.text = place.country ?? '';

          context.read<AddStoreBloc>().add(
            UpdateStoreField({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'country': place.country ?? '',
              'address': _addressController.text,
              'landmark': place.subLocality ?? '',
              'city': place.locality ?? '',
              'state': place.administrativeArea ?? '',
              'zipcode': place.postalCode ?? '',
            }),
          );
          if (mounted) {
            showCustomSnackbar(
              context: context,
              message:
                  AppLocalizations.of(context)?.locationFetchedSuccessfully ??
                  'Location fetched successfully!',
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showError(
          AppLocalizations.of(
                context,
              )?.failedToGetLocationWithDetail(e.toString()) ??
              'Failed to get location: $e',
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openMapScreen() async {
    final formData = context.read<AddStoreBloc>().state.formData;
    final latitude = formData['latitude'] != null
        ? double.tryParse(formData['latitude'].toString())
        : null;
    final longitude = formData['longitude'] != null
        ? double.tryParse(formData['longitude'].toString())
        : null;

    final result = await context.push<Map<String, dynamic>>(
      AppRoutes.mapScreen,
      extra: {'latitude': latitude, 'longitude': longitude},
    );
    if (result != null && mounted) {
      setState(() {
        log('result :: $result');
        _landmarkController.text = result['landmark'] ?? '';
        _addressController.text = result['address'] ?? '';
        _cityController.text = result['city'] ?? '';
        _stateController.text = result['state'] ?? '';
        _zipCodeController.text = result['zipCode'] ?? '';
        _countryController.text = result['country'] ?? '';

        context.read<AddStoreBloc>().add(
          UpdateStoreField({
            'latitude': result['latitude'],
            'longitude': result['longitude'],
            'landmark': result['landmark'] ?? '',
            'address': result['address'] ?? '',
            'city': result['city'] ?? '',
            'state': result['state'] ?? '',
            'zipcode': result['zipCode'] ?? '',
            'country': result['country'] ?? '',
          }),
        );
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      showCustomSnackbar(context: context, message: message, isError: true);
    }
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
            Row(
              children: [
                Expanded(
                  child: _isLoading
                      ? const Center(child: CustomLoadingIndicator())
                      : SecondaryButton(
                          text: l10n?.autoFetch ?? "Auto Fetch",
                          icon: Icons.my_location,
                          onPressed: _autoFetchLocation,
                          height: 45,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: l10n?.fromMap ?? "From Map",
                    icon: Icons.location_on_rounded,
                    onPressed: _openMapScreen,
                    height: 45,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.country ?? "Country",
              isRequired: true,
              hint: "India",
              controller: _countryController,
              readOnly: true,
              suffixIcon: const Icon(Icons.keyboard_arrow_down),
              validator: (value) =>
                  ValidatorUtils.validateEmpty(context, value),
              focusNode: countryNode,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.address ?? "Address",
              isRequired: true,
              hint: l10n?.enterAddress ?? "Enter Address",
              controller: _addressController,
              maxLines: 3,
              validator: (value) =>
                  ValidatorUtils.validateEmpty(context, value),
              focusNode: addressNode,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.landmark ?? "Landmark",
              hint: "XYZ Area",
              isRequired: true,
              controller: _landmarkController,
              validator: (value) =>
                  ValidatorUtils.validateEmpty(context, value),
              focusNode: landmarkNode,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.city ?? "City",
              isRequired: true,
              hint: "Bhuj",
              controller: _cityController,
              validator: (value) =>
                  ValidatorUtils.validateEmpty(context, value),
              focusNode: cityNode,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.state ?? "State",
              isRequired: true,
              hint: "Gujarat",
              controller: _stateController,
              validator: (value) =>
                  ValidatorUtils.validateEmpty(context, value),
              focusNode: stateNode,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: l10n?.zipCode ?? "Zip code",
              isRequired: true,
              hint: "370001",
              controller: _zipCodeController,
              keyboardType: TextInputType.number,
              validator: (value) =>
                  ValidatorUtils.validateEmpty(context, value),
              focusNode: zipCodeNode,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    hint: "Lat",
                    readOnly: true,
                    controller: _latController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    hint: "Long",
                    readOnly: true,
                    controller: _longController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
