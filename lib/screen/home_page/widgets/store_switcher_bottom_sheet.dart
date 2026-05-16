import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoreSwitcherBottomSheet extends StatelessWidget {
  const StoreSwitcherBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ScreenSizeBloc, ScreenSizeState>(
      builder: (context, screenSizeState) {
        final screenType = screenSizeState.screenType;
        return BlocBuilder<StoreSwitcherCubit, StoreSwitcherState>(
          builder: (context, state) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(UIUtils.radiusLG(screenType)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: UIUtils.gapSM(screenType)),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: UIUtils.pagePadding(screenType),
                    child: Text(
                      l10n?.switchStore ?? "Switch Store",
                      style: TextStyle(
                        fontSize: UIUtils.pageTitle(screenType),
                        fontWeight: UIUtils.bold,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(
                        left: UIUtils.gapMD(screenType),
                        right: UIUtils.gapMD(screenType),
                        bottom: UIUtils.gapLG(screenType),
                      ),
                      itemCount: state.stores.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: UIUtils.gapSM(screenType)),
                      itemBuilder: (context, index) {
                        final store = state.stores[index];
                        final isSelected = state.selectedStore?.id == store.id;

                        return ListTile(
                          onTap: () {
                            context.read<StoreSwitcherCubit>().selectStore(
                              store,
                            );
                            Navigator.pop(context);
                          },
                          contentPadding: UIUtils.tilePadding(screenType),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              UIUtils.radiusMD(screenType),
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                              width: isSelected ? 1.5 : 0.5,
                            ),
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              UIUtils.radiusSM(screenType),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: store.logo ?? '',
                              width: UIUtils.avatarMD(screenType),
                              height: UIUtils.avatarMD(screenType),
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.store),
                            ),
                          ),
                          title: Text(
                            store.name,
                            style: TextStyle(
                              fontSize: UIUtils.tileTitle(screenType),
                              fontWeight: isSelected
                                  ? UIUtils.bold
                                  : UIUtils.semiBold,
                            ),
                          ),
                          subtitle: Text(
                            store.address ?? '',
                            style: TextStyle(
                              fontSize: UIUtils.caption(screenType),
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).primaryColor,
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StoreSwitcherBottomSheet(),
    );
  }
}
