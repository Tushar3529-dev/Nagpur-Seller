import 'package:flutter/material.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_search_field.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductSelectionSheet extends StatefulWidget {
  final ScreenType screenType;
  final Function(Product) onSelected;

  const ProductSelectionSheet({
    super.key,
    required this.screenType,
    required this.onSelected,
  });

  static void show(BuildContext context, {required Function(Product) onSelected}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductSelectionSheet(
        screenType: context.screenType,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<ProductSelectionSheet> createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends State<ProductSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ProductsRepo _repo = ProductsRepo();
  
  final List<Product> _products = [];
  bool _isLoading = false;
  int _page = 1;
  bool _hasMore = true;
  String _lastSearch = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _fetchProducts();
      }
    }
  }

  Future<void> _fetchProducts({bool isRefresh = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _page = 1;
        _products.clear();
      }
    });

    try {
      final response = await _repo.getProducts(
        page: _page,
        search: _searchController.text,
      );
      
      final productsResponse = ProductsResponse.fromJson(response);
      if (productsResponse.success == true && productsResponse.data != null) {
        final newProducts = productsResponse.data!.products ?? [];
        setState(() {
          _products.addAll(newProducts);
          _hasMore = productsResponse.data!.currentPage! < productsResponse.data!.lastPage!;
          if (_hasMore) _page++;
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(UIUtils.radiusLG(widget.screenType)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Select Product',
              style: TextStyle(
                fontSize: UIUtils.pageTitle(widget.screenType),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(UIUtils.gapMD(widget.screenType)),
            child: CustomSearchField(
              controller: _searchController,
              hint: 'Search products...',
              onChanged: (value) {
                if (value != _lastSearch) {
                  _lastSearch = value;
                  _fetchProducts(isRefresh: true);
                }
              },
            ),
          ),
          Expanded(
            child: _products.isEmpty && !_isLoading
                ? Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(horizontal: UIUtils.gapMD(widget.screenType)),
                    itemCount: _products.length + (_isLoading ? 1 : 0),
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index >= _products.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CustomLoadingIndicator()),
                        );
                      }
                      
                      final product = _products[index];
                      return ListTile(
                        onTap: () {
                          widget.onSelected(product);
                          Navigator.pop(context);
                        },
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: product.mainImage,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                          ),
                        ),
                        title: Text(
                          product.title,
                          style: TextStyle(
                            fontSize: UIUtils.tileTitle(widget.screenType),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          product.categoryName ?? '',
                          style: TextStyle(
                            fontSize: UIUtils.caption(widget.screenType),
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
