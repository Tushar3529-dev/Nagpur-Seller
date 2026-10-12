import 'package:flutter/material.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/widgets/product_inventory_dialog.dart';

/// Listing resources may lack per-store inventory IDs. Load fresh details
/// directly into the editor without navigating away from the product list.
class ProductInventoryLoader extends StatefulWidget {
  final int productId;
  final ProductsRepo? repo;
  const ProductInventoryLoader({super.key, required this.productId, this.repo});

  @override
  State<ProductInventoryLoader> createState() => _ProductInventoryLoaderState();
}

class _ProductInventoryLoaderState extends State<ProductInventoryLoader> {
  late final _repo = widget.repo ?? ProductsRepo();
  List<Variant>? _variants;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _repo.getProductById(widget.productId);
      final data = response is Map ? response['data'] : null;
      if (data is! Map<String, dynamic>) {
        throw Exception('Product details are unavailable.');
      }
      final variants = Product.fromJson(data).variants ?? <Variant>[];
      if (variants.isEmpty) {
        throw Exception('This product has no inventory variations.');
      }
      if (!mounted) return;
      setState(() {
        _variants = variants;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final variants = _variants;
    if (variants != null) {
      return ProductInventoryDialog(
        productId: widget.productId,
        variant: variants.first,
        variants: variants,
        repo: _repo,
      );
    }
    return AlertDialog(
      title: const Text('Edit stock quantity'),
      content: _loading
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading current stock…'),
              ],
            )
          : Text(_error ?? 'Unable to load stock.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (!_loading) TextButton(onPressed: _load, child: const Text('Retry')),
      ],
    );
  }
}
