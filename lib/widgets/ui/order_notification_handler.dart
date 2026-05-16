import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/order_page/repo/order_repo.dart';
import 'package:hyper_local_seller/screen/order_page/model/order_details_model.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/screen/order_page/widgets/order_acceptance_bottom_sheet.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';

class OrderNotificationHandler {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static void showOrderAcceptanceBottomSheet(
    BuildContext context,
    Map<String, dynamic> payload,
  ) {
    final orderId = int.tryParse(payload['seller_order_id']?.toString() ?? '0') ?? 0;

    if (orderId == 0) {
      debugPrint('Invalid order ID in notification payload');
      return;
    }

    // Play in-app notification sound
    _playNotificationSound();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext bottomSheetContext) {
        return _OrderAcceptanceWrapper(orderId: orderId, payload: payload);
      },
    ).then((_) {
      // Re-trigger order refresh when bottom sheet is closed (swiped down, auto-closed, or closed via button)
      // This ensures that even if the first refresh on notification arrival was too early (DB delay),
      // the list will definitely update now.
      if (context.mounted) {
        debugPrint(
          'OrderAcceptanceBottomSheet closed, refreshing orders list...',
        );
        // Small delay to be safe
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            context.read<OrdersBloc>().add(RefreshOrders());
          }
        });
      }
    });
  }

  static void _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource(AudioPath.inAppNotificationSound));
    } catch (e) {
      debugPrint('Error playing in-app notification sound: $e');
    }
  }
}

class _OrderAcceptanceWrapper extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic> payload;

  const _OrderAcceptanceWrapper({required this.orderId, required this.payload});

  @override
  State<_OrderAcceptanceWrapper> createState() =>
      _OrderAcceptanceWrapperState();
}

class _OrderAcceptanceWrapperState extends State<_OrderAcceptanceWrapper> {
  OrderDetailsData? _orderData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    const maxRetries = 5;
    const retryDelays = [2000, 3000, 4000, 5000, 6000]; // ms between retries

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Wait before each attempt to give the DB time to persist the order
        final delayMs = retryDelays[attempt];
        debugPrint(
          'Fetching order details (attempt ${attempt + 1}/$maxRetries) after ${delayMs}ms delay...',
        );
        await Future.delayed(Duration(milliseconds: delayMs));

        if (!mounted) return;

        final repo = context.read<OrdersRepo>();
        final response = await repo.getOrderDetails(widget.orderId);

        if (response != null) {
          final orderDetailsResponse = OrderDetailsResponse.fromJson(response);

          if (orderDetailsResponse.success == true &&
              orderDetailsResponse.data != null) {
            if (mounted) {
              setState(() {
                _orderData = orderDetailsResponse.data;
                _isLoading = false;
              });
            }
            return; // Success — exit retry loop
          }

          // If order not found yet and retries remain, keep trying
          final isLastAttempt = attempt == maxRetries - 1;
          if (isLastAttempt) {
            if (mounted) {
              setState(() {
                _error =
                    'There is some issue getting order details. Please visit the orders page.';
                _isLoading = false;
              });
              _autoCloseBottomSheet();
            }
          } else {
            debugPrint(
              'Order not ready yet, retrying... (${attempt + 1}/$maxRetries)',
            );
          }
        }
      } catch (e) {
        debugPrint('Error fetching order details (attempt ${attempt + 1}): $e');
        if (attempt == maxRetries - 1 && mounted) {
          setState(() {
            _error =
                'There is some issue getting order details. Please visit the orders page.';
            _isLoading = false;
          });
          _autoCloseBottomSheet();
        }
      }
    }
  }

  void _autoCloseBottomSheet() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
        context.go(AppRoutes.orders);
        // Refresh will be handled by the .then block of showModalBottomSheet
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        height: 350,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center, // ← key change
          children: [
            // Drag handle at top
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const Expanded(
              child: Center(
                child: CustomLoadingIndicator(color: AppColors.primaryColor),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null || _orderData == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.info_outline, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'There is some issue getting order details. Please visit the orders page.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Closing automatically...',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (mounted) {
                    context.go(AppRoutes.orders);
                    // Refresh will be handled by the .then block of showModalBottomSheet
                  }
                },
                text: AppLocalizations.of(context)?.close ?? 'Close',
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    // Get first item details
    final firstItem = _orderData!.items?.first;
    final productImage = widget.payload['image']?.toString() ?? '';
    final productTitle = firstItem?.product?.title ?? 'Order Item';
    final quantity = firstItem?.quantity ?? 1;
    final price = firstItem?.price ?? '0';
    final deliveryType = _orderData!.isRushedOrder == 1
        ? 'Rush Delivery'
        : 'Standard Delivery';
    final totalPrice = _orderData!.totalPrice;
    final paymentMethod = _orderData!.paymentMethod;

    debugPrint('PAY LOAD ::::: ${widget.payload}');
    debugPrint('ID ::::: ${_orderData?.id}');
    debugPrint('PAYLOAD ID ::::: ${widget.orderId}');

    return OrderAcceptanceBottomSheet(
      orderId: widget.orderId,
      orderIdText: _orderData!.uuid,
      productImage: productImage,
      productTitle: productTitle,
      quantity: quantity,
      price: price,
      deliveryType: deliveryType,
      totalPrice: totalPrice,
      paymentMethod: paymentMethod,

      onViewOrder: () {
        Navigator.of(context).pop();

        if (mounted) {
          context.pushNamed(
            AppRoutes.orderDetails,

            pathParameters: {'id': widget.orderId.toString()},
          );

          // Refresh will be handled by the .then block of showModalBottomSheet
        }
      },
      // onAccept: () async {
      //   Navigator.of(context).pop();
      //   try {
      //     final repo = context.read<OrdersRepo>();
      //     await repo.updateOrderStatus(
      //       _orderData?.items?.first.id ?? widget.orderId,
      //       'accept',
      //     );
      //
      //     if (context.mounted) {
      //       context.read<OrdersBloc>().add(RefreshOrders());
      //       showCustomSnackbar(
      //         context: context,
      //         message: 'Order accepted successfully',
      //       );
      //     }
      //   } catch (e) {
      //     if (context.mounted) {
      //       showCustomSnackbar(
      //         context: context,
      //         message: e.toString(),
      //         isError: true,
      //       );
      //       // ScaffoldMessenger.of(context).showSnackBar(
      //       //   SnackBar(
      //       //     content: Text('Error accepting order: $e'),
      //       //     backgroundColor: Colors.red,
      //       //   ),
      //       // );
      //     }
      //   }
      // },
      // onReject: () async {
      //   Navigator.of(context).pop();
      //   try {
      //     final repo = context.read<OrdersRepo>();
      //     await repo.updateOrderStatus(
      //       _orderData?.items?.first.id ?? widget.orderId,
      //       'reject',
      //     );
      //
      //     if (context.mounted) {
      //       context.read<OrdersBloc>().add(RefreshOrders());
      //       showCustomSnackbar(
      //         context: context,
      //         message: 'Order rejected successfully',
      //       );
      //       // ScaffoldMessenger.of(context).showSnackBar(
      //       //   const SnackBar(
      //       //     content: Text('Order rejected'),
      //       //     backgroundColor: Colors.orange,
      //       //   ),
      //       // );
      //     }
      //   } catch (e) {
      //     if (context.mounted) {
      //       showCustomSnackbar(
      //         context: context,
      //         message: e.toString(),
      //         isError: true,
      //       );
      //       // ScaffoldMessenger.of(context).showSnackBar(
      //       //   SnackBar(
      //       //     content: Text('Error rejecting order: $e'),
      //       //     backgroundColor: Colors.red,
      //       //   ),
      //       // );
      //     }
      //   }
      // },
    );
  }
}
