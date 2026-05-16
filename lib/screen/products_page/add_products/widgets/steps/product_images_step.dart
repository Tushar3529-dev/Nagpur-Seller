// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/service/external_link.dart';
import 'package:hyper_local_seller/utils/image_picker_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_dropdown.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_upload_area.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/custom_section_widget.dart';

class ProductImagesStep extends StatefulWidget {
  const ProductImagesStep({super.key});

  @override
  State<ProductImagesStep> createState() => _ProductImagesStepState();
}

class _ProductImagesStepState extends State<ProductImagesStep> {
  String? _mainImage;
  final List<String> _additionalImages = [];
  String? _imageFit = "cover";
  String? _videoType;

  final TextEditingController _videoLinkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final productData = context.read<AddProductBloc>().state.productData;
    _mainImage = productData.mainImage;
    _additionalImages.addAll(productData.otherImages);
    _imageFit = productData.imageFit.toLowerCase();
    _videoType = productData.videoType;
    _videoLinkController.text = productData.videoLink ?? "";
  }

  @override
  void dispose() {
    _videoLinkController.dispose();
    super.dispose();
  }

  void _updateBloc() {
    final bloc = context.read<AddProductBloc>();
    final currentData = bloc.state.productData;
    bloc.add(
      UpdateProductData(
        currentData.copyWith(
          mainImage: _mainImage,
          otherImages: _additionalImages,
          imageFit: _imageFit,
          videoType: _videoType,
        ),
      ),
    );
  }

  Future<void> _pickMainImage() async {
    final imagePath = await ImagePickerUtils.pickMedia(
      context,
      mediaType: MediaType.image,
    );
    if (imagePath != null) {
      setState(() {
        _mainImage = imagePath;
      });
      _updateBloc();
    }
  }

  Future<void> _pickAdditionalImage() async {
    final imagePath = await ImagePickerUtils.pickMedia(
      context,
      mediaType: MediaType.image,
    );
    if (imagePath != null) {
      setState(() {
        _additionalImages.add(imagePath);
      });
      _updateBloc();
    }
  }

  void _removeMainImage() {
    setState(() {
      _mainImage = null;
    });
    final bloc = context.read<AddProductBloc>();
    bloc.add(
      UpdateProductData(
        bloc.state.productData.copyWith(clearMainImage: true),
      ),
    );
  }

  void _removeAdditionalImage(int index) {
    setState(() {
      _additionalImages.removeAt(index);
    });
    _updateBloc();
  }

  Future<void> _pickVideo() async {
    final videoPath = await ImagePickerUtils.pickMedia(
      context,
      mediaType: MediaType.video,
    );
    if (videoPath != null) {
      final bloc = context.read<AddProductBloc>();
      bloc.add(
        UpdateProductData(
          bloc.state.productData.copyWith(productVideo: videoPath),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final productData = context.watch<AddProductBloc>().state.productData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(AppLocalizations.of(context)!.mainImage, isRequired: true),
        CustomUploadArea(
          hint: AppLocalizations.of(context)!.uploadImage,
          fileName: _mainImage,
          onTap: _pickMainImage,
          onRemove: _removeMainImage,
        ),
        const SizedBox(height: 20),

        _buildLabel(AppLocalizations.of(context)!.additionalImages),
        ..._additionalImages.asMap().entries.map((entry) {
          int index = entry.key;
          String path = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: CustomUploadArea(
              hint:
                  "${AppLocalizations.of(context)!.additionalImage} ${index + 1}",
              fileName: path,
              onRemove: () => _removeAdditionalImage(index),
              height: 100,
            ),
          );
        }),
        CustomUploadArea(
          hint: AppLocalizations.of(context)!.addAdditionalImages,
          onTap: _pickAdditionalImage,
          height: 100,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(
            context,
          )!.youCanSelectMultipleImagesByClickingAddButton,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 20),

        CustomDropdown<String>(
          label: AppLocalizations.of(context)!.imageFit,
          hint: AppLocalizations.of(context)!.selectImageFit,
          value: _imageFit,
          items: [
            CustomDropdownItem(
              label: AppLocalizations.of(context)!.cover,
              value: "cover",
            ),
            CustomDropdownItem(
              label: AppLocalizations.of(context)!.contain,
              value: "contain",
            ),
          ],
          onChanged: (val) {
            setState(() => _imageFit = val);
            _updateBloc();
          },
        ),
        const SizedBox(height: 20),

        CustomDropdown<String>(
          label: AppLocalizations.of(context)!.videoType,
          hint: AppLocalizations.of(context)!.selectVideoType,
          value: _videoType,
          items: [
            CustomDropdownItem(
              label: AppLocalizations.of(context)!.youtube,
              value: "youtube",
            ),
            CustomDropdownItem(
              label: AppLocalizations.of(context)!.selfHosted,
              value: "self_hosted",
            ),
          ],
          onChanged: (val) {
            setState(() => _videoType = val);
            _updateBloc();
          },
        ),
        const SizedBox(height: 10),

        // if (_videoType == "youtube")
        //   CustomTextField(
        //     label: AppLocalizations.of(context)!.videoLink,
        //     hint: AppLocalizations.of(context)!.enterYoutubeUrl,
        //     controller: _videoLinkController,
        //     onChanged: (v) {
        //       final bloc = context.read<AddProductBloc>();
        //       bloc.add(
        //         UpdateProductData(
        //           bloc.state.productData.copyWith(videoLink: v),
        //         ),
        //       );
        //     },
        //   )
        // else if (_videoType == "self_hosted" &&
        //     productData.productVideo != null &&
        //     productData.productVideo!.startsWith('https')) ...[
        //   Padding(
        //     padding: const EdgeInsets.symmetric(vertical: 12),
        //     child: Text(
        //       "Current video: ${productData.productVideo!.split('/').last}",
        //       style: TextStyle(color: Theme.of(context).colorScheme.primary),
        //     ),
        //   ),
        //
        //   CustomUploadArea(
        //     hint: AppLocalizations.of(context)!.uploadVideo,
        //     fileName: productData.productVideo,
        //     onTap: _pickVideo,
        //     onRemove: () {
        //       final bloc = context.read<AddProductBloc>();
        //       bloc.add(
        //         UpdateProductData(
        //           bloc.state.productData.copyWith(productVideo: null),
        //         ),
        //       );
        //       setState(() {});
        //     },
        //   ),
        //   const SizedBox(height: 20),
        // ],
        if (_videoType == "youtube")
          CustomTextField(
            label: AppLocalizations.of(context)!.videoLink,
            hint: AppLocalizations.of(context)!.enterYoutubeUrl,
            controller: _videoLinkController,
            onChanged: (v) {
              final bloc = context.read<AddProductBloc>();
              bloc.add(
                UpdateProductData(
                  bloc.state.productData.copyWith(videoLink: v),
                ),
              );
            },
          )
        else if (_videoType == "self_hosted") ...[
          // ── Case 1: Existing remote video (edit mode) ──
          if (productData.videoLink != null &&
              productData.videoLink!.startsWith('https') &&
              (productData.productVideo == null ||
                  !File(productData.productVideo!).existsSync())) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Current video:",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      ExternalLink.showVideo(
                        productData.videoLink!,
                        context: context,
                      );
                    },
                    child: Text(
                      productData.videoLink!.split('/').last,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.lightBlue,
                      ),
                    ),
                  ),
                  Text(
                    "(remote file - will be kept unless replaced)",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            CustomUploadArea(
              hint: "Replace video (optional)",
              fileName: null, // don't show local filename here
              onTap: _pickVideo,
              onRemove: () {
                final bloc = context.read<AddProductBloc>();
                bloc.add(
                  UpdateProductData(
                    bloc.state.productData.copyWith(
                      clearProductVideo: true,
                      clearVideoLink: true,
                    ),
                  ),
                );
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
          ]
          // ── Case 2: New picked local video or no video yet ──
          else
            CustomUploadArea(
              hint: AppLocalizations.of(context)!.uploadVideo,
              fileName: productData.productVideo,
              onTap: _pickVideo,
              onRemove: () {
                final bloc = context.read<AddProductBloc>();
                bloc.add(
                  UpdateProductData(
                    bloc.state.productData.copyWith(clearProductVideo: true),
                  ),
                );
                setState(() {});
              },
            ),
        ],
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Custom Product Sections",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 15),
            Expanded(
              child: PrimaryButton(
                onPressed: () {
                  final currentSections = List<CustomProductSection>.from(
                    productData.customProductSections,
                  );
                  currentSections.add(CustomProductSection(title: ""));
                  final bloc = context.read<AddProductBloc>();
                  bloc.add(
                    UpdateProductData(
                      productData.copyWith(
                        customProductSections: currentSections,
                      ),
                    ),
                  );
                },
                icon: Icons.add,
                text: "Add Section",
                // style: ElevatedButton.styleFrom(
                //   backgroundColor: Theme.of(context).primaryColor,
                //   foregroundColor: Colors.white,
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(8),
                //   ),
                // ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...productData.customProductSections.asMap().entries.map((entry) {
          final index = entry.key;
          final section = entry.value;
          return CustomProductSectionWidget(
            index: index,
            section: section,
            onRemove: () {
              final currentSections = List<CustomProductSection>.from(
                productData.customProductSections,
              );
              currentSections.removeAt(index);
              final bloc = context.read<AddProductBloc>();
              bloc.add(
                UpdateProductData(
                  productData.copyWith(customProductSections: currentSections),
                ),
              );
            },
            onChanged: (updatedSection) {
              final currentSections = List<CustomProductSection>.from(
                productData.customProductSections,
              );
              currentSections[index] = updatedSection;
              final bloc = context.read<AddProductBloc>();
              bloc.add(
                UpdateProductData(
                  productData.copyWith(customProductSections: currentSections),
                ),
              );
            },
          );
        }),
        const SizedBox(height: 8),
        const Text(
          "Add custom sections with fields. Upload an image for each field if needed.",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
