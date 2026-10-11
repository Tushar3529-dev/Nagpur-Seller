import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/widgets/custom/custom_drop_menu.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CustomCard(
          type: CardType.product,
          screenType: ScreenType.mobile,
          data: const {'id': 1, 'name': 'Product', 'price': 10},
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    ),
  );

  List<String> menuLabels(WidgetTester tester) => tester
      .widget<CustomDropMenu>(find.byType(CustomDropMenu))
      .items
      .map((item) => item.label)
      .toList();

  testWidgets('menu lists only the permitted actions', (tester) async {
    await pumpCard(tester, onEdit: () {}, onDelete: () {});
    expect(menuLabels(tester), ['Edit', 'Delete']);

    await pumpCard(tester, onEdit: () {});
    expect(menuLabels(tester), ['Edit']);

    await pumpCard(tester, onDelete: () {});
    expect(menuLabels(tester), ['Delete']);
  });

  testWidgets('no menu at all without edit or delete', (tester) async {
    await pumpCard(tester);
    expect(find.byType(CustomDropMenu), findsNothing);
  });
}
