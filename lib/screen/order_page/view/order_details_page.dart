// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/order_details_bloc/order_details_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/model/order_details_model.dart';
import 'package:hyper_local_seller/screen/order_page/repo/order_repo.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/screen/order_page/widgets/order_dialogs.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

class OrderDetailsPage extends StatefulWidget {
  final int orderId;
  const OrderDetailsPage({super.key, required this.orderId});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final Set<int> _selectedItemIds = {};

  @override
  void initState() {
    super.initState();
    context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));
  }

  /// Returns 'pending' if selected items are pending/awaiting,
  /// 'accepted' if selected items are accepted, or null if nothing selected.
  String? _getSelectionMode(List<OrderItemDetail> items) {
    if (_selectedItemIds.isEmpty) return null;
    for (final item in items) {
      final itemId = item.orderItem?.id ?? item.id;
      if (_selectedItemIds.contains(itemId)) {
        final status = (item.orderItem?.status ?? '').toLowerCase();
        if (status == 'pending' || status == 'awaiting_store_response') {
          return 'pending';
        } else if (status == 'accepted') {
          return 'accepted';
        }
      }
    }
    return null;
  }

  /// Checks if an item can be selected based on its status and current selection mode.
  bool _isItemSelectable(OrderItemDetail item, String? selectionMode) {
    final status = (item.orderItem?.status ?? '').toLowerCase();
    // Never selectable statuses
    if ({
      'rejected',
      'cancelled',
      'preparing',
      'ready_for_pickup',
      'completed',
    }.contains(status)) {
      return false;
    }
    // No mode yet — any actionable item can start selection
    if (selectionMode == null) {
      return status == 'pending' ||
          status == 'awaiting_store_response' ||
          status == 'accepted';
    }
    if (selectionMode == 'pending') {
      return status == 'pending' || status == 'awaiting_store_response';
    }
    if (selectionMode == 'accepted') {
      return status == 'accepted';
    }
    return false;
  }

  /// Whether item has an actionable status (should show checkbox).
  bool _isItemActionable(OrderItemDetail item) {
    final status = (item.orderItem?.status ?? '').toLowerCase();
    return status == 'pending' ||
        status == 'awaiting_store_response' ||
        status == 'accepted';
  }

  void _toggleItemSelection(int itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Theme
    final theme = Theme.of(context);
    final currencySymbol = HiveStorage.currencySymbol;
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<OrderDetailsBloc, OrderDetailsState>(
      listener: (context, state) {
        if (state is OrderDetailsLoaded) {
          setState(() => _selectedItemIds.clear());
        }
      },
      builder: (context, state) {
        Widget? bottomBar;
        if (state is OrderDetailsLoaded) {
          bottomBar = _buildBottomBar(
            context,
            state.orderData,
            state.isUpdating,
            l10n,
          );
        }

        return CustomScaffold(
          title: l10n?.orderDetails ?? 'Order Details',
          centerTitle: true,
          showAppbar: true,
          bottomNavigationBar: bottomBar,
          body: Builder(
            builder: (context) {
              if (state is OrderDetailsLoading) {
                return _buildShimmerLoading(context);
              }
              if (state is OrderDetailsError) {
                return Center(child: Text(state.message));
              }
              if (state is OrderDetailsLoaded) {
                final data = state.orderData;
                return RefreshIndicator(
                  color: AppColors.primaryColor,
                  onRefresh: () async {
                    context.read<OrderDetailsBloc>().add(
                      FetchOrderDetails(widget.orderId),
                    );
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Order Summary
                        _buildSection(
                          context,
                          title: l10n?.orderSummary ?? 'Order Summary',
                          child: Column(
                            children: [
                              _buildKvRow(
                                context,
                                l10n?.orderNumber ?? 'Order Number :',
                                data.uuid,
                              ),
                              _buildKvRow(
                                context,
                                l10n?.orderDate ?? 'Order Date :',
                                data.createdAt,
                              ),
                              _buildKvRow(
                                context,
                                l10n?.statusLabel ?? 'Status :',
                                data.status,
                                isStatus: true,
                              ),
                              _buildKvRow(
                                context,
                                l10n?.totalPrice ?? 'Total Price :',
                                '$currencySymbol ${data.totalPrice}',
                              ),
                              _buildKvRow(
                                context,
                                l10n?.paymentMethod ?? 'Payment Method :',
                                data.paymentMethod.toUpperCase().replaceAll(
                                  '_',
                                  ' ',
                                ),
                              ),
                              _buildKvRow(
                                context,
                                l10n?.paymentStatus ?? 'Payment Status :',
                                data.paymentStatus,
                                isStatus: true,
                                isPaymentStatus: true,
                              ),
                              _buildKvRow(
                                context,
                                l10n?.deliveryTypeLabel ?? 'Delivery Type :',
                                data.isRushedOrder == 1
                                    ? (l10n?.rushDelivery ?? 'Rush Delivery')
                                    : (l10n?.standardDelivery ??
                                          'Standard Delivery'),
                                isStatus: true,
                              ),
                              if (data.orderNote != null &&
                                  data.orderNote!.isNotEmpty)
                                _buildKvRow(
                                  context,
                                  l10n?.orderNote ?? 'Order Note :',
                                  data.orderNote!,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildSection(
                          context,
                          title:
                              '${l10n?.orderItems ?? "Order Items"} (${data.items?.length ?? 0})',
                          trailing: _selectedItemIds.isNotEmpty
                              ? TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _selectedItemIds.clear()),
                                  icon: const Icon(
                                    TablerIcons.circle_x,
                                    size: 16,
                                  ),
                                  label: Text(l10n?.clear ?? 'Clear'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    visualDensity: VisualDensity.compact,
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : null,
                          child: Column(
                            children: () {
                              final items = data.items ?? [];
                              final selectionMode = _getSelectionMode(items);
                              return items.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final bool isSame =
                                    item.product?.title == item.variant?.title;
                                final itemId = item.orderItem?.id ?? item.id;

                                return _ExpandableOrderItem(
                                  index: index,
                                  item: item,
                                  isSame: isSame,
                                  currencySymbol: currencySymbol,
                                  isLast: index == items.length - 1,
                                  isSelected: _selectedItemIds.contains(itemId),
                                  isSelectable: _isItemSelectable(
                                    item,
                                    selectionMode,
                                  ),
                                  showCheckbox: _isItemActionable(item),
                                  onSelectionChanged: (_) =>
                                      _toggleItemSelection(itemId),
                                );
                              }).toList();
                            }(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Customer Information
                        _buildSection(
                          context,
                          title:
                              l10n?.customerInformation ??
                              'Customer Information',
                          child: Column(
                            children: [
                              _buildKvRow(
                                context,
                                l10n?.customerName ?? 'Customer Name :',
                                data.billingName,
                              ),
                              _buildKvRow(
                                context,
                                l10n?.phoneLabel ?? 'Phone :',
                                data.billingPhone,
                              ),
                              _buildKvRow(
                                context,
                                l10n?.emailLabel ?? 'Email :',
                                data.email,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Shipping Address
                        _buildSection(
                          context,
                          title: l10n?.shippingAddress ?? 'Shipping Address',
                          child: Text(
                            '${data.shippingName}\n'
                            '${data.shippingAddress1}\n'
                            '${data.shippingCity}, ${data.shippingState} ${data.shippingZip}, ${data.shippingCountry}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, indent: 0, endIndent: 0),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildKvRow(
    BuildContext context,
    String key,
    String value, {
    bool isStatus = false,
    bool isPaymentStatus = false,
  }) {
    final theme = Theme.of(context);

    Widget valueWidget = Text(
      value.isEmpty ? '—' : value, // fallback for empty values
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
    );

    if (isStatus || isPaymentStatus) {
      Color color = Colors.green;
      Color bgColor = Colors.green.withValues(alpha: 0.12);

      final v = value.toLowerCase().replaceAll('_', ' ');
      if (v.contains('pending') ||
          v.contains('awaiting') ||
          v.contains('partially')) {
        color = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.12);
      } else if (v.contains('accepted')) {
        color = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.12);
      } else if (v.contains('preparing')) {
        color = Colors.blue;
        bgColor = Colors.blue.withValues(alpha: 0.12);
      } else if (v.contains('ready')) {
        color = Colors.purple;
        bgColor = Colors.purple.withValues(alpha: 0.12);
      } else if (v.contains('completed')) {
        color = Colors.green;
      } else if (v.contains('rejected') || v.contains('cancelled')) {
        color = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.12);
      }

      valueWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          v.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              key,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16), // consistent gap
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft, // values pushed to right
              child: valueWidget,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSectionShimmer(context, 190),
          const SizedBox(height: 16),
          _buildSectionShimmer(context, 150),
          const SizedBox(height: 16),
          _buildSectionShimmer(context, 150),
          const SizedBox(height: 16),
          _buildSectionShimmer(context, 175),
        ],
      ),
    );
  }

  Widget _buildSectionShimmer(BuildContext context, double height) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomShimmer(width: 150, height: 20),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomShimmer(width: 100, height: 16),
                    CustomShimmer(width: 150, height: 16),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomShimmer(width: 100, height: 16),
                    CustomShimmer(width: 150, height: 16),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomShimmer(width: 100, height: 16),
                    CustomShimmer(width: 80, height: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar(
    BuildContext context,
    OrderDetailsData data,
    bool isUpdating,
    AppLocalizations? l10n,
  ) {
    if (data.items == null || data.items!.isEmpty) return null;
    if (_selectedItemIds.isEmpty) return null;

    final selectionMode = _getSelectionMode(data.items!);
    final selectedCount = _selectedItemIds.length;
    final theme = Theme.of(context);

    if (selectionMode == 'pending') {
      // Show Accept + Reject buttons
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              // margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    TablerIcons.info_circle,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$selectedCount item${selectedCount > 1 ? 's' : ''} selected',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isUpdating
                        ? null
                        : () => _handleReject(context, l10n),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isUpdating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(TablerIcons.circle_x, size: 20),
                              const SizedBox(width: 8),
                              Text(l10n?.reject ?? 'Reject'),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isUpdating
                        ? null
                        : () => _handleAccept(context, l10n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isUpdating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(TablerIcons.circle_check, size: 20),
                              const SizedBox(width: 8),
                              Text(l10n?.accept ?? 'Accept'),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (selectionMode == 'accepted') {
      // Show Prepare button
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    TablerIcons.info_circle,
                    size: 14,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$selectedCount item${selectedCount > 1 ? 's' : ''} selected',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () => _handlePrepare(context, l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(TablerIcons.package, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n?.markAsPreparing ?? 'Mark as Preparing'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      );
    }

    return null;
  }

  void _handleAccept(BuildContext context, AppLocalizations? l10n) {
    if (!PermissionChecker.hasPermission(AppPermissions.orderUpdateStatus)) {
      showCustomSnackbar(
        context: context,
        message: "You don't have permission to update order status",
        isWarning: true,
      );
      return;
    }
    if (!DemoGuard.shouldProceed(context)) return;

    final selectedIds = _selectedItemIds.toList();
    OrderDialogs.showAcceptDialog(context, () async {
      for (final itemId in selectedIds) {
        await context.read<OrdersRepo>().updateOrderStatus(itemId, 'accept');
      }
      if (context.mounted) {
        context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));
        context.read<OrdersBloc>().add(RefreshOrders());
      }
    });
  }

  void _handleReject(BuildContext context, AppLocalizations? l10n) {
    if (!PermissionChecker.hasPermission(AppPermissions.orderUpdateStatus)) {
      showCustomSnackbar(
        context: context,
        message: "You don't have permission to update order status",
        isWarning: true,
      );
      return;
    }
    if (!DemoGuard.shouldProceed(context)) return;

    final selectedIds = _selectedItemIds.toList();
    OrderDialogs.showRejectDialog(context, () async {
      for (final itemId in selectedIds) {
        await context.read<OrdersRepo>().updateOrderStatus(itemId, 'reject');
      }
      if (context.mounted) {
        context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));
        context.read<OrdersBloc>().add(RefreshOrders());
      }
    });
  }

  void _handlePrepare(BuildContext context, AppLocalizations? l10n) {
    if (!PermissionChecker.hasPermission(AppPermissions.orderUpdateStatus)) {
      showCustomSnackbar(
        context: context,
        message: "You don't have permission to update order status",
        isWarning: true,
      );
      return;
    }
    if (!DemoGuard.shouldProceed(context)) return;

    final selectedIds = _selectedItemIds.toList();
    OrderDialogs.showPreparedDialog(context, () async {
      for (final itemId in selectedIds) {
        await context.read<OrdersRepo>().updateOrderStatus(itemId, 'preparing');
      }
      if (context.mounted) {
        context.read<OrderDetailsBloc>().add(FetchOrderDetails(widget.orderId));
        context.read<OrdersBloc>().add(RefreshOrders());
      }
    });
  }
}

class _ExpandableOrderItem extends StatefulWidget {
  final int index;
  final OrderItemDetail item;
  final bool isSame;
  final String currencySymbol;
  final bool isLast;
  final bool isSelected;
  final bool isSelectable;
  final bool showCheckbox;
  final ValueChanged<bool>? onSelectionChanged;

  const _ExpandableOrderItem({
    required this.index,
    required this.item,
    required this.isSame,
    required this.currencySymbol,
    required this.isLast,
    this.isSelected = false,
    this.isSelectable = false,
    this.showCheckbox = false,
    this.onSelectionChanged,
  });

  @override
  State<_ExpandableOrderItem> createState() => _ExpandableOrderItemState();
}

class _ExpandableOrderItemState extends State<_ExpandableOrderItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Container(
          color: widget.isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : null,
          child: InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Header - Always visible
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Custom Styled Selection Indicator
                      if (widget.showCheckbox)
                        GestureDetector(
                          onTap: widget.isSelectable
                              ? () => widget.onSelectionChanged?.call(
                                  !widget.isSelected,
                                )
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(top: 2, right: 12),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isSelected
                                  ? AppColors.primaryColor
                                  : Colors.transparent,
                              border: Border.all(
                                color: widget.isSelected
                                    ? AppColors.primaryColor
                                    : Colors.grey.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: widget.isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),

                      // Product Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.product?.title ??
                                  (l10n?.notAvailable ?? 'N/A'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: widget.isSelectable || widget.isSelected
                                    ? null
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  l10n?.qtyWithCount(widget.item.quantity) ??
                                      'Qty: ${widget.item.quantity}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${widget.currencySymbol} ${widget.item.subtotal.toStringAsFixed(2)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            // Move Status Badge below info
                            if ((widget.item.orderItem?.status ?? '')
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildStatusChip(
                                context,
                                widget.item.orderItem!.status,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Expand/Collapse Icon
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ],
                  ),

                  // Expanded Details
                  if (_isExpanded) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          if (!widget.isSame)
                            _buildDetailRow(
                              context,
                              l10n?.variant ?? 'Variant',
                              widget.item.variant?.title ??
                                  (l10n?.notAvailable ?? 'N/A'),
                            ),
                          _buildDetailRow(
                            context,
                            l10n?.quantity ?? 'Quantity',
                            widget.item.quantity.toString(),
                          ),
                          _buildDetailRow(
                            context,
                            l10n?.price ?? 'Price',
                            '${widget.currencySymbol} ${widget.item.price}',
                          ),
                          _buildDetailRow(
                            context,
                            l10n?.subtotal ?? 'Subtotal',
                            '${widget.currencySymbol} ${widget.item.subtotal.toStringAsFixed(2)}',
                            isLast: true,
                          ),
                          if (widget.item.attachments != null &&
                              widget.item.attachments!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                l10n?.attachments ?? 'Attachments',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 80,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.item.attachments!.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final attachment =
                                      widget.item.attachments![index];
                                  final String url = attachment.toString();
                                  final isImage =
                                      url.toLowerCase().endsWith('.jpg') ||
                                      url.toLowerCase().endsWith('.jpeg') ||
                                      url.toLowerCase().endsWith('.png') ||
                                      url.toLowerCase().endsWith('.gif') ||
                                      url.toLowerCase().endsWith('.webp');

                                  return GestureDetector(
                                    onTap: () async {
                                      final uri = Uri.parse(url);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      }
                                    },
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              theme.colorScheme.outlineVariant,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: isImage
                                          ? CachedNetworkImage(
                                              imageUrl: url,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                    child: CustomShimmer(
                                                      width: 80,
                                                      height: 80,
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            )
                                          : Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(TablerIcons.file),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    url.split('/').last,
                                                    style: theme
                                                        .textTheme
                                                        .labelSmall,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Divider between items
        if (!widget.isLast)
          Divider(
            height: 1,
            thickness: 0.5,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isLast = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final theme = Theme.of(context);
    final v = status.toLowerCase().replaceAll('_', ' ');

    Color color;
    Color bgColor;

    if (v.contains('pending') || v.contains('awaiting')) {
      color = Colors.orange;
      bgColor = Colors.orange.withValues(alpha: 0.12);
    } else if (v.contains('accepted')) {
      color = Colors.green;
      bgColor = Colors.green.withValues(alpha: 0.12);
    } else if (v.contains('preparing')) {
      color = Colors.blue;
      bgColor = Colors.blue.withValues(alpha: 0.12);
    } else if (v.contains('ready')) {
      color = Colors.purple;
      bgColor = Colors.purple.withValues(alpha: 0.12);
    } else if (v.contains('completed')) {
      color = Colors.green;
      bgColor = Colors.green.withValues(alpha: 0.12);
    } else if (v.contains('rejected') || v.contains('cancelled')) {
      color = Colors.red;
      bgColor = Colors.red.withValues(alpha: 0.12);
    } else {
      color = Colors.grey;
      bgColor = Colors.grey.withValues(alpha: 0.12);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        v.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }
}
