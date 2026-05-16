// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/constant.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

class ExternalLink {
  static Future<bool> _tryLaunch(
    Uri uri, {
    required BuildContext context,
    String? failureMessage,
  }) async {
    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        debugPrint('launchUrl returned false (system refused): $uri');
        _showFailureSnackbar(
          context,
          failureMessage ?? 'Could not open the link. Please try again.',
        );
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('launchUrl failed: $e  →  URI: $uri');
      _showFailureSnackbar(
        context,
        failureMessage ?? 'Failed to open link: $e',
      );
      return false;
    }
  }

  static void _showFailureSnackbar(BuildContext context, String message) {
    showCustomSnackbar(
      context: context,
      message: message,
      isError: true,
      // backgroundColor: AppColors.errorColor, // already default in your showCustomSnackbar
    );
  }

  static Future<void> launchAdminUrl(
    String baseUrl, {
    required BuildContext context,
    bool isTokenNeeded = false,
  }) async {
    final token = HiveStorage.userToken;

    if (token == null || token.isEmpty) {
      debugPrint("No token available — user not logged in?");
      _showFailureSnackbar(context, 'Please log in to access this feature.');
      return;
    }

    debugPrint('Token retrieved');

    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        ...Uri.parse(baseUrl).queryParameters,
        if (isTokenNeeded) 'token': token,
      },
    );

    debugPrint('Launching admin URL: $uri');

    final success = await _tryLaunch(
      uri,
      context: context,
      failureMessage: 'Could not open admin panel. Please try again.',
    );

    if (!success) {
      debugPrint('Failed to open external browser for admin URL');
    }
  }

  static Future<void> showVideo(
    String url, {
    required BuildContext context,
  }) async {
    if (url.isEmpty) {
      debugPrint('Empty video URL');
      _showFailureSnackbar(context, 'No video link available.');
      return;
    }

    final uri = Uri.parse(url.trim());

    if (!['http', 'https'].contains(uri.scheme)) {
      debugPrint('Invalid scheme for video: $uri');
      _showFailureSnackbar(context, 'Invalid video link format.');
      return;
    }

    try {
      // 1. Prefer external app if possible
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        debugPrint('externalApplication failed → fallback to in-app browser');

        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);

        if (!launched) {
          debugPrint('All launch attempts failed for: $url');
          _showFailureSnackbar(context, 'Could not play the video.');
        }
      }
    } catch (e) {
      debugPrint('launchUrl exception: $e  URL: $url');
      _showFailureSnackbar(context, 'Failed to open video: $e');
    }
  }

  static Future<void> toStoreConfiguration(
    BuildContext context,
    String storeId,
  ) async {
    final url =
        '${AppConstants.domainUrl}/seller/stores/$storeId/configuration';
    await launchAdminUrl(url, context: context, isTokenNeeded: true);
  }

  static Future<void> makePhoneCall(
    BuildContext context,
    String? phoneNumber,
  ) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      debugPrint('No phone number provided');
      _showFailureSnackbar(context, 'No phone number available.');
      return;
    }

    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]+'), '');
    if (cleanNumber.isEmpty) {
      debugPrint('Invalid phone number after cleaning');
      _showFailureSnackbar(context, 'Invalid phone number format.');
      return;
    }

    final Uri telUri = Uri(scheme: 'tel', path: cleanNumber);

    debugPrint('Attempting to dial: $telUri');

    final success = await _tryLaunch(
      telUri,
      context: context,
      failureMessage: 'Could not open phone dialer.',
    );

    if (!success) {
      debugPrint('Failed to open dialer');
    }
  }
}
