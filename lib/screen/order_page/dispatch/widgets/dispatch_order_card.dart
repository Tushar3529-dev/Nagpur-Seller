import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/utils/time_utils.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import '../model/dispatch_model.dart';
import 'dispatch_status_badge.dart';
import 'self_deliver_sheet.dart';

class DispatchOrderCard extends StatelessWidget {
  final DispatchOrder order;
  final bool isPending;
  const DispatchOrderCard({
    super.key,
    required this.order,
    this.isPending = false,
  });
  void _openOrder(BuildContext context) {
    for (final item in context.read<OrdersBloc>().state.items) {
      if (item.orderNumber == order.orderNumber) {
        context.pushNamed(
          AppRoutes.orderDetails,
          pathParameters: {'id': item.sellerOrderId.toString()},
        );
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenType = context.screenType;
    final name =
        order.deliveryBoyName ??
        (order.deliveryBoyId == null
            ? l10n?.dispatchRiderFallback ?? 'Rider'
            : l10n?.dispatchRiderId(order.deliveryBoyId!) ??
                  'rider #${order.deliveryBoyId}');
    final riderLine = switch (order.status) {
      DispatchStatus.awaitingRiderAcceptance =>
        l10n?.dispatchOfferedTo(name) ?? 'Offered to $name',
      DispatchStatus.riderAssigned =>
        l10n?.dispatchRiderName(name) ?? 'Rider: $name',
      DispatchStatus.noNearbyRiders || DispatchStatus.waitingForDispatch =>
        l10n?.dispatchNearbyRiders(order.nearbyAvailableRiders) ??
            '${order.nearbyAvailableRiders} riders nearby',
      DispatchStatus.sellerSelfDelivery =>
        l10n?.dispatchSelfDeliveryInfo ??
            "You're responsible for delivering this order. Completing it in the app isn't available yet.",
      DispatchStatus.unknown => '',
    };
    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: UIUtils.body(screenType)),
            ),
          ),
        ],
      ),
    );
    final buttonLabel = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPending) ...[
          const CustomLoadingIndicator(size: 18, strokeWidth: 2),
          const SizedBox(width: 8),
        ],
        Flexible(child: Text(l10n?.dispatchDeliverMyself ?? 'Deliver myself')),
      ],
    );
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIUtils.radiusLG(screenType)),
        side: BorderSide(
          color: order.status.needsAction
              ? Colors.red
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: () => _openOrder(context),
        borderRadius: BorderRadius.circular(UIUtils.radiusLG(screenType)),
        child: Padding(
          padding: UIUtils.cardPadding(screenType),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${order.orderNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: DispatchStatusBadge(order: order)),
                ],
              ),
              line(Icons.storefront_outlined, order.pickup),
              line(Icons.qr_code_2, order.bagBarcode),
              if (riderLine.isNotEmpty)
                line(
                  order.status == DispatchStatus.sellerSelfDelivery
                      ? Icons.info_outline
                      : Icons.person_outline,
                  riderLine,
                ),
              if (order.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    TimeUtils.formatTimeAgo(
                      order.createdAt!.toIso8601String(),
                      context,
                      type: TimeFormatType.order,
                    ),
                    style: TextStyle(
                      fontSize: UIUtils.caption(screenType),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (isPending)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: CustomLoadingIndicator(size: 18, strokeWidth: 2),
                ),
              if (order.status.canSelfDeliver &&
                  PermissionChecker.hasPermission(
                    AppPermissions.orderUpdateStatus,
                  ))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: order.status.needsAction
                      ? FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                          ),
                          onPressed: isPending
                              ? null
                              : () => SelfDeliverSheet.show(context, order),
                          child: buttonLabel,
                        )
                      : OutlinedButton(
                          onPressed: isPending
                              ? null
                              : () => SelfDeliverSheet.show(context, order),
                          child: buttonLabel,
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
