import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/more_page/view/tax_group/bloc/tax_group_bloc.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';

import '../../../../../widgets/custom/card_shimmers.dart';

class TaxGroupsPage extends StatefulWidget {
  const TaxGroupsPage({super.key});

  @override
  State<TaxGroupsPage> createState() => _TaxGroupsPageState();
}

class _TaxGroupsPageState extends State<TaxGroupsPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaxGroupsBloc>().add(LoadTaxGroupsInitial());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<TaxGroupsBloc>().add(LoadMoreTaxGroups());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ScreenSizeBloc, ScreenSizeState>(
      builder: (context, screenSizeState) {
        final screenType = screenSizeState.screenType;

        return CustomScaffold(
          showAppbar: true,
          title: l10n?.taxGroup ?? 'Tax Groups',
          centerTitle: true,
          body: BlocBuilder<TaxGroupsBloc, TaxGroupsState>(
            builder: (context, state) {
              if ((state.isInitialLoading || state.isRefreshing) &&
                  state.items.isEmpty) {
                return ListView.separated(
                  padding: UIUtils.cardsPadding(screenType),
                  separatorBuilder: (context, index) =>
                      SizedBox(height: UIUtils.gapMD(screenType)),
                  itemCount: 10,
                  itemBuilder: (context, index) => CardShimmer(
                    type: 'taxGroup',
                    screenType: screenType,
                  ),
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
                    context.read<TaxGroupsBloc>().add(RefreshTaxGroups());
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
                    context.read<TaxGroupsBloc>().add(RefreshTaxGroups());
                  },
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: UIUtils.pagePadding(screenType),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "${l10n?.total ?? 'Total'} ${l10n?.taxGroup ?? 'Tax Groups'} (${state.total ?? state.items.length})",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: UIUtils.body(screenType),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primaryColor,
                      onRefresh: () async {
                        context.read<TaxGroupsBloc>().add(RefreshTaxGroups());
                      },
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: UIUtils.cardsPadding(screenType),
                        separatorBuilder: (context, index) =>
                            SizedBox(height: UIUtils.gapMD(screenType)),
                        itemCount:
                            state.items.length + (state.isPaginating ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.items.length) {
                            return CardShimmer(
                              type: 'taxGroup',
                              screenType: screenType,
                            );
                          }
                          return CustomCard(
                            type: CardType.taxGroup,
                            data: state.items[index].toJson(),
                            screenType: screenType,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
