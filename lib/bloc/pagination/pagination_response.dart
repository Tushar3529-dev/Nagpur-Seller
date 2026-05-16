class PaginationResponse<T> {
  final List<T> items;
  final int? total;
  final bool? hasMore;
  final int? currentPage;

  const PaginationResponse({
    required this.items,
    this.total,
    this.hasMore,
    this.currentPage,
  });
}
