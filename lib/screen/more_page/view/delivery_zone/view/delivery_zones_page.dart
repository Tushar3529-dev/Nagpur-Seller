import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/bloc/delivery_zone_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/model/delivery_zone_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/view/delivery_zone_details_page.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';

class DeliveryZonesPage extends StatefulWidget {
  const DeliveryZonesPage({super.key});

  @override
  State<DeliveryZonesPage> createState() => _DeliveryZonesPageState();
}

class _DeliveryZonesPageState extends State<DeliveryZonesPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<DeliveryZoneBloc>().add(LoadDeliveryZonesInitial());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<DeliveryZoneBloc>().add(LoadMoreDeliveryZones());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomScaffold(
      title: "Delivery Zones",
      showAppbar: true,
      isHaveSearch: true,
      searchController: _searchController,
      onSearchChanged: (value) {
        _debouncer.run(() {
          context.read<DeliveryZoneBloc>().add(SearchDeliveryZones(value));
        });
      },
      searchHint: "Search",
      body: BlocBuilder<ScreenSizeBloc, ScreenSizeState>(
        builder: (context, screenTypeState) {
          final screenType = screenTypeState.screenType;
          return BlocBuilder<DeliveryZoneBloc, DeliveryZoneState>(
            builder: (context, state) {
              if ((state.isInitialLoading || state.isRefreshing) &&
                  state.items.isEmpty) {
                return ListView.separated(
                  padding: UIUtils.cardsPadding(screenType),
                  separatorBuilder: (context, index) =>
                      SizedBox(height: UIUtils.gapMD(screenType)),
                  itemCount: 5,
                  itemBuilder: (context, index) =>
                      CardShimmer(type: 'permission', screenType: screenType),
                );
              }

              if (state.error != null && state.items.isEmpty) {
                return EmptyStateWidget(
                  svgPath: ImagesPath.noOrderFoundSvg,
                  title:
                      l10n?.somethingWentWrong ??
                      'Seems like there is some issue',
                  subtitle: l10n?.tryAgainLater ?? 'Please try again later',
                  actionText: l10n?.tryAgain ?? 'Try Again',
                  onAction: () {
                    context.read<DeliveryZoneBloc>().add(
                      RefreshDeliveryZones(),
                    );
                  },
                );
              }

              if (state.items.isEmpty) {
                return EmptyStateWidget(
                  svgPath: ImagesPath.noOrderFoundSvg,
                  title:
                      l10n?.somethingWentWrong ??
                      'Seems like there is some issue',
                  subtitle: l10n?.tryAgainLater ?? 'Please try again later',
                  actionText: l10n?.tryAgain ?? 'Try Again',
                  onAction: () {
                    context.read<DeliveryZoneBloc>().add(
                      RefreshDeliveryZones(),
                    );
                  },
                );
              }

              return RefreshIndicator(
                color: AppColors.primaryColor,
                onRefresh: () async {
                  context.read<DeliveryZoneBloc>().add(RefreshDeliveryZones());
                },
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length + (state.isPaginating ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return CardShimmer(
                        type: 'permission',
                        screenType: screenType,
                      );
                    }
                    final zone = state.items[index];
                    return _ZoneListItem(zone: zone);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ZoneListItem extends StatelessWidget {
  final DeliveryZone zone;

  const _ZoneListItem({required this.zone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryZoneDetailsPage(zone: zone),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zone.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: zone.status == 'active'
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    zone.status.toUpperCase(),
                    style: TextStyle(
                      color: zone.status == 'active'
                          ? Colors.green
                          : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DetailSmallCard(
                    icon: Icons.local_shipping_outlined,
                    label: "Delivery Fee",
                    value: "₹${zone.regularDeliveryCharges ?? 0}",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailSmallCard(
                    icon: Icons.local_shipping_outlined,
                    label: "Rush Fee",
                    value: "₹${zone.rushDeliveryCharges ?? 0}",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailWideCard(
              icon: Icons.local_shipping_outlined,
              label: "Free Delivery Above",
              value: "₹${zone.freeDeliveryAmount ?? 0}",
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSmallCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailSmallCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _DetailWideCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailWideCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
