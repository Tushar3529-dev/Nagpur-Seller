import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/model/bag_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/repo/bags_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/widgets/product_scan_dialog.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/widgets/custom/barcode_scan_widgets.dart';

/// What happened in the edit dialog.
enum EditBagOutcome { updated, assigned }

/// Edits a bag's barcode. Completes with [EditBagOutcome.updated] once saved,
/// [EditBagOutcome.assigned] when the server says the bag was assigned to an
/// order in the meantime, or null when the seller cancels.
Future<EditBagOutcome?> openEditBagDialog(
  BuildContext context,
  Bag bag, {
  BagsRepo? repo,
}) => showDialog<EditBagOutcome>(
  context: context,
  builder: (_) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: EditBagDialog(bag: bag, repo: repo),
    ),
  ),
);

class EditBagDialog extends StatefulWidget {
  final Bag bag;
  final BagsRepo? repo;

  const EditBagDialog({super.key, required this.bag, this.repo});

  @override
  State<EditBagDialog> createState() => _EditBagDialogState();
}

class _EditBagDialogState extends State<EditBagDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.bag.barcode,
  );
  late final BagsRepo _repo = widget.repo ?? BagsRepo();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await scanProductBarcode(context);
    if (code == null || !mounted) return;
    setState(() {
      _controller.text = code;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final barcode = _controller.text.trim();
    if (barcode.isEmpty) {
      setState(() => _error = 'Enter a barcode');
      return;
    }
    if (barcode == widget.bag.barcode) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await _repo.updateBag(widget.bag.id, barcode);
      if (mounted) Navigator.of(context).pop(EditBagOutcome.updated);
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.statusCode == 409) {
        Navigator.of(context).pop(EditBagOutcome.assigned);
        return;
      }
      setState(() {
        _isSaving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final decoration = scanCodeFieldDecoration(context, errorText: _error);
    return ColoredBox(
      color: isDark ? AppColors.darkSubCategoryCardColor : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScanDialogHeader(
            title: 'Edit bag',
            onClose: () => Navigator.of(context).pop(),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    enabled: !_isSaving,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    onSubmitted: (_) => _save(),
                    cursorColor: scanFieldColor(context),
                    style: const TextStyle(fontFamily: 'monospace'),
                    decoration: decoration.copyWith(
                      suffixIcon: IconButton(
                        tooltip: 'Scan barcode',
                        onPressed: _isSaving ? null : _scan,
                        icon: const Icon(Icons.qr_code_scanner),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type the new code, or tap the scan icon to scan it.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ScanBottomBar(
            child: Row(
              children: [
                Expanded(
                  child: ScanSecondaryButton(
                    label: 'Cancel',
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ScanPrimaryButton(
                    label: 'Save',
                    icon: Icons.check,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
