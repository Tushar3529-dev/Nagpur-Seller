import 'package:flutter/material.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class MetadataStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const MetadataStep({super.key, required this.formKey});

  @override
  State<MetadataStep> createState() => _MetadataStepState();
}

class _MetadataStepState extends State<MetadataStep> {
  final TextEditingController _metadataController = TextEditingController();

  @override
  void dispose() {
    _metadataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: 'metadata',
            hint: "Enter Writing e.g. Hi",
            controller: _metadataController,
            maxLines: 5,
            minLines: 3,
          ),
        ],
      ),
    );
  }
}
