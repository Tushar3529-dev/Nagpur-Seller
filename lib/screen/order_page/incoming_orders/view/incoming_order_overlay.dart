import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/home_page/home_page_bloc.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/notification/notification_list_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/cubit/incoming_orders_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/model/pending_order_model.dart';
import 'package:hyper_local_seller/screen/order_page/incoming_orders/widgets/response_timer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Sits in `MaterialApp.builder`, above every route. While there are pending
/// regular orders it covers the whole app with a stack of order cards that
/// can only be cleared by accepting them — there is no close or reject.
class IncomingOrderOverlay extends StatelessWidget {
  final Widget child;

  const IncomingOrderOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncomingOrdersCubit, IncomingOrdersState>(
      builder: (context, state) {
        return Stack(
          children: [
            child,
            if (state.hasPending)
              Positioned.fill(child: _OrderStackBarrier(state: state)),
          ],
        );
      },
    );
  }
}

class _OrderStackBarrier extends StatelessWidget {
  final IncomingOrdersState state;

  const _OrderStackBarrier({required this.state});

  @override
  Widget build(BuildContext context) {
    final top = state.orders.first;
    final behind = (state.orders.length - 1).clamp(0, 2);

    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _WaitingBadge(count: state.orders.length),
                  const SizedBox(height: 14),
                  // Edges of the cards waiting underneath the top one.
                  for (var i = behind; i >= 1; i--) _StackEdge(depth: i),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween(
                            begin: 0.96,
                            end: 1.0,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _IncomingOrderCard(
                        key: ValueKey(top.sellerOrderId),
                        order: top,
                        position: 1,
                        total: state.orders.length,
                        isAccepting:
                            state.acceptingOrderId == top.sellerOrderId,
                        errorMessage: state.failedOrderId == top.sellerOrderId
                            ? state.errorMessage
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaitingBadge extends StatelessWidget {
  final int count;

  const _WaitingBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_active, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            count == 1 ? '1 order waiting' : '$count orders waiting',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StackEdge extends StatelessWidget {
  final int depth;

  const _StackEdge({required this.depth});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.darkProductCardColor : Colors.white;
    return Container(
      height: 10,
      margin: EdgeInsets.symmetric(horizontal: 14.0 * depth),
      decoration: BoxDecoration(
        color: base.withValues(alpha: depth == 1 ? 0.85 : 0.6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
    );
  }
}

class _IncomingOrderCard extends StatelessWidget {
  final PendingOrder order;
  final int position;
  final int total;
  final bool isAccepting;
  final String? errorMessage;

  const _IncomingOrderCard({
    super.key,
    required this.order,
    required this.position,
    required this.total,
    required this.isAccepting,
    required this.errorMessage,
  });

  static const double _timerSize = 112;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.darkSubCategoryCardColor
        : Colors.white;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: ColoredBox(
        color: cardColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(position: position, total: total),
                    const SizedBox(height: _timerSize / 2 + 12),
                  ],
                ),
                Positioned(
                  bottom: 12,
                  child: ResponseTimer(
                    since: order.createdAt,
                    size: _timerSize,
                  ),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OrderSummary(order: order),
                    const SizedBox(height: 12),
                    for (final item in order.items) _ItemRow(item: item),
                  ],
                ),
              ),
            ),
            _AcceptBar(
              order: order,
              isAccepting: isAccepting,
              errorMessage: errorMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int position;
  final int total;

  const _Header({required this.position, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryColor,
      // Bottom padding clears the top half of the timer that overlaps it.
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 68),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  total > 1
                      ? 'INCOMING ORDER · $position OF $total'
                      : 'INCOMING ORDER',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'New regular order',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Review the details and start preparing.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final PendingOrder order;

  const _OrderSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = HiveStorage.currencySymbol;
    final created = order.createdAt?.toLocal();

    final tiles = <_InfoTile>[
      _InfoTile(
        label: 'ORDERED',
        value: created == null
            ? '—'
            : DateFormat('d MMM yyyy, HH:mm').format(created),
      ),
      _InfoTile(label: 'PAYMENT', value: _paymentLabel(order.paymentMethod)),
      _InfoTile(label: 'TOTAL', value: '$currency${order.total}'),
      _InfoTile(
        label: 'ITEMS',
        value: order.itemCount == 1 ? '1 item' : '${order.itemCount} items',
      ),
      if (order.deliverySlot != null)
        _InfoTile(label: 'DELIVERY SLOT', value: order.deliverySlot!),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkProductCardColor
            : AppColors.mainLightContainerBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #${order.orderNumber}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(order.customerName, style: theme.textTheme.bodyMedium),
              if (order.customerPhone.isNotEmpty) ...[
                Text(' · ', style: theme.textTheme.bodyMedium),
                GestureDetector(
                  onTap: () =>
                      launchUrl(Uri.parse('tel:${order.customerPhone}')),
                  child: Text(
                    order.customerPhone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (order.customerAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              order.customerAddress,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tile in tiles) SizedBox(width: width, child: tile),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _paymentLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cod':
        return 'Cash on delivery';
      case '':
        return '—';
      default:
        return method[0].toUpperCase() + method.substring(1);
    }
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSubCategoryCardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.hintColor,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final PendingOrderItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = HiveStorage.currencySymbol;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
          ),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48,
              height: 48,
              child: item.image != null
                  ? CachedNetworkImage(
                      imageUrl: item.image!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const _ItemPlaceholder(),
                      placeholder: (_, _) => const _ItemPlaceholder(),
                    )
                  : const _ItemPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (item.variant != null) item.variant!,
                    'Qty ${item.quantity}',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$currency${item.subtotal}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemPlaceholder extends StatelessWidget {
  const _ItemPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.stepCurrentBgColor,
      child: const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.primaryColor,
        size: 22,
      ),
    );
  }
}

class _AcceptBar extends StatelessWidget {
  final PendingOrder order;
  final bool isAccepting;
  final String? errorMessage;

  const _AcceptBar({
    required this.order,
    required this.isAccepting,
    required this.errorMessage,
  });

  Future<void> _accept(BuildContext context) async {
    final accepted = await context.read<IncomingOrdersCubit>().accept(order);
    if (!accepted || !context.mounted) return;

    context.read<OrdersBloc>().add(RefreshOrders());
    context.read<NotificationListBloc>().add(FetchUnreadCount());
    final store = context.read<StoreSwitcherCubit>().state.selectedStore;
    if (store != null) {
      context.read<HomePageBloc>().add(FetchHomePageData(storeId: store.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorMessage != null) ...[
            Text(
              "Couldn't accept this order. $errorMessage",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: isAccepting ? null : () => _accept(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                disabledBackgroundColor: Colors.green.shade600.withValues(
                  alpha: 0.7,
                ),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isAccepting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      errorMessage != null
                          ? 'Retry accept'
                          : 'Accept and prepare order',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
