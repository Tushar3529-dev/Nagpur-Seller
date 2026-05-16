import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/model/attributes_model.dart'
    as attr_model;
import 'package:hyper_local_seller/screen/more_page/view/attributes/model/attribute_values_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/bloc/attribute_values_bloc/attribute_values_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/widgets/add_attribute_value_dialog.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';

class AttributeValuesPage extends StatefulWidget {
  final attr_model.Attribute attribute;
  const AttributeValuesPage({super.key, required this.attribute});

  @override
  State<AttributeValuesPage> createState() => _AttributeValuesPageState();
}

class _AttributeValuesPageState extends State<AttributeValuesPage> {
  @override
  void initState() {
    super.initState();
    context.read<AttributeValuesBloc>().add(
      LoadAttributeValues(widget.attribute.id),
    );
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
          title: l10n?.attributeValues ?? 'Attribute Values',
          body: RefreshIndicator(
            color: AppColors.primaryColor,
            onRefresh: () async {
              context.read<AttributeValuesBloc>().add(
                LoadAttributeValues(widget.attribute.id),
              );
            },
            child: BlocConsumer<AttributeValuesBloc, AttributeValuesState>(
              listener: (context, state) {
                if (state is AttributeValuesFailure) {
                  showCustomSnackbar(
                    context: context,
                    message: state.error,
                    isError: true,
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state is AttributeValuesLoading;
                final data = (state is AttributeValuesLoaded)
                    ? state.data
                    : (state is AttributeValuesFailure)
                    ? state.data
                    : null;
                final values = data?.values ?? [];

                if (!isLoading && values.isEmpty) {
                  return EmptyStateWidget(
                    svgPath: ImagesPath.noProductFoundSvg,
                    title:
                        l10n?.noAttributeValuesFound ??
                        'No attribute value found',
                    subtitle:
                        l10n?.noAttributeValuesAddedYet ??
                        'You have not added any attribute value yet',
                    actionText: l10n?.addValues ?? 'Add Values',
                    onAction: () => _showAddDialog(context, l10n),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: UIUtils.pagePadding(screenType),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          isLoading
                              ? CustomShimmer(
                                  width: 150,
                                  height: UIUtils.body(screenType),
                                )
                              : Text(
                                  "${widget.attribute.title} (${values.length})",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: UIUtils.body(screenType),
                                  ),
                                ),
                          isLoading
                              ? CustomShimmer(
                                  width: 100,
                                  height: 40,
                                  borderRadius: BorderRadius.circular(
                                    UIUtils.radiusMD(screenType),
                                  ),
                                )
                              : SecondaryButton(
                                  text: l10n?.addValue ?? 'Add Value',
                                  icon: Icons.add,
                                  onPressed: () =>
                                      _showAddDialog(context, l10n),
                                ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: UIUtils.cardsPadding(screenType),
                        separatorBuilder: (context, index) =>
                            SizedBox(height: UIUtils.gapMD(screenType)),
                        itemCount: isLoading ? 10 : values.length,
                        itemBuilder: (context, index) {
                          if (isLoading) {
                            return CardShimmer(
                              type: 'attributeValue',
                              screenType: screenType,
                            );
                          }
                          final value = values[index];
                          return CustomCard(
                            type: CardType.attributeValue,
                            screenType: screenType,
                            data: {
                              'id': value.id,
                              'name': value.title,
                              'swatch_value': value.swatcheValue,
                              'swatch_type': widget.attribute.swatcheType,
                              'date': value.createdAt,
                            },
                            onEdit: () =>
                                _showAddDialog(context, l10n, value: value),
                            onDelete: () =>
                                _confirmDelete(context, value.id, l10n),
                          );
                        },
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

  void _showAddDialog(
    BuildContext context,
    AppLocalizations? l10n, {
    AttributeValue? value,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddAttributeValueDialog(attribute: widget.attribute, value: value),
    );
  }

  void _confirmDelete(
    BuildContext context,
    int valueId,
    AppLocalizations? l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.delete ?? 'Delete'),
        content: Text(
          l10n?.deleteAttributeValueConfirmation ??
              'Are you sure you want to delete this attribute value?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AttributeValuesBloc>().add(
                DeleteAttributeValue(widget.attribute.id, valueId),
              );
              Navigator.pop(context);
            },
            child: Text(
              l10n?.delete ?? 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
