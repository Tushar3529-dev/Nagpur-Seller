import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/stock_quantity_field.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/widgets/product_inventory_dialog.dart';

class _Repo extends ProductsRepo {
  final calls = <(int, int, int)>[];
  bool fail = false;
  @override
  Future<int> updateInventory({
    required int productId,
    required int storeProductVariantId,
    required int stock,
  }) async {
    calls.add((productId, storeProductVariantId, stock));
    if (fail) throw Exception('Network unavailable');
    return stock;
  }
}

void main() {
  test('creation stock is blank and zero survives both pricing payloads', () {
    expect(StorePricing(storeId: 1, storeName: 'Store').toJson()['stock'], '');
    expect(
      StorePricing(
        storeId: 1,
        storeName: 'Store',
        stock: '0',
      ).toJson()['stock'],
      '0',
    );
    expect(
      VariantStorePricing(
        storeId: 1,
        variantId: 'v1',
        stock: '0',
      ).toJson()['stock'],
      '0',
    );
    for (final value in ['0', '5', '25', '0005']) {
      expect(isValidStockQuantity(value), isTrue);
    }
    for (final value in [null, '', '-1', '1.5', 'text']) {
      expect(isValidStockQuantity(value), isFalse);
    }
  });

  testWidgets('new stock field is empty; editable integer stock accepts zero', (
    tester,
  ) async {
    String? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockQuantityField(onChanged: (value) => changed = value),
        ),
      ),
    );
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '',
    );
    await tester.enterText(find.byType(TextFormField), '25');
    expect(changed, '25');
    await tester.enterText(find.byType(TextFormField), '0');
    expect(changed, '0');
    for (final invalid in ['-5', '1.5', 'abc']) {
      await tester.enterText(find.byType(TextFormField), invalid);
      expect(changed, '0');
    }
  });

  testWidgets('stock field hydrates external edit values including zero', (
    tester,
  ) async {
    Future<void> pump(String? value) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockQuantityField(value: value, onChanged: (_) {}),
        ),
      ),
    );
    await pump('6');
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '6',
    );
    await pump('0');
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '0',
    );
    await pump(null);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '',
    );
  });

  late _Repo repo;
  late VariantStore store;
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => ProductInventoryDialog(
                  productId: 123,
                  variant: Variant(title: 'Product', stores: [store]),
                  repo: repo,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    repo = _Repo();
    store = VariantStore(
      storeId: 7,
      storeName: 'Store',
      storeProductVariantId: 789,
      stock: 6,
    );
  });

  testWidgets(
    'refill saves an absolute total using inventory ID; zero is allowed',
    (tester) async {
      await open(tester);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '6',
      );
      await tester.enterText(find.byType(TextFormField), '0');
      await tester.tap(find.text('Save stock'));
      await tester.pumpAndSettle();
      expect(repo.calls, [(123, 789, 0)]);
      expect(store.stock, 0);
      expect(find.byType(ProductInventoryDialog), findsNothing);
    },
  );

  testWidgets('failed save preserves quantity and supports retry', (
    tester,
  ) async {
    repo.fail = true;
    await open(tester);
    await tester.enterText(find.byType(TextFormField), '25');
    await tester.tap(find.text('Save stock'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Network unavailable'), findsOneWidget);
    expect(store.stock, 6);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '25',
    );
    repo.fail = false;
    await tester.tap(find.text('Save stock'));
    await tester.pumpAndSettle();
    expect(repo.calls, [(123, 789, 25), (123, 789, 25)]);
    expect(store.stock, 25);
  });

  testWidgets('missing inventory ID never substitutes the store ID', (
    tester,
  ) async {
    store.storeProductVariantId = null;
    await open(tester);
    await tester.tap(find.text('Save stock'));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);
    expect(
      find.textContaining('Inventory details are missing'),
      findsOneWidget,
    );
  });

  testWidgets('cancel and blank quantity do not change inventory', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField), '');
    await tester.tap(find.text('Save stock'));
    await tester.pumpAndSettle();
    expect(find.text('Enter stock quantity'), findsWidgets);
    expect(repo.calls, isEmpty);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.stock, 6);
  });
}
