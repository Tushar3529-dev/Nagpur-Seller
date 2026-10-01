/// A delivery bag in the seller's inventory. A bag is assigned to at most one
/// seller order, and assigned bags can't be edited or deleted.
class Bag {
  final int id;
  final String barcode;
  final String status;
  final int? sellerOrderId;
  final String? orderNumber;
  final DateTime? assignedAt;
  final DateTime? createdAt;

  const Bag({
    required this.id,
    required this.barcode,
    required this.status,
    this.sellerOrderId,
    this.orderNumber,
    this.assignedAt,
    this.createdAt,
  });

  static const String available = 'available';
  static const String assigned = 'assigned';

  bool get isAssigned => status == assigned;

  factory Bag.fromJson(Map<String, dynamic> json) => Bag(
    id: (json['id'] as num).toInt(),
    barcode: json['barcode']?.toString() ?? '',
    status: json['status']?.toString() ?? available,
    sellerOrderId: (json['seller_order_id'] as num?)?.toInt(),
    orderNumber: json['order_number']?.toString(),
    assignedAt: DateTime.tryParse(json['assigned_at']?.toString() ?? ''),
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
  );
}

/// One page of `GET /bags`.
class BagsPage {
  final List<Bag> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const BagsPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory BagsPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    final items = data['items'] as List? ?? const [];
    return BagsPage(
      items: items.whereType<Map<String, dynamic>>().map(Bag.fromJson).toList(),
      currentPage: (data['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (data['last_page'] as num?)?.toInt() ?? 1,
      total: (data['total'] as num?)?.toInt() ?? items.length,
    );
  }
}

/// Outcome of `POST /bags/bulk`. Barcodes already in use anywhere are skipped
/// and reported back instead of failing the request.
class BulkAddBagsResult {
  final int createdCount;
  final List<String> createdBarcodes;
  final List<String> duplicateBarcodes;

  const BulkAddBagsResult({
    required this.createdCount,
    required this.createdBarcodes,
    required this.duplicateBarcodes,
  });

  factory BulkAddBagsResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    List<String> codes(Object? value) =>
        (value as List? ?? const []).map((e) => e.toString()).toList();
    final created = codes(data['created_barcodes']);
    return BulkAddBagsResult(
      createdCount: (data['created_count'] as num?)?.toInt() ?? created.length,
      createdBarcodes: created,
      duplicateBarcodes: codes(data['duplicate_barcodes']),
    );
  }
}
