import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/bloc/attributes_bloc/attributes_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/model/attributes_model.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/widgets/add_attribute_dialog.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';

class AttributesPage extends StatefulWidget {
  const AttributesPage({super.key});

  @override
  State<AttributesPage> createState() => _AttributesPageState();
}

class _AttributesPageState extends State<AttributesPage> {
  final ScrollController _scrollController = ScrollController();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    context.read<AttributesBloc>().add(LoadAttributesInitial(search: null));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<AttributesBloc>().add(LoadMoreAttributes());
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
          centerTitle: true,
          showAppbar: true,
          title: l10n?.attributes ?? "Attributes",
          isHaveSearch: true,
          onSearchChanged: (value) {
            _debouncer.run(() {
              context.read<AttributesBloc>().add(SearchAttributes(value));
            });
          },
          body: BlocListener<AttributesBloc, AttributesState>(
            listenWhen: (previous, current) =>
                previous.operationSuccess != current.operationSuccess &&
                current.operationSuccess != null,
            listener: (context, state) {
              if (state.operationSuccess == true) {
                showCustomSnackbar(
                  context: context,
                  message: state.operationMessage ?? "Operation successful",
                );
                context.read<AttributesBloc>().add(
                  ClearAttributeOperationState(),
                );
              } else if (state.operationSuccess == false) {
                showCustomSnackbar(
                  context: context,
                  message: state.error ?? state.operationMessage ?? 'Operation failed',
                  isError: true,
                );
                context.read<AttributesBloc>().add(
                  ClearAttributeOperationState(),
                );
              } else if (state.error != null && state.items.isNotEmpty) {
                // Global error (background refresh failed)
                showCustomSnackbar(
                  context: context,
                  message: state.error!,
                  isError: true,
                );
                context.read<AttributesBloc>().add(
                  ClearAttributeOperationState(),
                );
              }
            },
            child: BlocBuilder<AttributesBloc, AttributesState>(
              builder: (context, state) {
                // Removed early return for initial loading to show shimmers in the layout

                final items = state.items;
                final hasMore = state.hasMore;
                final total = state.total ?? 0;
                final isPaginating = state.isPaginating;

                if (state.error != null && items.isEmpty) {
                  return EmptyStateWidget(
                    svgPath: ImagesPath.noOrderFoundSvg,
                    title:
                        l10n?.somethingWentWrong ??
                        'Seems like there is some issue',
                    subtitle: l10n?.tryAgainLater ?? 'Please try again later',
                    actionText: l10n?.tryAgain ?? 'Try Again',
                    onAction: () {
                      context.read<AttributesBloc>().add(RefreshAttributes());
                    },
                  );
                }

                if (!state.isInitialLoading && !state.isRefreshing && items.isEmpty) {
                  return EmptyStateWidget(
                    svgPath: ImagesPath.noProductFoundSvg,
                    title: l10n?.noAttributesFound ?? 'No attribute found',
                    subtitle:
                        l10n?.noAttributesAddedYet ??
                        'You have not added any attribute yet',
                    actionText: l10n?.addAttribute ?? 'Add Attribute',
                    onAction: () {
                      if (!PermissionChecker.hasPermission(
                        AppPermissions.attributeCreate,
                      )) {
                        showCustomSnackbar(
                          context: context,
                          message:
                              l10n?.noPermissionCreateAttribute ??
                              "You don't have permission to add attributes",
                          isWarning: true,
                        );
                        return;
                      }
                      if (!DemoGuard.shouldProceed(context)) return;

                      _showAddDialog(context);
                    },
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: UIUtils.pagePadding(screenType),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          (state.isInitialLoading || state.isRefreshing) && state.items.isEmpty
                              ? CustomShimmer(
                                  width: 150,
                                  height: UIUtils.body(screenType),
                                )
                              : Text(
                                  l10n?.totalAttributesWithCount(total) ??
                                      "Total Attributes ($total)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: UIUtils.body(screenType),
                                  ),
                                ),
                          Row(
                            children: [
                              if (state.isRefreshing)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8.0),
                                  child: CustomLoadingIndicator(
                                    size: 16,
                                    strokeWidth: 2,
                                  ),
                                ),

                              (state.isInitialLoading || state.isRefreshing) && state.items.isEmpty
                                  ? CustomShimmer(
                                      width: 60,
                                      height: 35,
                                      borderRadius: BorderRadius.circular(
                                        UIUtils.radiusMD(screenType),
                                      ),
                                    )
                                  : SecondaryButton(
                                      text:
                                          l10n?.addAttribute ?? 'Add Attribute',
                                      icon: Icons.add,
                                      onPressed: () {
                                        if (!PermissionChecker.hasPermission(
                                          AppPermissions.attributeCreate,
                                        )) {
                                          showCustomSnackbar(
                                            context: context,
                                            message:
                                                l10n?.noPermissionCreateAttribute ??
                                                "You don't have permission to add attributes",
                                            isWarning: true,
                                          );
                                          return;
                                        }
                                        if (!DemoGuard.shouldProceed(context)) {
                                          return;
                                        }

                                        _showAddDialog(context);
                                      },
                                      height: 35,
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primaryColor,
                        onRefresh: () async {
                          context.read<AttributesBloc>().add(
                            RefreshAttributes(),
                          );
                        },
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: UIUtils.cardsPadding(screenType),
                          separatorBuilder: (context, index) =>
                              SizedBox(height: UIUtils.gapMD(screenType)),
                          itemCount:
                              (state.isInitialLoading || state.isRefreshing) && state.items.isEmpty
                              ? 10
                              : items.length +
                                    (hasMore ? (isPaginating ? 10 : 1) : 0),
                          itemBuilder: (context, index) {
                            if ((state.isInitialLoading || state.isRefreshing) && state.items.isEmpty) {
                              return CardShimmer(
                                type: 'attribute',
                                screenType: screenType,
                              );
                            }
                            if (index >= items.length) {
                              return CardShimmer(
                                type: 'attribute',
                                screenType: screenType,
                              );
                            }

                            final attribute = items[index];
                            return CustomCard(
                              type: CardType.attribute,
                              screenType: screenType,
                              data: {
                                'id': attribute.id,
                                'name': attribute.title,
                                'swatch_type': attribute.swatcheType,
                                'values_count': attribute.valuesCount,
                                'date': attribute.createdAt,
                              },
                              onTap: () {
                                context.pushNamed(
                                  AppRoutes.attributeValues,
                                  extra: attribute,
                                );
                              },
                              onEdit: () {
                                if (!PermissionChecker.hasPermission(
                                  AppPermissions.attributeEdit,
                                )) {
                                  showCustomSnackbar(
                                    context: context,
                                    message:
                                        l10n?.noPermissionEditAttribute ??
                                        "You don't have permission to edit attributes",
                                    isWarning: true,
                                  );
                                  return;
                                }
                                if (!DemoGuard.shouldProceed(context)) return;

                                _showAddDialog(context, attribute: attribute);
                              },
                              onDelete: () {
                                if (!PermissionChecker.hasPermission(
                                  AppPermissions.attributeDelete,
                                )) {
                                  showCustomSnackbar(
                                    context: context,
                                    message:
                                        l10n?.noPermissionDeleteAttribute ??
                                        "You don't have permission to delete attributes",
                                    isWarning: true,
                                  );
                                  return;
                                }
                                if (!DemoGuard.shouldProceed(context)) return;
                                context.read<AttributesBloc>().add(
                                  DeleteAttribute(attribute.id),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, {Attribute? attribute}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAttributeDialog(attribute: attribute),
    );
  }
}
