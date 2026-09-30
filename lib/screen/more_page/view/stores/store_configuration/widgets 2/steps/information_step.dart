import 'package:flutter/material.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class InformationStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const InformationStep({super.key, required this.formKey});

  @override
  State<InformationStep> createState() => _InformationStepState();
}

class _InformationStepState extends State<InformationStep> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _aboutUsController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _aboutUsController.dispose();
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
            label: 'description',
            isRequired: true,
            hint: "Enter Visiting e.g. Hi",
            controller: _descriptionController,
            maxLines: 5,
            minLines: 3,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'aboutUs',
            hint: "Select Brand",
            controller: _aboutUsController,
            maxLines: 5,
            minLines: 3,
          ),
        ],
      ),
    );
  }
}
