import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/widgets/product_scan_dialog.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

class _FakeRepo extends ProductsRepo {
  final Map<String, int> idsByBarcode;
  Object? barcodeError;
  final List<String> barcodeCalls = [];
  final List<int> idCalls = [];

  _FakeRepo(this.idsByBarcode);

  @override
  Future<dynamic> getProductByBarcode(String barcode) async {
    barcodeCalls.add(barcode);
    if (barcodeError != null) throw barcodeError!;
    final id = idsByBarcode[barcode];
    if (id == null) throw ApiException('Product not found', statusCode: 404);
    return {
      'success': true,
      'data': {
        'product': {'id': id},
        'matched_variant': {'barcode': barcode},
      },
    };
  }

  @override
  Future<dynamic> getProductById(int id) async {
    idCalls.add(id);
    return {
      'success': true,
      'data': {'id': id, 'title': 'Classic T-Shirt', 'slug': 'classic-t-shirt'},
    };
  }
}

void main() {
  late _FakeRepo repo;
  late void Function(String code, Uint8List? image) scan;
  Product? popped;
  String? barcodePopped;

  Future<void> open(WidgetTester tester, {bool returnBarcode = false}) async {
    popped = null;
    barcodePopped = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final result = await showDialog<Object>(
                  context: context,
                  builder: (_) => Dialog(
                    child: ProductScanDialog(
                      repo: repo,
                      returnBarcode: returnBarcode,
                      cameraBuilder: (onCode) {
                        scan = onCode;
                        return const SizedBox(
                          height: 100,
                          child: Text('camera'),
                        );
                      },
                    ),
                  ),
                );
                if (result is Product) {
                  popped = result;
                }
                if (result is String) {
                  barcodePopped = result;
                }
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  setUp(() => repo = _FakeRepo({'8901234500021': 123}));

  testWidgets('form scan confirms a new barcode without product lookup', (
    tester,
  ) async {
    await open(tester, returnBarcode: true);
    expect(find.text('Scan barcode'), findsOneWidget);
    scan(' 8901234500099 ', null);
    await tester.pumpAndSettle();
    expect(barcodePopped, isNull);
    expect(find.text('8901234500099'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(barcodePopped, '8901234500099');
    expect(repo.barcodeCalls, isEmpty);
    expect(repo.idCalls, isEmpty);
  });

  testWidgets('form scan retakes and cancellation returns no replacement', (
    tester,
  ) async {
    await open(tester, returnBarcode: true);
    scan('8901234500099', null);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retake'));
    await tester.pumpAndSettle();
    expect(find.text('camera'), findsOneWidget);
    expect(barcodePopped, isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(barcodePopped, isNull);
    expect(repo.barcodeCalls, isEmpty);
  });

  testWidgets(
    'form scanner manual entry validates and returns code without lookup',
    (tester) async {
      await open(tester, returnBarcode: true);
      await tester.tap(find.byTooltip('Enter code manually'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use barcode'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a barcode'), findsOneWidget);
      await tester.enterText(find.byType(TextField), ' 8901234500099 ');
      await tester.tap(find.text('Use barcode'));
      await tester.pumpAndSettle();
      expect(barcodePopped, '8901234500099');
      expect(repo.barcodeCalls, isEmpty);
    },
  );

  testWidgets('camera scan asks to confirm, then pops with the product', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Scan product'), findsOneWidget);

    scan('8901234500021', null);
    await tester.pumpAndSettle();
    expect(find.text('Is this code correct?'), findsOneWidget);
    expect(find.text('8901234500021'), findsOneWidget);
    expect(repo.barcodeCalls, isEmpty);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(repo.barcodeCalls, ['8901234500021']);
    expect(repo.idCalls, [123]);
    expect(popped?.id, 123);
    expect(find.byType(ProductScanDialog), findsNothing);
  });

  testWidgets('retake goes back to the camera', (tester) async {
    await open(tester);
    scan('111', null);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retake'));
    await tester.pumpAndSettle();
    expect(find.text('camera'), findsOneWidget);
    expect(repo.barcodeCalls, isEmpty);
  });

  testWidgets('unknown barcode shows not found and stays open', (tester) async {
    await open(tester);
    scan('000', null);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('No product found with barcode 000.'), findsOneWidget);
    expect(find.byType(ProductScanDialog), findsOneWidget);
    expect(popped, isNull);
  });

  testWidgets('typed code searches without the confirm step', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Enter code manually'));
    await tester.pumpAndSettle();
    expect(find.text('Enter barcode'), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pump();
    expect(find.text('Enter a barcode'), findsOneWidget);

    await tester.enterText(find.byType(TextField), ' 8901234500021 ');
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(repo.barcodeCalls, ['8901234500021']);
    expect(popped?.id, 123);
  });

  testWidgets('network error is shown with the message', (tester) async {
    repo.barcodeError = ApiException('No Internet Connection');
    await open(tester);
    scan('8901234500021', null);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(
      find.text("Couldn't look up the product. No Internet Connection"),
      findsOneWidget,
    );
  });
}
