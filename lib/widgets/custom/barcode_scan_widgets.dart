import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Building blocks shared by the barcode scanners: the incoming-order scan
/// panel and the product scan dialog.

/// First non-empty barcode value in [capture], or null.
String? firstBarcodeValue(BarcodeCapture capture) {
  for (final barcode in capture.barcodes) {
    final value = barcode.rawValue?.trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return null;
}

/// Live camera with an aiming frame and a flashlight button.
class ScanCameraView extends StatelessWidget {
  final MobileScannerController controller;
  final void Function(BarcodeCapture capture) onDetect;
  final VoidCallback onManualEntry;
  final String hint;

  const ScanCameraView({
    super.key,
    required this.controller,
    required this.onDetect,
    required this.onManualEntry,
    this.hint = "Point the camera at the product's barcode.",
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 280,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: onDetect,
                  errorBuilder: (context, error) => ScanCameraError(
                    permissionDenied:
                        error.errorCode ==
                        MobileScannerErrorCode.permissionDenied,
                    onManualEntry: onManualEntry,
                  ),
                ),
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 240,
                      height: 130,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filledTonal(
                    tooltip: 'Flashlight',
                    onPressed: controller.toggleTorch,
                    icon: const Icon(Icons.flashlight_on_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          hint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class ScanCodeBox extends StatelessWidget {
  final String label;
  final String code;

  const ScanCodeBox({super.key, required this.label, required this.code});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkProductCardColor
            : AppColors.mainLightContainerBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              code,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScanCameraError extends StatelessWidget {
  final bool permissionDenied;
  final VoidCallback onManualEntry;

  const ScanCameraError({
    super.key,
    required this.permissionDenied,
    required this.onManualEntry,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white70),
            const SizedBox(height: 10),
            Text(
              permissionDenied
                  ? 'Camera access is off. Allow it in Settings, or enter the code manually.'
                  : "The camera isn't available. Enter the code manually.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (permissionDenied)
                  TextButton(
                    onPressed: () => AppSettings.openAppSettings(),
                    child: const Text('Open settings'),
                  ),
                TextButton(
                  onPressed: onManualEntry,
                  child: const Text('Enter manually'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ScanErrorText extends StatelessWidget {
  final String message;

  const ScanErrorText(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: Colors.red.shade600),
    );
  }
}

class ScanBottomBar extends StatelessWidget {
  final Widget child;

  const ScanBottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkProductCardColor
            : AppColors.mainLightContainerBgColor,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Decoration for the typed-barcode field. The light theme's primary colour
/// is the pale container colour, which a focused field would otherwise use
/// for its label and border.
InputDecoration scanCodeFieldDecoration(
  BuildContext context, {
  String? errorText,
}) {
  final color = scanFieldColor(context);
  final hint = Theme.of(context).hintColor;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: 'Barcode',
    labelStyle: TextStyle(color: hint),
    floatingLabelStyle: WidgetStateTextStyle.resolveWith(
      (states) => TextStyle(
        color: states.contains(WidgetState.error)
            ? Colors.red.shade600
            : color,
      ),
    ),
    prefixIcon: const Icon(Icons.keyboard_outlined),
    prefixIconColor: color,
    errorText: errorText,
    errorMaxLines: 3,
    border: border(Colors.grey.shade400),
    enabledBorder: border(Colors.grey.shade400),
    focusedBorder: border(color, 1.5),
  );
}

/// Text, cursor and focus colour for the typed-barcode field.
Color scanFieldColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? Colors.white
    : Colors.black;

/// Outlined style for the left-hand scan buttons. The light theme's primary
/// colour is the pale container colour, which OutlinedButton would otherwise
/// use for its text and icon.
ButtonStyle _outlinedScanStyle(BuildContext context, {EdgeInsets? padding}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return OutlinedButton.styleFrom(
    foregroundColor: isDark ? Colors.white : Colors.black,
    side: BorderSide(
      color: isDark ? AppColors.darkOutline : Colors.grey.shade400,
    ),
    padding: padding,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

class ScanManualEntryButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ScanManualEntryButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: _outlinedScanStyle(context, padding: EdgeInsets.zero),
        child: const Tooltip(
          message: 'Enter code manually',
          child: Icon(Icons.keyboard_outlined),
        ),
      ),
    );
  }
}

class ScanPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const ScanPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.primaryColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading ? const SizedBox.shrink() : Icon(icon),
        label: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.7),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class ScanSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const ScanSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: _outlinedScanStyle(context),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Blue title bar with a close button, shared by the scanner dialogs.
class ScanDialogHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const ScanDialogHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryColor,
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
