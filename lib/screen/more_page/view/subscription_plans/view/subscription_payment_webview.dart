import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/buy_subscription/buy_subscription_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/buy_subscription/buy_subscription_state.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/current_subscription/current_subscription_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

class SubscriptionPaymentWebView extends StatefulWidget {
  final String url;
  final String title;

  const SubscriptionPaymentWebView({
    super.key,
    required this.url,
    this.title = 'Payment',
  });

  @override
  State<SubscriptionPaymentWebView> createState() =>
      _SubscriptionPaymentWebViewState();
}

class _SubscriptionPaymentWebViewState
    extends State<SubscriptionPaymentWebView> {
  double _progress = 0;
  InAppWebViewController? _webViewController;

  @override
  Widget build(BuildContext context) {
    return BlocListener<BuySubscriptionBloc, BuySubscriptionState>(
      listener: (context, state) {
        if (state is BuySubscriptionSuccess) {
          // showCustomSnackbar(
          //   context: context,
          //   message: 'Payment Successful!\nYour subscription is now active.',
          // );
          context.read<CurrentSubscriptionBloc>().add(
            FetchCurrentSubscription(),
          );

          context.go(AppRoutes.home);
        } else if (state is BuySubscriptionFailure) {
          showCustomSnackbar(
            context: context,
            message: state.message,
            isError: true,
          );
        }
      },
      child: CustomScaffold(
        showAppbar: true,
        title: widget.title,
        centerTitle: true,
        appBarActions: [
          IconButton(
            onPressed: () {
              _webViewController?.reload();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
                supportMultipleWindows: true,
                javaScriptCanOpenWindowsAutomatically: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
              onCreateWindow: (controller, createWindowAction) async {
                debugPrint(
                  "DEBUG: onCreateWindow triggered with windowId: ${createWindowAction.windowId}",
                );
                showGeneralDialog(
                  context: context,
                  barrierDismissible: false,
                  barrierLabel: "Payment Authentication",
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return SafeArea(
                      child: Scaffold(
                        appBar: AppBar(
                          title: const Text("Payment Authentication"),
                          leading: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                          elevation: 0,
                        ),
                        body: InAppWebView(
                          windowId: createWindowAction.windowId,
                          onCloseWindow: (controller) {
                            debugPrint("DEBUG: onCloseWindow triggered");
                            Navigator.pop(context);
                          },
                          onProgressChanged: (controller, progress) {
                            if (progress == 100) {
                              debugPrint("DEBUG: Popup Loaded");
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
                return true;
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url;
                debugPrint("DEBUG: shouldOverrideUrlLoading: $uri");
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) async {
                debugPrint("DEBUG: onLoadStop: $url");
              },
            ),
            if (_progress < 1.0)
              LinearProgressIndicator(
                value: _progress,
                color: Theme.of(context).primaryColor,
                backgroundColor: Colors.transparent,
              ),
          ],
        ),
      ),
    );
  }
}
