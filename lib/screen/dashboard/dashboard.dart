import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';

class Dashboard extends StatefulWidget {
  final int index;
  final StatefulNavigationShell navigationShell;

  const Dashboard({
    super.key,
    required this.index,
    required this.navigationShell,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  /// Timestamp of the last back-press while already on the Home tab.
  DateTime? _lastBackPressedAt;

  /// How long the "Press back again to exit" window stays open.
  static const Duration _exitTimeout = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    _scaleController.forward().then((_) => _scaleController.reverse());

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  Future<bool> _onPopInvoked(AppLocalizations? l10n) async {
    final currentIndex = widget.navigationShell.currentIndex;
    if (currentIndex != 0) {
      widget.navigationShell.goBranch(0);
      _lastBackPressedAt = null;
      return false;
    }

    final now = DateTime.now();

    if (_lastBackPressedAt != null &&
        now.difference(_lastBackPressedAt!) < _exitTimeout) {
      return true;
    }

    _lastBackPressedAt = now;

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      showCustomSnackbar(
        context: context,
        message: l10n?.pressAgainToExit ?? 'Press again to exit',
      );
    }

    return false;
  }

  Widget _buildAnimatedIcon({
    required String activeSvg,
    required String inactiveSvg,
    required bool isActive,
    required ScreenType screenType,
    required Color activeColor,
  }) {
    return AnimatedScale(
      scale: isActive ? _scaleAnimation.value : 1.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedCrossFade(
        firstChild: SvgPicture.asset(
          inactiveSvg,
          width: UIUtils.bottomNavIconInactive(screenType),
          height: UIUtils.bottomNavIconInactive(screenType),
          colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
        ),
        secondChild: SvgPicture.asset(
          activeSvg,
          width: UIUtils.bottomNavIconActive(screenType),
          height: UIUtils.bottomNavIconActive(screenType),
          colorFilter: ColorFilter.mode(activeColor, BlendMode.srcIn),
        ),
        crossFadeState: isActive
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.tertiary;
    final bgColor = theme.colorScheme.surface;
    final l10n = AppLocalizations.of(context);

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        final shouldExit = await _onPopInvoked(l10n);
        if (shouldExit && mounted) {
          // Close the app cleanly
          SystemNavigator.pop();
        }
      },
      child: BlocListener<StoreSwitcherCubit, StoreSwitcherState>(
        listenWhen: (previous, current) =>
            previous.selectedStore?.id != current.selectedStore?.id,
        listener: (context, state) {
          if (state.selectedStore != null) {
            context.read<OrdersBloc>().add(
                  RefreshOrders(storeId: state.selectedStore?.id),
                );
          }
        },
        child: Scaffold(
          body: widget.navigationShell,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: widget.index,
          onTap: _onTap,
          selectedItemColor: activeColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: bgColor,
          elevation: 0,
          selectedFontSize: UIUtils.bottomNavFontSize(screenType),
          unselectedFontSize: UIUtils.bottomNavFontSize(screenType),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          iconSize: UIUtils.bottomNavIconInactive(screenType),
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: UIUtils.bottomNavPadding(screenType),
                child: _buildAnimatedIcon(
                  activeSvg: ImagesPath.homeActive,
                  inactiveSvg: ImagesPath.homeInactive,
                  isActive: widget.index == 0,
                  screenType: screenType,
                  activeColor: activeColor,
                ),
              ),
              label: l10n?.home ?? "Home",
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: UIUtils.bottomNavPadding(screenType),
                child: _buildAnimatedIcon(
                  activeSvg: ImagesPath.orderActive,
                  inactiveSvg: ImagesPath.orderInactive,
                  isActive: widget.index == 1,
                  screenType: screenType,
                  activeColor: activeColor,
                ),
              ),
              label: l10n?.orders ?? "Orders",
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: UIUtils.bottomNavPadding(screenType),
                child: _buildAnimatedIcon(
                  activeSvg: ImagesPath.productsActive,
                  inactiveSvg: ImagesPath.productsInactive,
                  isActive: widget.index == 2,
                  screenType: screenType,
                  activeColor: activeColor,
                ),
              ),
              label: l10n?.products ?? "Products",
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: UIUtils.bottomNavPadding(screenType),
                child: _buildAnimatedIcon(
                  activeSvg: ImagesPath.moreActive,
                  inactiveSvg: ImagesPath.moreInactive,
                  isActive: widget.index == 3,
                  screenType: screenType,
                  activeColor: activeColor,
                ),
              ),
              label: l10n?.more ?? "More",
            ),
          ],
        ),
      ),
    ),
  );
  }
}
