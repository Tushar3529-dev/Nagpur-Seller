import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/repo/add_product_repo.dart';

void main() {
  group('simple product payload', () {
    ProductData simple() => ProductData()
      ..type = 'simple'
      ..barcode = '8901234567890'
      ..isInclusiveTax = true
      ..netQuantity = '500'
      ..netQuantityUnit = 'g'
      ..unitCount = '2'
      ..unitCountType = 'packet'
      ..customFields = [
        {'key': 'origin', 'value': 'Nagpur'},
      ]
      ..variants = [
        VariantData(
          title: 'Simple',
          attributeValueIds: [],
          weight: '0.55',
          height: '8',
          length: '12',
          breadth: '6',
        ),
      ]
      ..storePricing = [
        StorePricing(
          storeId: 12,
          storeName: 'Nagpur Central',
          price: '200',
          specialPrice: '150',
          unitPriceBasisQuantity: '100',
          unitPriceBasisUnit: 'g',
          cost: '100',
          stock: '25',
          sku: 'MASAALA-500G-2PK',
        ),
      ];

    test('sends package fields at the top level', () async {
      final fields = await AddProductRepo.buildFields(simple());
      expect(fields['net_quantity'], 500);
      expect(fields['net_quantity_unit'], 'g');
      expect(fields['unit_count'], 2);
      expect(fields['unit_count_type'], 'packet');
      expect(fields['weight'], '0.55');
      expect(fields['is_inclusive_tax'], '1');
      expect(fields['custom_fields[origin]'], 'Nagpur');
      expect(fields.containsKey('variants_json'), isFalse);
    });

    test('sends unit price basis and wholesale on store pricing', () async {
      final fields = await AddProductRepo.buildFields(simple());
      final pricing = jsonDecode(fields['pricing'] as String);
      final row = (pricing['store_pricing'] as List).single as Map;
      expect(row['unit_price_basis_quantity'], '100');
      expect(row['unit_price_basis_unit'], 'g');
      expect(row.containsKey('wholesale_price'), isTrue);
      expect(row['wholesale_price'], isNull);
      expect(row.containsKey('unit_price'), isFalse);
    });

    test('omits incomplete package pairs', () async {
      final data = simple()
        ..netQuantityUnit = ''
        ..unitCountType = '';
      final fields = await AddProductRepo.buildFields(data);
      expect(fields.containsKey('net_quantity'), isFalse);
      expect(fields.containsKey('unit_count'), isFalse);
    });

    test('omits basis when either half is blank', () {
      final row = StorePricing(
        storeId: 1,
        storeName: 's',
        unitPriceBasisQuantity: '100',
      ).toJson();
      expect(row.containsKey('unit_price_basis_quantity'), isFalse);
      expect(row.containsKey('unit_price_basis_unit'), isFalse);
    });
  });

  test('variant payload carries package data per variant', () async {
    final data = ProductData()
      ..type = 'variant'
      ..variants = [
        VariantData(
          id: 'variant-local-1',
          title: '2 x 500 g packets',
          attributeValueIds: [42],
          attributes: [
            {
              'attribute_id': 7,
              'value_id': 42,
              'attribute_name': 'Pack Size',
              'value_name': '500 g',
            },
          ],
          barcode: '8901234567890',
          weight: '1.1',
          height: '8',
          length: '12',
          breadth: '6',
          isDefault: true,
          netQuantity: '500',
          netQuantityUnit: 'g',
          unitCount: '2',
          unitCountType: 'packet',
        ),
        VariantData(
          id: 'variant-local-2',
          title: '1 kg',
          attributeValueIds: [43],
          attributes: [
            {'attribute_id': 7, 'value_id': 43},
          ],
          barcode: '8901234567891',
          weight: '1',
          height: '8',
          length: '12',
          breadth: '6',
        ),
      ]
      ..variantStorePricing = [
        VariantStorePricing(
          storeId: 12,
          variantId: 'variant-local-1',
          price: '200',
          unitPriceBasisQuantity: '100',
          unitPriceBasisUnit: 'g',
        ),
      ];

    final fields = await AddProductRepo.buildFields(data);
    expect(fields.containsKey('net_quantity'), isFalse);

    final variants = jsonDecode(fields['variants_json'] as String) as List;
    final first = variants[0] as Map;
    expect(first['net_quantity'], 500);
    expect(first['net_quantity_unit'], 'g');
    expect(first['unit_count'], 2);
    expect(first['unit_count_type'], 'packet');
    expect(first['is_default'], 'on');
    expect(first['attributes'], [
      {'attribute_id': 7, 'value_id': 42},
    ]);

    final second = variants[1] as Map;
    expect(second['is_default'], 'off');
    expect(second.containsKey('net_quantity'), isFalse);
    expect(second.containsKey('unit_count'), isFalse);

    final pricing = jsonDecode(fields['pricing'] as String);
    final row = (pricing['variant_pricing'] as List).single as Map;
    expect(row['variant_id'], 'variant-local-1');
    expect(row['unit_price_basis_unit'], 'g');
  });
}
