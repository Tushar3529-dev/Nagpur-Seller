import 'dart:math' as math;

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Building blocks shared by the barcode scanners: the incoming-order scan
/// panel, the product scan dialog and the bag scanner. They all open full
/// screen.

/// First non-empty barcode value in [capture], or null.
String? firstBarcodeValue(BarcodeCapture capture) {
  for (final barcode in capture.barcodes) {
    final value = barcode.rawValue?.trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return null;
}

/// Full-screen live camera: everything outside the scan window is dimmed,
/// the window has corner marks and a red aiming line, and only barcodes
/// inside the window are read. The flashlight button sits under the window.
class ScanCameraView extends StatelessWidget {
  final MobileScannerController? controller;
  final void Function(BarcodeCapture capture)? onDetect;
  final VoidCallback onManualEntry;
  final String hint;

  /// Stands in for the live camera (tests).
  final Widget? preview;

  /// Pinned to the bottom of the camera, e.g. a summary of scanned codes.
  final Widget? footer;

  const ScanCameraView({
    super.key,
    this.controller,
    this.onDetect,
    required this.onManualEntry,
    this.hint = "Point the camera at the product's barcode.",
    this.preview,
    this.footer,
  });

  /// Scan window for a camera of [size]: wide and short like a barcode,
  /// a little above the middle.
  static Rect windowFor(Size size) {
    final width = math.min(size.width * 0.82, 420.0);
    final height = math.min(width * 0.62, size.height * 0.4);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: width,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final window = windowFor(constraints.biggest);
        final overlays = <Widget>[
          IgnorePointer(
            child: CustomPaint(painter: _ScanWindowPainter(window)),
          ),
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Center(child: _ScanHint(hint)),
          ),
          if (controller != null)
            Positioned(
              top: window.bottom + 14,
              left: 0,
              right: 0,
              child: Center(
                child: IconButton.filledTonal(
                  tooltip: 'Flashlight',
                  onPressed: controller!.toggleTorch,
                  icon: const Icon(Icons.flashlight_on_outlined),
                ),
              ),
            ),
        ];
        return ClipRect(
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                preview ??
                    MobileScanner(
                      controller: controller,
                      onDetect: onDetect,
                      scanWindow: window,
                      errorBuilder: (context, error) => ScanCameraError(
                        permissionDenied:
                            error.errorCode ==
                            MobileScannerErrorCode.permissionDenied,
                        onManualEntry: onManualEntry,
                      ),
                    ),
                // No aiming marks over the camera error and its buttons.
                if (controller == null)
                  ...overlays
                else
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: controller!,
                    builder: (context, state, _) => state.error != null
                        ? const SizedBox.shrink()
                        : Stack(fit: StackFit.expand, children: overlays),
                  ),
                if (footer != null)
                  Positioned(left: 12, right: 12, bottom: 12, child: footer!),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScanHint extends StatelessWidget {
  final String text;

  const _ScanHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanWindowPainter extends CustomPainter {
  final Rect window;

  const _ScanWindowPainter(this.window);

  @override
  void paint(Canvas canvas, Size size) {
    final rounded = RRect.fromRectAndRadius(window, const Radius.circular(4));
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(rounded),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    final corner = Paint()
      ..color = const Color(0xFF2F6BFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;
    const arm = 24.0;
    final w = window;
    for (final (point, dx, dy) in [
      (w.topLeft, 1.0, 1.0),
      (w.topRight, -1.0, 1.0),
      (w.bottomLeft, 1.0, -1.0),
      (w.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(point, point.translate(arm * dx, 0), corner)
        ..drawLine(point, point.translate(0, arm * dy), corner);
    }

    canvas.drawLine(
      Offset(w.left + 10, w.center.dy),
      Offset(w.right - 10, w.center.dy),
      Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_ScanWindowPainter oldDelegate) =>
      oldDelegate.window != window;
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
      child: SafeArea(top: false, child: child),
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
        color: states.contains(WidgetState.error) ? Colors.red.shade600 : color,
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
      child: SafeArea(
        bottom: false,
        child: Padding(
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
        ),
      ),
    );
  }
}

/// Opens a scanner dialog that covers the whole screen.
Future<T?> showFullScreenScanner<T>(
  BuildContext context,
  Widget scanner, {
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  useSafeArea: false,
  barrierDismissible: barrierDismissible,
  builder: (_) => Dialog.fullscreen(child: scanner),
);
