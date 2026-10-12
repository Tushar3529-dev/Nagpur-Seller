import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

bool isValidStockQuantity(String? value) {
  final text = value?.trim() ?? '';
  return RegExp(r'^\d+$').hasMatch(text) && int.tryParse(text) != null;
}

/// Stock is an absolute available quantity, including zero, not a refill delta.
class StockQuantityField extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;

  const StockQuantityField({super.key, this.value, required this.onChanged});

  @override
  State<StockQuantityField> createState() => _StockQuantityFieldState();
}

class _StockQuantityFieldState extends State<StockQuantityField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value ?? '',
  );

  @override
  void didUpdateWidget(StockQuantityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.value ?? '';
    if (oldWidget.value != widget.value && text != _controller.text) {
      // A surrounding Form must not be notified during its child build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            (widget.value ?? '') != text ||
            _controller.text == text) {
          return;
        }
        _controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CustomTextField(
        controller: _controller,
        hint: 'Enter stock quantity',
        keyboardType: TextInputType.number,
        inputFormatters: [
          TextInputFormatter.withFunction(
            (oldValue, newValue) =>
                newValue.text.isEmpty ||
                    RegExp(r'^\d+$').hasMatch(newValue.text)
                ? newValue
                : oldValue,
          ),
        ],
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Enter stock quantity'
            : isValidStockQuantity(value)
            ? null
            : 'Enter a whole number of 0 or more',
        onChanged: widget.onChanged,
      ),
      const SizedBox(height: 6),
      Text(
        'Total units available. Use 0 for out of stock.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}
