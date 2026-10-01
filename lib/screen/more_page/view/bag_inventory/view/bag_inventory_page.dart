import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/bloc/bags_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/model/bag_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/repo/bags_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/widgets/add_bags_dialog.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/widgets/bag_card.dart';
import 'package:hyper_local_seller/screen/more_page/view/bag_inventory/widgets/edit_bag_dialog.dart';
import 'package:hyper_local_seller/screen/products_page/products/widgets/product_scan_dialog.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/barcode_scan_widgets.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_alert_dialog.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_search_field.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';

/// Lists the seller's delivery bags and adds, edits and deletes them.
class BagInventoryPage extends StatelessWidget {
  final BagsRepo? repo;

  const BagInventoryPage({super.key, this.repo});

  @override
  Widget build(BuildContext context) {
    final repo = this.repo ?? BagsRepo();
    return BlocProvider(
      create: (_) => BagsBloc(repo),
      child: _BagInventoryView(repo: repo),
    );
  }
}

class _BagInventoryView extends StatefulWidget {
  final BagsRepo repo;

  const _BagInventoryView({required this.repo});

  @override
  State<_BagInventoryView> createState() => _BagInventoryViewState();
}

class _BagInventoryViewState extends State<_BagInventoryView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 500);

  /// [Bag.available], [Bag.assigned] or null for every bag.
  String? _status;

  @override
  void initState() {
    super.initState();
    _reload();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<BagsBloc>().add(
      LoadBags(status: _status, search: _searchController.text.trim()),
    );
  }

  void _refresh() => context.read<BagsBloc>().add(RefreshBags());

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent * 0.9) {
      context.read<BagsBloc>().add(LoadMoreBags());
    }
  }

  void _setStatus(String? status) {
    if (status == _status) return;
    setState(() => _status = status);
    _reload();
  }

  Future<void> _scanSearch() async {
    final code = await scanProductBarcode(context);
    if (code == null || !mounted) return;
    _searchController.text = code;
    _reload();
  }

  Future<void> _addBags() async {
    final added = await openAddBagsDialog(context, repo: widget.repo);
    if (added && mounted) _refresh();
  }

  Future<void> _edit(Bag bag) async {
    final outcome = await openEditBagDialog(context, bag, repo: widget.repo);
    if (!mounted || outcome == null) return;
    showCustomSnackbar(
      context: context,
      message: outcome == EditBagOutcome.updated
          ? 'Bag updated'
          : 'This bag is now assigned to an order and can no longer be edited.',
      isWarning: outcome == EditBagOutcome.assigned,
    );
    _refresh();
  }

  void _delete(Bag bag) {
    showAppAlertDialog(
      context: context,
      title: 'Delete bag?',
      message: '${bag.barcode} will be removed from your inventory.',
      confirmText: 'Delete',
      isDestructive: true,
      onConfirm: () async {
        try {
          await widget.repo.deleteBag(bag.id);
          if (!mounted) return;
          showCustomSnackbar(context: context, message: 'Bag deleted');
        } catch (e) {
          if (!mounted) return;
          showCustomSnackbar(
            context: context,
            message: e is ApiException && e.statusCode == 409
                ? 'This bag is now assigned to an order and can no longer be deleted.'
                : "Couldn't delete the bag. $e",
            isError: true,
          );
        }
        if (mounted) _refresh();
      },
    );
  }

  void _showLocked(Bag bag) {
    final order = bag.orderNumber;
    showCustomSnackbar(
      context: context,
      message: order == null
          ? "Assigned bags can't be edited or deleted."
          : "This bag is assigned to order $order, so it can't be edited or deleted.",
      isWarning: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenType = context.screenType;

    return CustomScaffold(
      centerTitle: true,
      showAppbar: true,
      title: l10n?.bagInventory ?? 'Bag Inventory',
      body: BlocBuilder<BagsBloc, BagsState>(
        builder: (context, state) {
          final isLoading =
              (state.isInitialLoading || state.isRefreshing) &&
              state.items.isEmpty;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: UIUtils.pagePadding(screenType),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ScanPrimaryButton(
                      label: 'Add bags',
                      icon: Icons.qr_code_scanner,
                      onPressed: _addBags,
                    ),
                    const SizedBox(height: 12),
                    CustomSearchField(
                      controller: _searchController,
                      hint: 'Search barcode',
                      onChanged: (_) => _debouncer.run(_reload),
                      suffixIcon: IconButton(
                        tooltip: 'Scan to search',
                        onPressed: _scanSearch,
                        icon: const Icon(Icons.qr_code_scanner),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFilters(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isLoading ? '' : _countLabel(state.total ?? 0),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: UIUtils.body(screenType),
                            ),
                          ),
                        ),
                        if (state.isRefreshing && state.items.isNotEmpty)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildList(state, isLoading)),
            ],
          );
        },
      ),
    );
  }

  String _countLabel(int total) {
    final noun = total == 1 ? 'bag' : 'bags';
    return switch (_status) {
      Bag.available => '$total available $noun',
      Bag.assigned => '$total assigned $noun',
      _ => '$total $noun',
    };
  }

  Widget _buildFilters() {
    const filters = {
      null: 'All',
      Bag.available: 'Available',
      Bag.assigned: 'Assigned',
    };
    return Wrap(
      spacing: 8,
      children: [
        for (final entry in filters.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: _status == entry.key,
            onSelected: (_) => _setStatus(entry.key),
            showCheckmark: true,
            checkmarkColor: Colors.white,
            selectedColor: AppColors.primaryColor,
            labelStyle: TextStyle(
              color: _status == entry.key ? Colors.white : null,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildList(BagsState state, bool isLoading) {
    final screenType = context.screenType;

    if (state.error != null && state.items.isEmpty) {
      return EmptyStateWidget(
        svgPath: ImagesPath.noOrderFoundSvg,
        title: "Couldn't load your bags",
        subtitle: state.error,
        actionText: 'Try again',
        onAction: _reload,
      );
    }

    if (!isLoading && state.items.isEmpty) {
      final searching = _searchController.text.trim().isNotEmpty;
      return RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: () async => _refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            EmptyStateWidget(
              svgPath: ImagesPath.noSearchFoundSvg,
              svgSize: 140,
              title: searching
                  ? 'No bags match your search'
                  : switch (_status) {
                      Bag.available => 'No available bags',
                      Bag.assigned => 'No assigned bags',
                      _ => 'Add your first bags',
                    },
              subtitle: searching || _status != null
                  ? null
                  : 'Scan bag barcodes to add them to your inventory.',
            ),
          ],
        ),
      );
    }

    final items = state.items;
    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: () async => _refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: UIUtils.cardsPadding(screenType),
        separatorBuilder: (_, _) => SizedBox(height: UIUtils.gapMD(screenType)),
        itemCount: isLoading
            ? 6
            : items.length + (state.hasMore && state.isPaginating ? 2 : 0),
        itemBuilder: (context, index) {
          if (isLoading || index >= items.length) {
            return CardShimmer(type: 'bag', screenType: screenType);
          }
          final bag = items[index];
          return BagCard(
            key: ValueKey(bag.id),
            bag: bag,
            onEdit: () => _edit(bag),
            onDelete: () => _delete(bag),
            onLockedTap: () => _showLocked(bag),
          );
        },
      ),
    );
  }
}
