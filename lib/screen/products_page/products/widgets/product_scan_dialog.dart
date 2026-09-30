import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/widgets/custom/barcode_scan_widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Opens the product scanner and, when a product is found, its details page.
Future<void> openProductScanner(BuildContext context) async {
  final product = await showDialog<Product>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: const ProductScanDialog(),
      ),
    ),
  );
  if (product != null && context.mounted) {
    context.push(AppRoutes.productDetails, extra: product);
  }
}

enum _Mode { camera, manual, review }

/// Reads a barcode for a product form without looking up an existing product.
Future<String?> scanProductBarcode(BuildContext context) => showDialog<String>(
  context: context,
  builder: (_) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: const ProductScanDialog(returnBarcode: true),
    ),
  ),
);

/// Scans (or takes a typed) product barcode, looks the product up and pops
/// with it.
class ProductScanDialog extends StatefulWidget {
  /// Product forms need the confirmed code, including codes for new products.
  final bool returnBarcode;
  @visibleForTesting
  final ProductsRepo? repo;

  @visibleForTesting
  final Widget Function(void Function(String code, Uint8List? image) onCode)?
  cameraBuilder;

  const ProductScanDialog({
    super.key,
    this.repo,
    this.cameraBuilder,
    this.returnBarcode = false,
  });

  @override
  State<ProductScanDialog> createState() => _ProductScanDialogState();
}

class _ProductScanDialogState extends State<ProductScanDialog> {
  _Mode _mode = _Mode.camera;
  MobileScannerController? _scanner;
  final _codeController = TextEditingController();

  /// Code read by the camera, waiting for the seller to confirm it.
  String? _scannedCode;
  Uint8List? _scannedImage;
  bool _isSearching = false;
  String? _error;

  late final ProductsRepo _repo = widget.repo ?? ProductsRepo();

  @override
  void initState() {
    super.initState();
    if (widget.cameraBuilder == null) {
      _scanner = MobileScannerController(returnImage: true);
    }
  }

  @override
  void dispose() {
    _scanner?.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _go(_Mode mode) {
    if (mode == _Mode.camera && widget.cameraBuilder == null) {
      _scanner ??= MobileScannerController(returnImage: true);
    } else {
      _scanner?.dispose();
      _scanner = null;
    }
    if (mode == _Mode.manual) _codeController.clear();
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_mode != _Mode.camera) return;
    final code = firstBarcodeValue(capture);
    if (code == null) return;
    _onCode(code, capture.image);
  }

  void _onCode(String code, Uint8List? image) {
    if (!mounted || _mode != _Mode.camera || code.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    _scannedCode = code.trim();
    _scannedImage = image;
    _go(_Mode.review);
  }

  /// Finds the product for [code]. The barcode endpoint returns the public
  /// product resource, so the seller resource is fetched by id for the
  /// details page, which expects that shape.
  Future<void> _search(String code) async {
    final barcode = code.trim();
    if (barcode.isEmpty) {
      setState(() => _error = 'Enter a barcode');
      return;
    }
    if (widget.returnBarcode) {
      Navigator.of(context).pop(barcode);
      return;
    }
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final found = await _repo.getProductByBarcode(barcode);
      final id = found['data']?['product']?['id'];
      if (id is! int) throw ApiException('Product not found', statusCode: 404);
      final response = await _repo.getProductById(id);
      if (response['success'] != true || response['data'] == null) {
        throw ApiException('Product not found', statusCode: 404);
      }
      final product = Product.fromJson(response['data']);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(product);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _error = e is ApiException && e.statusCode == 404
            ? 'No product found with barcode $barcode.'
            : "Couldn't look up the product. $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? AppColors.darkSubCategoryCardColor : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            title: switch (_mode) {
              _Mode.camera =>
                widget.returnBarcode ? 'Scan barcode' : 'Scan product',
              _Mode.manual => 'Enter barcode',
              _Mode.review => 'Is this code correct?',
            },
            onClose: () => Navigator.of(context).pop(),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: switch (_mode) {
                _Mode.camera => _buildCamera(),
                _Mode.manual => _buildManual(),
                _Mode.review => _buildReview(),
              },
            ),
          ),
          ScanBottomBar(
            child: switch (_mode) {
              _Mode.camera => _buildCameraActions(),
              _Mode.manual => _buildManualActions(),
              _Mode.review => _buildReviewActions(),
            },
          ),
        ],
      ),
    );
  }

  // ── Camera ─────────────────────────────────────────────────────────────

  Widget _buildCamera() {
    if (widget.cameraBuilder != null) return widget.cameraBuilder!(_onCode);
    return ScanCameraView(
      controller: _scanner!,
      onDetect: _onDetect,
      onManualEntry: () => _go(_Mode.manual),
    );
  }

  Widget _buildCameraActions() {
    return Row(
      children: [
        ScanManualEntryButton(onPressed: () => _go(_Mode.manual)),
        const SizedBox(width: 10),
        Expanded(
          child: ScanSecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  // ── Review a camera scan ───────────────────────────────────────────────

  Widget _buildReview() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 200,
            color: Colors.black,
            child: _scannedImage != null
                ? Image.memory(_scannedImage!, fit: BoxFit.contain)
                : const Icon(Icons.qr_code_2, color: Colors.white70, size: 64),
          ),
        ),
        const SizedBox(height: 12),
        ScanCodeBox(label: 'Detected code', code: _scannedCode ?? ''),
        if (_error != null) ...[
          const SizedBox(height: 10),
          ScanErrorText(_error!),
        ],
        const SizedBox(height: 4),
        Text(
          widget.returnBarcode
              ? 'Confirm to use this barcode, or retake the scan.'
              : 'Confirm to find the product, or retake the scan.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  Widget _buildReviewActions() {
    return Row(
      children: [
        Expanded(
          child: ScanSecondaryButton(
            label: 'Retake',
            onPressed: _isSearching ? null : () => _go(_Mode.camera),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ScanPrimaryButton(
            label: 'Confirm',
            icon: Icons.check,
            color: Colors.green.shade600,
            isLoading: _isSearching,
            onPressed: () => _search(_scannedCode ?? ''),
          ),
        ),
      ],
    );
  }

  // ── Manual entry ───────────────────────────────────────────────────────

  Widget _buildManual() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Type the code printed under the product's barcode.",
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _codeController,
          autofocus: true,
          enabled: !_isSearching,
          textInputAction: widget.returnBarcode
              ? TextInputAction.done
              : TextInputAction.search,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: _search,
          cursorColor: scanFieldColor(context),
          decoration: scanCodeFieldDecoration(context, errorText: _error),
        ),
      ],
    );
  }

  Widget _buildManualActions() {
    return Row(
      children: [
        Expanded(
          child: ScanSecondaryButton(
            label: 'Scan instead',
            onPressed: _isSearching ? null : () => _go(_Mode.camera),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ScanPrimaryButton(
            label: widget.returnBarcode ? 'Use barcode' : 'Search',
            icon: widget.returnBarcode ? Icons.check : Icons.search,
            isLoading: _isSearching,
            onPressed: () => _search(_codeController.text),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _Header({required this.title, required this.onClose});

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
