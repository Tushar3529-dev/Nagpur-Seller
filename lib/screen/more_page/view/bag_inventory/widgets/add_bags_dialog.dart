import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/model/bag_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/repo/bags_repo.dart';
import 'package:hyper_local_seller/widgets/custom/barcode_scan_widgets.dart';
import 'package:hyper_local_seller/widgets/custom/custom_alert_dialog.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Opens the bag scanner. Completes with true when bags were sent to the
/// server, so the caller can reload its list.
Future<bool> openAddBagsDialog(BuildContext context, {BagsRepo? repo}) async {
  final added = await showFullScreenScanner<bool>(
    context,
    AddBagsDialog(repo: repo),
    barrierDismissible: false,
  );
  return added ?? false;
}

enum _Mode { camera, manual, review, list, result }

/// Scans bag barcodes one at a time into a list, lets the seller check and
/// trim that list, then adds every barcode in a single bulk request.
class AddBagsDialog extends StatefulWidget {
  @visibleForTesting
  final BagsRepo? repo;

  @visibleForTesting
  final Widget Function(void Function(String code, Uint8List? image) onCode)?
  cameraBuilder;

  const AddBagsDialog({super.key, this.repo, this.cameraBuilder});

  @override
  State<AddBagsDialog> createState() => _AddBagsDialogState();
}

class _AddBagsDialogState extends State<AddBagsDialog> {
  _Mode _mode = _Mode.camera;
  MobileScannerController? _scanner;
  final _codeController = TextEditingController();

  /// Barcodes waiting to be sent, in scan order.
  final List<String> _queue = [];

  /// Code read by the camera, waiting for the seller to save or retake it.
  String? _scannedCode;
  Uint8List? _scannedImage;

  /// The camera usually still sees the bag that was just saved, so that code
  /// is ignored instead of being reported as a duplicate.
  String? _lastSaved;

  /// Short status line under the camera or the manual entry field.
  String? _notice;
  String? _error;
  bool _isSubmitting = false;
  BulkAddBagsResult? _result;

  late final BagsRepo _repo = widget.repo ?? BagsRepo();

  bool get _isFull => _queue.length >= BagsRepo.maxBulkBarcodes;

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
      if (mode != _Mode.camera && mode != _Mode.manual) _notice = null;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    final code = firstBarcodeValue(capture);
    if (code == null) return;
    _onCode(code, capture.image);
  }

  void _onCode(String rawCode, Uint8List? image) {
    final code = rawCode.trim();
    if (!mounted || _mode != _Mode.camera || code.isEmpty) return;
    if (_queue.contains(code)) {
      final notice = '$code is already in your list.';
      if (code != _lastSaved && _notice != notice) {
        setState(() => _notice = notice);
      }
      return;
    }
    if (_isFull) {
      setState(() => _notice = _fullNotice);
      return;
    }
    HapticFeedback.mediumImpact();
    _scannedCode = code;
    _scannedImage = image;
    _go(_Mode.review);
  }

  String get _fullNotice =>
      'You can add up to ${BagsRepo.maxBulkBarcodes} bags at a time. '
      'Confirm these first.';

  void _saveScanned({required bool finish}) {
    final code = _scannedCode;
    if (code != null && !_queue.contains(code) && !_isFull) {
      _queue.add(code);
      _lastSaved = code;
    }
    _scannedCode = null;
    _scannedImage = null;
    _notice = null;
    _go(finish ? _Mode.list : _Mode.camera);
  }

  /// Adds every code typed into the manual field. Several codes can be
  /// separated by commas, semicolons or new lines.
  void _addTyped() {
    final codes = _codeController.text
        .split(RegExp(r'[,;\n]'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toSet();
    if (codes.isEmpty) {
      setState(() => _error = 'Enter a barcode');
      return;
    }
    var added = 0;
    var skipped = 0;
    for (final code in codes) {
      if (_queue.contains(code)) {
        skipped++;
      } else if (!_isFull) {
        _queue.add(code);
        added++;
      }
    }
    final notFitting = codes.length - added - skipped;
    _codeController.clear();
    setState(() {
      _error = null;
      _notice = [
        'Added $added ${added == 1 ? 'bag' : 'bags'}.',
        if (skipped > 0) '$skipped already in your list.',
        if (notFitting > 0) _fullNotice,
      ].join(' ');
    });
  }

  void _remove(String code) {
    setState(() {
      _queue.remove(code);
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting || _queue.isEmpty) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final result = await _repo.addBags(List.of(_queue));
      if (!mounted) return;
      HapticFeedback.lightImpact();
      _queue.clear();
      _result = result;
      _isSubmitting = false;
      _go(_Mode.result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = "Couldn't add the bags. $e";
      });
    }
  }

  /// Closing with scanned bags that haven't been sent asks first.
  void _close() {
    if (_isSubmitting) return;
    if (_mode == _Mode.result) {
      Navigator.of(context).pop(true);
      return;
    }
    if (_queue.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    final count = _queue.length;
    showAppAlertDialog(
      context: context,
      title: 'Discard scanned bags?',
      message:
          "The $count ${count == 1 ? 'barcode' : 'barcodes'} in your list "
          "haven't been added yet.",
      confirmText: 'Discard',
      cancelText: 'Keep scanning',
      isDestructive: true,
      onConfirm: () {
        if (mounted) Navigator.of(context).pop(false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: ColoredBox(
        color: isDark ? AppColors.darkSubCategoryCardColor : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScanDialogHeader(
              title: switch (_mode) {
                _Mode.camera => 'Scan bags',
                _Mode.manual => 'Enter barcodes',
                _Mode.review => 'Is this code correct?',
                _Mode.list =>
                  'Review ${_queue.length} '
                      '${_queue.length == 1 ? 'bag' : 'bags'}',
                _Mode.result => 'Bags added',
              },
              onClose: _close,
            ),
            Expanded(
              child: switch (_mode) {
                _Mode.camera => _buildCamera(),
                _Mode.list => _buildList(),
                _ => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: switch (_mode) {
                    _Mode.manual => _buildManual(),
                    _Mode.review => _buildReview(),
                    _Mode.result => _buildResult(),
                    _ => const SizedBox.shrink(),
                  },
                ),
              },
            ),
            ScanBottomBar(
              child: switch (_mode) {
                _Mode.camera => _buildCameraActions(),
                _Mode.manual => _buildManualActions(),
                _Mode.review => _buildReviewActions(),
                _Mode.list => _buildListActions(),
                _Mode.result => ScanPrimaryButton(
                  label: 'Done',
                  icon: Icons.check,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  /// "6 bags in list · Review", shown while scanning or typing.
  Widget _buildQueueBar({bool topGap = true}) {
    if (_queue.isEmpty) return const SizedBox.shrink();
    final count = _queue.length;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark ? Colors.white : AppColors.primaryColor;
    return Padding(
      padding: EdgeInsets.only(top: topGap ? 12 : 0),
      child: Material(
        color: AppColors.primaryColor.withValues(alpha: isDark ? 0.25 : 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _go(_Mode.list),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.checklist_rounded, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$count ${count == 1 ? 'bag' : 'bags'} in list',
                    style: theme.textTheme.bodyMedium?.copyWith(color: color),
                  ),
                ),
                Text(
                  'Review',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(Icons.chevron_right, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotice() {
    if (_notice == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        _notice!,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.orange.shade800,
        ),
      ),
    );
  }

  // ── Camera ─────────────────────────────────────────────────────────────

  Widget _buildCamera() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = BoxDecoration(
      color: isDark ? AppColors.darkSubCategoryCardColor : Colors.white,
      borderRadius: BorderRadius.circular(12),
    );
    return ScanCameraView(
      controller: _scanner,
      onDetect: _onDetect,
      onManualEntry: () => _go(_Mode.manual),
      hint: "Point the camera at the bag's barcode.",
      preview: widget.cameraBuilder?.call(_onCode),
      footer: _notice == null && _queue.isEmpty
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_notice != null)
                  DecoratedBox(
                    decoration: card,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: _buildNotice(),
                    ),
                  ),
                if (_notice != null && _queue.isNotEmpty)
                  const SizedBox(height: 8),
                if (_queue.isNotEmpty)
                  DecoratedBox(
                    decoration: card,
                    child: _buildQueueBar(topGap: false),
                  ),
              ],
            ),
    );
  }

  Widget _buildCameraActions() {
    return Row(
      children: [
        ScanManualEntryButton(onPressed: () => _go(_Mode.manual)),
        const SizedBox(width: 10),
        Expanded(
          child: ScanSecondaryButton(label: 'Cancel', onPressed: _close),
        ),
      ],
    );
  }

  // ── Review one scan ────────────────────────────────────────────────────

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
        const SizedBox(height: 8),
        Text(
          'Save to scan the next bag, or finish if this is the last one.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  Widget _buildReviewActions() {
    final total = _queue.length + 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ScanSecondaryButton(
                label: 'Retake',
                onPressed: () => _go(_Mode.camera),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: ScanPrimaryButton(
                label: 'Save & next',
                icon: Icons.add,
                onPressed: () => _saveScanned(finish: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ScanPrimaryButton(
          label: 'Save and finish ($total)',
          icon: Icons.check,
          color: Colors.green.shade600,
          onPressed: () => _saveScanned(finish: true),
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
          "Type the code printed under the bag's barcode. Separate several "
          'codes with commas or semicolons.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _codeController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _addTyped(),
          cursorColor: scanFieldColor(context),
          decoration: scanCodeFieldDecoration(context, errorText: _error),
        ),
        _buildNotice(),
        _buildQueueBar(),
      ],
    );
  }

  Widget _buildManualActions() {
    return Row(
      children: [
        Expanded(
          child: ScanSecondaryButton(
            label: 'Scan instead',
            onPressed: () => _go(_Mode.camera),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ScanPrimaryButton(
            label: 'Add to list',
            icon: Icons.add,
            onPressed: _addTyped,
          ),
        ),
      ],
    );
  }

  // ── List of scanned bags ───────────────────────────────────────────────

  Widget _buildList() {
    final theme = Theme.of(context);
    if (_queue.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Text(
          'No bags in the list. Scan a bag to add it.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Swipe left or tap ✕ to remove a barcode.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            itemCount: _queue.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _QueuedBarcodeRow(
              key: ValueKey(_queue[index]),
              code: _queue[index],
              enabled: !_isSubmitting,
              onRemove: () => _remove(_queue[index]),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ScanErrorText(_error!),
          ),
      ],
    );
  }

  Widget _buildListActions() {
    final count = _queue.length;
    if (count == 0) {
      return ScanPrimaryButton(
        label: 'Scan bags',
        icon: Icons.qr_code_scanner,
        onPressed: () => _go(_Mode.camera),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScanPrimaryButton(
          label: 'Confirm $count ${count == 1 ? 'bag' : 'bags'}',
          icon: Icons.check,
          color: Colors.green.shade600,
          isLoading: _isSubmitting,
          onPressed: _submit,
        ),
        const SizedBox(height: 10),
        ScanSecondaryButton(
          label: 'Scan more',
          onPressed: _isSubmitting || _isFull ? null : () => _go(_Mode.camera),
        ),
      ],
    );
  }

  // ── Result ─────────────────────────────────────────────────────────────

  Widget _buildResult() {
    final result = _result!;
    final theme = Theme.of(context);
    final created = result.createdCount;
    final duplicates = result.duplicateBarcodes;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 28,
              backgroundColor: created > 0
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              child: Icon(
                created > 0 ? Icons.check : Icons.info_outline,
                size: 30,
                color: created > 0
                    ? Colors.green.shade700
                    : Colors.orange.shade800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            created > 0
                ? '$created ${created == 1 ? 'bag' : 'bags'} added'
                : 'No new bags added',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (duplicates.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${duplicates.length} ${duplicates.length == 1 ? 'barcode is' : 'barcodes are'} '
                    'already in use and ${duplicates.length == 1 ? 'was' : 'were'} skipped:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    duplicates.join('\n'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QueuedBarcodeRow extends StatelessWidget {
  final String code;
  final bool enabled;
  final VoidCallback onRemove;

  const _QueuedBarcodeRow({
    super.key,
    required this.code,
    required this.enabled,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final row = Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
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
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              code,
              style: theme.textTheme.titleSmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove $code',
            onPressed: enabled ? onRemove : null,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
    if (!enabled) return row;
    return Dismissible(
      key: ValueKey('dismiss-$code'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: row,
    );
  }
}
