import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/utils/unit_price_calculator.dart';

double? _unitPrice({
  required double price,
  double? special,
  required double qty,
  required String unit,
  int? count,
  required double basisQty,
  required String basisUnit,
}) {
  return UnitPriceCalculator.unitPrice(
    price: price,
    specialPrice: special,
    netQuantity: qty,
    netQuantityUnit: unit,
    unitCount: count,
    basisQuantity: basisQty,
    basisUnit: basisUnit,
  );
}

void main() {
  group('backend contract examples', () {
    test('1 kg at 200 per 100 g is 20', () {
      expect(
        _unitPrice(
          price: 200,
          qty: 1,
          unit: 'kg',
          basisQty: 100,
          basisUnit: 'g',
        ),
        closeTo(20, 1e-9),
      );
    });

    test('special price wins over regular price', () {
      expect(
        _unitPrice(
          price: 200,
          special: 150,
          qty: 1,
          unit: 'kg',
          basisQty: 100,
          basisUnit: 'g',
        ),
        closeTo(15, 1e-9),
      );
    });

    test('5 pcs at 100 per pc is 20', () {
      expect(
        _unitPrice(
          price: 100,
          qty: 5,
          unit: 'pcs',
          basisQty: 1,
          basisUnit: 'pc',
        ),
        closeTo(20, 1e-9),
      );
    });

    test('1 dozen at 240 per piece is 20', () {
      expect(
        _unitPrice(
          price: 240,
          qty: 1,
          unit: 'dozen',
          basisQty: 1,
          basisUnit: 'piece',
        ),
        closeTo(20, 1e-9),
      );
    });

    test('500 g x 2 packet at 200 per 100 g is 20', () {
      expect(
        _unitPrice(
          price: 200,
          qty: 500,
          unit: 'g',
          count: 2,
          basisQty: 100,
          basisUnit: 'g',
        ),
        closeTo(20, 1e-9),
      );
    });

    test('1 bottle at 80 per bottle is 80, but not comparable to ml', () {
      expect(
        _unitPrice(
          price: 80,
          qty: 1,
          unit: 'bottle',
          basisQty: 1,
          basisUnit: 'Bottle ',
        ),
        closeTo(80, 1e-9),
      );
      expect(
        _unitPrice(
          price: 80,
          qty: 1,
          unit: 'bottle',
          basisQty: 100,
          basisUnit: 'ml',
        ),
        isNull,
      );
    });
  });

  test('normalizes aliases', () {
    expect(UnitPriceCalculator.normalizeUnit(' GM '), 'g');
    expect(UnitPriceCalculator.normalizeUnit('Litre'), 'L');
    expect(UnitPriceCalculator.normalizeUnit('millilitre'), 'ml');
    expect(UnitPriceCalculator.normalizeUnit('Pcs'), 'piece');
    expect(UnitPriceCalculator.normalizeUnit('Sachet'), 'sachet');
  });

  test('default basis per unit family', () {
    expect(
      UnitPriceCalculator.defaultBasisFor('kg'),
      const PackageSize(100, 'g'),
    );
    expect(
      UnitPriceCalculator.defaultBasisFor('L'),
      const PackageSize(100, 'ml'),
    );
    expect(
      UnitPriceCalculator.defaultBasisFor('dozen'),
      const PackageSize(1, 'piece'),
    );
    expect(
      UnitPriceCalculator.defaultBasisFor('bottle'),
      const PackageSize(1, 'bottle'),
    );
  });

  test('parses attribute package values', () {
    expect(
      UnitPriceCalculator.parsePackageSize('200 g'),
      const PackageSize(200, 'g'),
    );
    expect(
      UnitPriceCalculator.parsePackageSize('1L'),
      const PackageSize(1, 'L'),
    );
    expect(
      UnitPriceCalculator.parsePackageSize('1.5 kg'),
      const PackageSize(1.5, 'kg'),
    );
    expect(UnitPriceCalculator.parsePackageSize('Large'), isNull);
    expect(UnitPriceCalculator.parsePackageSize('500'), isNull);
  });

  test('identifies package attributes by name', () {
    expect(UnitPriceCalculator.isPackageAttribute('Pack Size'), isTrue);
    expect(UnitPriceCalculator.isPackageAttribute('Net Weight'), isTrue);
    expect(UnitPriceCalculator.isPackageAttribute('Color'), isFalse);
  });

  test('pack price from unit price inverts unit price', () {
    expect(
      UnitPriceCalculator.packPriceFromUnitPrice(
        unitPrice: 20,
        netQuantity: 500,
        netQuantityUnit: 'g',
        unitCount: 2,
        basisQuantity: 100,
        basisUnit: 'g',
      ),
      closeTo(200, 1e-9),
    );
  });

  test('formats numbers without trailing zeros', () {
    expect(UnitPriceCalculator.formatNumber(200), '200');
    expect(UnitPriceCalculator.formatNumber(0.5), '0.5');
    expect(UnitPriceCalculator.formatNumber(13.3333), '13.33');
  });
}
