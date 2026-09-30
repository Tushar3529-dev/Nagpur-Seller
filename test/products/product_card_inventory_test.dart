import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/widgets/product_inventory_loader.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';

class _Repo extends ProductsRepo {
  final fetched = <int>[];
  final saved = <(int, int, int)>[];
  bool failLoad = false;
  @override
  Future<dynamic> getProductById(int id) async {
    fetched.add(id);
    if (failLoad) throw Exception('Connection failed');
    return {
      'success': true,
      'data': {
        'id': id,
        'title': 'Product',
        'slug': 'product',
        'variants': [
          for (var index = 0; index < 2; index++)
            {
              'id': index + 1,
              'title': 'Variation ${index + 1}',
              'stores': [
                {
                  'store_id': 7,
                  'store_name': 'Store',
                  'id': 789 + index,
                  'stock': index == 0 ? 6 : 0,
                },
              ],
            },
        ],
      },
    };
  }

  @override
  Future<int> updateInventory({
    required int productId,
    required int storeProductVariantId,
    required int stock,
  }) async {
    saved.add((productId, storeProductVariantId, stock));
    return stock;
  }
}

void main() {
  for (final size in [const Size(320, 700), const Size(412, 915)]) {
    testWidgets('card Edit qty does not open details and fits $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      var editCount = 0;
      var detailsCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: CustomCard(
                type: CardType.product,
                screenType: ScreenType.mobile,
                data: {'id': 20, 'name': 'Product', 'stock': 6, 'price': 25},
                onEditQty: () => editCount++,
                onTap: () => detailsCount++,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Low stock'), findsOneWidget);
      await tester.tap(find.text('Edit qty'));
      expect(editCount, 1);
      expect(detailsCount, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'listing editor loads current values and saves the selected variation',
    (tester) async {
      final repo = _Repo();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) =>
                      ProductInventoryLoader(productId: 20, repo: repo),
                ),
                child: const Text('Edit qty'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Edit qty'));
      await tester.pumpAndSettle();
      expect(repo.fetched, [20]);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).last)
            .controller!
            .text,
        '6',
      );
      await tester.tap(find.text('Variation 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Variation 2').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).last)
            .controller!
            .text,
        '0',
      );
      await tester.enterText(find.byType(TextFormField).last, '25');
      await tester.tap(find.text('Save stock'));
      await tester.pumpAndSettle();
      expect(repo.saved, [(20, 790, 25)]);
      expect(find.byType(ProductInventoryLoader), findsNothing);
    },
  );

  testWidgets('listing stock load errors support retry without navigation', (
    tester,
  ) async {
    final repo = _Repo()..failLoad = true;
    await tester.pumpWidget(
      MaterialApp(home: ProductInventoryLoader(productId: 20, repo: repo)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Connection failed'), findsOneWidget);
    repo.failLoad = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(repo.fetched, [20, 20]);
    expect(find.text('Save stock'), findsOneWidget);
    expect(repo.saved, isEmpty);
  });
}
