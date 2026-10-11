/// Package-size parsing and unit-price ("₹20 / 100 g") calculations for the
/// product form, following the seller product setup contract:
///
///   total package quantity = quantity per inner unit * unit count (or 1)
///   comparable quantity    = total package quantity in the basis unit
///   unit price             = effective price / comparable quantity * basis amount
///
/// Known units convert within their family (kg → g, L → ml, dozen → 12
/// pieces). Any other unit only compares with itself after trimming and
/// case normalisation, so `bottle` never converts to `ml`.
library;

class PackageSize {
  final double quantity;
  final String unit;

  const PackageSize(this.quantity, this.unit);

  @override
  bool operator ==(Object other) =>
      other is PackageSize && other.quantity == quantity && other.unit == unit;

  @override
  int get hashCode => Object.hash(quantity, unit);

  @override
  String toString() => '${UnitPriceCalculator.formatNumber(quantity)} $unit';
}

class UnitPriceCalculator {
  UnitPriceCalculator._();

  static const int maxUnitLength = 30;

  /// Attribute names containing one of these words carry the package size
  /// for variant products.
  static const List<String> packageAttributeKeywords = [
    'size',
    'weight',
    'volume',
    'quantity',
    'pack',
  ];

  static const Map<String, String> _aliases = {
    'g': 'g',
    'gm': 'g',
    'gms': 'g',
    'gram': 'g',
    'grams': 'g',
    'kg': 'kg',
    'kgs': 'kg',
    'kilogram': 'kg',
    'kilograms': 'kg',
    'ml': 'ml',
    'milliliter': 'ml',
    'milliliters': 'ml',
    'millilitre': 'ml',
    'millilitres': 'ml',
    'l': 'L',
    'liter': 'L',
    'liters': 'L',
    'litre': 'L',
    'litres': 'L',
    'pc': 'piece',
    'pcs': 'piece',
    'piece': 'piece',
    'pieces': 'piece',
    'dozen': 'dozen',
    'dozens': 'dozen',
  };

  /// Canonical unit → (base unit, multiplier into base).
  static const Map<String, (String, double)> _conversions = {
    'g': ('g', 1),
    'kg': ('g', 1000),
    'ml': ('ml', 1),
    'L': ('ml', 1000),
    'piece': ('piece', 1),
    'dozen': ('piece', 12),
  };

  /// Maps common aliases to a canonical unit (`gm` → `g`, `litre` → `L`,
  /// `pcs` → `piece`). Unknown units are trimmed and lower-cased.
  static String normalizeUnit(String unit) {
    final key = unit.trim().toLowerCase();
    return _aliases[key] ?? key;
  }

  static (String, double) _toBase(String unit) {
    final canonical = normalizeUnit(unit);
    return _conversions[canonical] ?? (canonical, 1);
  }

  /// Whether quantities in [a] and [b] can be compared.
  static bool areComparable(String a, String b) {
    if (a.trim().isEmpty || b.trim().isEmpty) return false;
    return _toBase(a).$1 == _toBase(b).$1;
  }

  /// Default comparison basis for a package unit: 100 g for weight, 100 ml
  /// for volume, 1 piece for countables and `1 <unit>` for anything else.
  static PackageSize defaultBasisFor(String packageUnit) {
    final trimmed = packageUnit.trim();
    switch (_toBase(trimmed).$1) {
      case 'g':
        return const PackageSize(100, 'g');
      case 'ml':
        return const PackageSize(100, 'ml');
      case 'piece':
        return const PackageSize(1, 'piece');
      default:
        return PackageSize(1, trimmed);
    }
  }

  static bool isPackageAttribute(String attributeName) {
    final name = attributeName.toLowerCase();
    return packageAttributeKeywords.any(name.contains);
  }

  static final RegExp _packageValuePattern = RegExp(
    r'^\s*(\d+(?:[.,]\d+)?)\s*([^\d\s.,].*?)\s*$',
  );

  /// Parses attribute values such as `200 g`, `1L`, `5 pcs` or `1 dozen`.
  /// Returns null when the value does not start with a number and a unit.
  static PackageSize? parsePackageSize(String? value) {
    if (value == null) return null;
    final match = _packageValuePattern.firstMatch(value);
    if (match == null) return null;
    final quantity = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    final unit = match.group(2)!;
    if (quantity == null || quantity <= 0 || unit.length > maxUnitLength) {
      return null;
    }
    return PackageSize(quantity, unit);
  }

  /// Total package contents expressed in [basisUnit], or null when the
  /// package is incomplete or not comparable with the basis.
  static double? comparableQuantity({
    required double? netQuantity,
    required String? netQuantityUnit,
    int? unitCount,
    required String basisUnit,
  }) {
    if (netQuantity == null || netQuantity <= 0) return null;
    if (netQuantityUnit == null) return null;
    if (!areComparable(netQuantityUnit, basisUnit)) return null;
    final count = (unitCount == null || unitCount <= 0) ? 1 : unitCount;
    final packInBase = netQuantity * count * _toBase(netQuantityUnit).$2;
    return packInBase / _toBase(basisUnit).$2;
  }

  /// Special price when it is set, otherwise the regular price.
  static double? effectivePrice({double? price, double? specialPrice}) {
    if (specialPrice != null && specialPrice > 0) return specialPrice;
    return price;
  }

  /// Price per [basisQuantity] [basisUnit], or null when it can't be derived.
  static double? unitPrice({
    required double? price,
    double? specialPrice,
    required double? netQuantity,
    required String? netQuantityUnit,
    int? unitCount,
    required double? basisQuantity,
    required String? basisUnit,
  }) {
    final effective = effectivePrice(price: price, specialPrice: specialPrice);
    if (effective == null || basisQuantity == null || basisQuantity <= 0) {
      return null;
    }
    if (basisUnit == null) return null;
    final comparable = comparableQuantity(
      netQuantity: netQuantity,
      netQuantityUnit: netQuantityUnit,
      unitCount: unitCount,
      basisUnit: basisUnit,
    );
    if (comparable == null || comparable <= 0) return null;
    return effective / comparable * basisQuantity;
  }

  /// Inverse of [unitPrice]: the pack price that yields [unitPrice].
  static double? packPriceFromUnitPrice({
    required double unitPrice,
    required double? netQuantity,
    required String? netQuantityUnit,
    int? unitCount,
    required double? basisQuantity,
    required String? basisUnit,
  }) {
    if (basisQuantity == null || basisQuantity <= 0 || basisUnit == null) {
      return null;
    }
    final comparable = comparableQuantity(
      netQuantity: netQuantity,
      netQuantityUnit: netQuantityUnit,
      unitCount: unitCount,
      basisUnit: basisUnit,
    );
    if (comparable == null || comparable <= 0) return null;
    return unitPrice / basisQuantity * comparable;
  }

  /// `200.0` → `200`, `0.5` → `0.5`, `13.3333` → `13.33`.
  static String formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
