class PaginationGuard {
  /// Defensive logic to decide if pagination should stop.
  /// If ANY condition says stop, we stop.
  static bool shouldStopPagination({
    required List<dynamic> itemsReceived,
    required List<dynamic> currentItems,
    int? total,
    bool? hasMoreBackend,
    required int perPage,
  }) {
    // 1. Backend explicitly says no more data
    if (hasMoreBackend == false) return true;

    // 2. We already reached or exceeded the total count (if provided)
    if (total != null && (currentItems.length + itemsReceived.length) >= total) {
      return true;
    }

    // 3. Received empty list - definitely no more
    if (itemsReceived.isEmpty) return true;

    // 4. Received fewer items than requested - usually means end of list
    if (itemsReceived.length < perPage) return true;

    return false;
  }
}
