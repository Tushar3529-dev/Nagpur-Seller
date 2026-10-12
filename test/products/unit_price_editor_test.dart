import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/widgets/unit_price_editor.dart';
import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';
import 'package:hyper_local_seller/utils/unit_price_calculator.dart';

import '../incoming_orders/helpers.dart';

class _Row {
  String? price;
  String? specialPrice;
  String? basisQuantity;
  String? basisUnit;
  _Row({this.price, this.specialPrice, this.basisQuantity, this.basisUnit});
}

Widget _host(_Row row, {PackageSize? package, int? unitCount}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) => UnitPriceEditor(
          price: row.price,
          specialPrice: row.specialPrice,
          basisQuantity: row.basisQuantity,
          basisUnit: row.basisUnit,
          packageSize: package,
          unitCount: unitCount,
          onBasisChanged: (q, u) => setState(() {
            row.basisQuantity = q;
            row.basisUnit = u;
          }),
          onPackPriceChanged: ({price, specialPrice}) => setState(() {
            if (price != null) row.price = price;
            if (specialPrice != null) row.specialPrice = specialPrice;
          }),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() => initTestHive());

  testWidgets('shows unit price and stores the default basis', (tester) async {
    final row = _Row(price: '200');
    await tester.pumpWidget(
      _host(row, package: const PackageSize(500, 'g'), unitCount: 2),
    );
    await tester.pump();

    expect(row.basisQuantity, '100');
    expect(row.basisUnit, 'g');
    expect(find.widgetWithText(TextFormField, '20'), findsOneWidget);
  });

  testWidgets('editing unit price updates special price when set', (
    tester,
  ) async {
    final row = _Row(
      price: '200',
      specialPrice: '150',
      basisQuantity: '100',
      basisUnit: 'g',
    );
    await tester.pumpWidget(_host(row, package: const PackageSize(1, 'kg')));

    await tester.enterText(find.widgetWithText(TextFormField, '15'), '12.5');
    await tester.pump();

    expect(row.specialPrice, '125');
    expect(row.price, '200');
    // The field keeps what the seller typed while focused.
    expect(find.widgetWithText(TextFormField, '12.5'), findsOneWidget);
  });

  testWidgets('editing unit price updates regular price otherwise', (
    tester,
  ) async {
    final row = _Row(price: '240', basisQuantity: '1', basisUnit: 'piece');
    await tester.pumpWidget(
      _host(row, package: const PackageSize(1, 'dozen')),
    );

    await tester.enterText(find.widgetWithText(TextFormField, '20'), '25');
    await tester.pump();

    expect(row.price, '300');
    expect(row.specialPrice, isNull);
  });

  testWidgets('offers the default basis when units are not comparable', (
    tester,
  ) async {
    final row = _Row(price: '80', basisQuantity: '100', basisUnit: 'ml');
    await tester.pumpWidget(
      _host(row, package: const PackageSize(1, 'bottle')),
    );

    expect(find.text('Use 1 bottle'), findsOneWidget);
    await tester.tap(find.text('Use 1 bottle'));
    await tester.pump();

    expect(row.basisQuantity, '1');
    expect(row.basisUnit, 'bottle');
    expect(find.widgetWithText(TextFormField, '80'), findsOneWidget);
  });

  test('parses package and basis fields from the edit response', () {
    final variant = Variant.fromJson({
      'id': 903,
      'weight': 1.1,
      'net_quantity': 500,
      'net_quantity_unit': 'g',
      'unit_count': 2,
      'unit_count_type': 'packet',
      'stores': [
        {
          'id': 8801,
          'store_id': 12,
          'price': 200,
          'special_price': null,
          'wholesale_price': null,
          'unit_price_basis_quantity': 100,
          'unit_price_basis_unit': 'g',
          'cost': 100,
          'stock': 25,
        },
      ],
    });
    expect(variant.netQuantity, 500);
    expect(variant.netQuantityUnit, 'g');
    expect(variant.unitCount, 2);
    expect(variant.unitCountType, 'packet');
    final store = variant.stores!.single;
    expect(store.specialPrice, isNull);
    expect(store.wholesalePrice, isNull);
    expect(store.unitPriceBasisQuantity, 100);
    expect(store.unitPriceBasisUnit, 'g');

    final bare = Variant.fromJson({'id': 1});
    expect(bare.netQuantity, isNull);
    expect(bare.unitCount, isNull);
  });
}
