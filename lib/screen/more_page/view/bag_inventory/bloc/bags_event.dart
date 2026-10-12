part of 'bags_bloc.dart';

abstract class BagsEvent {}

/// Reloads from page 1 with the given status filter and barcode search.
class LoadBags extends BagsEvent {
  final String? status;
  final String? search;
  LoadBags({this.status, this.search});
}

class LoadMoreBags extends BagsEvent {}

/// Reloads with the current filter while keeping the list on screen.
class RefreshBags extends BagsEvent {}
