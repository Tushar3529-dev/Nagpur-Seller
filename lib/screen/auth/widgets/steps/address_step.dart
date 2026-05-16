// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/utils/validator_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class BusinessAddressStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController addressController;
  final TextEditingController landmarkController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController countryController;
  final TextEditingController zipCodeController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;

  final FocusNode addressNode;
  final FocusNode landmarkNode;
  final FocusNode cityNode;
  final FocusNode stateNode;
  final FocusNode countryNode;
  final FocusNode zipCodeNode;

  const BusinessAddressStep({
    super.key,
    required this.formKey,
    required this.addressController,
    required this.landmarkController,
    required this.cityController,
    required this.stateController,
    required this.countryController,
    required this.zipCodeController,
    required this.latitudeController,
    required this.longitudeController,
    required this.addressNode,
    required this.landmarkNode,
    required this.cityNode,
    required this.stateNode,
    required this.countryNode,
    required this.zipCodeNode,
  });

  @override
  State<BusinessAddressStep> createState() => _BusinessAddressStepState();
}

class _BusinessAddressStepState extends State<BusinessAddressStep> {
  bool _isLoading = false;

  Future<void> _autoFetchLocation(AppLocalizations? l10n) async {
    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError(
            l10n?.locationPermissionDenied ?? 'Location permission denied',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError(
          l10n?.locationPermissionPermanentlyDenied ??
              'Location permissions are permanently denied',
        );
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
          widget.addressController.text = [
            place.street,
            place.subLocality,
            place.locality,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          widget.landmarkController.text = place.subLocality ?? '';
          widget.cityController.text = place.locality ?? '';
          widget.stateController.text = place.administrativeArea ?? '';
          widget.zipCodeController.text = place.postalCode ?? '';
          widget.latitudeController.text = position.latitude.toStringAsFixed(6);
          widget.longitudeController.text = position.longitude.toStringAsFixed(
            6,
          );
          widget.countryController.text = place.country ?? '';
          if (mounted) {
            showCustomSnackbar(
              context: context,
              message:
                  l10n?.locationFetchedSuccess ??
                  'Location fetched successfully!',
            );
          }
        });
      }
    } catch (e) {
      _showError(l10n?.failedToGetLocation ?? 'Failed to get location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openMapScreen() async {
    // Option A: Try to use existing values first
    double? lat = double.tryParse(widget.latitudeController.text);
    double? lng = double.tryParse(widget.longitudeController.text);

    // If we don't have valid coordinates yet → try to auto-fetch once
    if (lat == null || lng == null || lat == 0 || lng == 0) {
      setState(() => _isLoading = true);
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        lat = position.latitude;
        lng = position.longitude;

        // Optional: also fill the fields right away (better UX)
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          widget.addressController.text = [
            place.street,
            place.subLocality,
            place.locality,
          ].where((e) => e?.isNotEmpty ?? false).join(', ');
          widget.landmarkController.text = place.subLocality ?? '';
          widget.cityController.text = place.locality ?? '';
          widget.stateController.text = place.administrativeArea ?? '';
          widget.zipCodeController.text = place.postalCode ?? '';
          widget.countryController.text = place.country ?? '';
          widget.latitudeController.text = lat.toStringAsFixed(6);
          widget.longitudeController.text = lng.toStringAsFixed(6);
        }
      } catch (e) {
        _showError('Could not get current location: $e\nMap will open anyway.');
        // continue anyway — map screen has fallback
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

    // Now open map (with best available coordinates or null)
    final result = await context.push<Map<String, dynamic>>(
      AppRoutes.mapScreen,
      extra: {'latitude': lat, 'longitude': lng},
    );

    if (result != null && mounted) {
      setState(() {
        widget.addressController.text = result['address'] ?? '';
        widget.cityController.text = result['city'] ?? '';
        widget.stateController.text = result['state'] ?? '';
        widget.zipCodeController.text = result['zipCode'] ?? '';
        widget.latitudeController.text = result['latitude']?.toString() ?? '';
        widget.longitudeController.text = result['longitude']?.toString() ?? '';
        widget.countryController.text = result['country'] ?? '';
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field with location icon
          Row(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CustomLoadingIndicator())
                    : SecondaryButton(
                        text: l10n?.autoFetch ?? "Auto Fetch",
                        icon: Icons.my_location,
                        onPressed: () => _autoFetchLocation(l10n),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: l10n?.fromMap ?? "From Map",
                  icon: Icons.location_on_rounded,
                  onPressed: _openMapScreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: l10n?.address ?? "Address",
            isRequired: true,
            hint: "e.g. 123, Shree Complex, Station Road",
            controller: widget.addressController,
            validator: (value) => ValidatorUtils.validateEmpty(context, value),
            focusNode: widget.addressNode,
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: l10n?.city ?? "City",
            isRequired: true,
            hint: "e.g. Bhuj",
            controller: widget.cityController,
            validator: (value) => ValidatorUtils.validateEmpty(context, value),
            focusNode: widget.cityNode,
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: l10n?.landmark ?? "Landmark",
            isRequired: true,
            hint: "e.g. Near Bus Stand",
            controller: widget.landmarkController,
            validator: (value) => ValidatorUtils.validateEmpty(context, value),
            focusNode: widget.landmarkNode,
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: l10n?.state ?? "State",
            isRequired: true,
            hint: "e.g. Gujarat",
            controller: widget.stateController,
            validator: (value) => ValidatorUtils.validateEmpty(context, value),
            focusNode: widget.stateNode,
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: l10n?.zipCode ?? "Zipcode",
            isRequired: true,
            hint: "e.g. 370001",
            controller: widget.zipCodeController,
            keyboardType: TextInputType.number,
            validator: (value) => ValidatorUtils.validateEmpty(context, value),
            focusNode: widget.zipCodeNode,
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: l10n?.country ?? "Country",
            hint: "e.g. India",
            isRequired: true,
            controller: widget.countryController,
            validator: (value) => ValidatorUtils.validateEmpty(context, value),
            focusNode: widget.countryNode,
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: l10n?.latitude ?? "Latitude",
            hint: "e.g. 23.241999",
            isRequired: true,
            controller: widget.latitudeController,
            keyboardType: TextInputType.number,
            readOnly: true,
            validator: (value) => ValidatorUtils.validateEmpty(context, value),
          ),
          const SizedBox(height: 20),

          CustomTextField(
            label: l10n?.longitude ?? "Longitude",
            hint: "e.g. 69.666881",
            isRequired: true,
            controller: widget.longitudeController,
            keyboardType: TextInputType.number,
            readOnly: true,
            validator: (value) => ValidatorUtils.validateEmpty(context, value),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
