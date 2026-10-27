part of 'delivery_boy_bloc.dart';

enum DeliveryBoyStatus { initial, loading, success, failure }

class DeliveryBoyState extends Equatable {
  final DeliveryBoyStatus status;
  final bool isRefreshing;
  final List<DeliveryBoy> assigned;
  final int assignedPage;
  final bool assignedHasMore;
  final int assignedTotal;
  final bool isLoadingMoreAssigned;
  final List<DeliveryBoy> available;
  final int availablePage;
  final bool availableHasMore;
  final int availableTotal;
  final bool isLoadingMoreAvailable;
  final String search;
  final Set<int> busyRiderIds;
  final String? errorMessage;
  final String? actionMessage;
  final int? errorStatusCode;
  final Map<String, String> fieldErrors;

  const DeliveryBoyState({
    this.status = DeliveryBoyStatus.initial,
    this.isRefreshing = false,
    this.assigned = const [],
    this.assignedPage = 1,
    this.assignedHasMore = false,
    this.assignedTotal = 0,
    this.isLoadingMoreAssigned = false,
    this.available = const [],
    this.availablePage = 1,
    this.availableHasMore = false,
    this.availableTotal = 0,
    this.isLoadingMoreAvailable = false,
    this.search = '',
    this.busyRiderIds = const {},
    this.errorMessage,
    this.actionMessage,
    this.errorStatusCode,
    this.fieldErrors = const {},
  });

  DeliveryBoyState copyWith({
    DeliveryBoyStatus? status,
    bool? isRefreshing,
    List<DeliveryBoy>? assigned,
    int? assignedPage,
    bool? assignedHasMore,
    int? assignedTotal,
    bool? isLoadingMoreAssigned,
    List<DeliveryBoy>? available,
    int? availablePage,
    bool? availableHasMore,
    int? availableTotal,
    bool? isLoadingMoreAvailable,
    String? search,
    Set<int>? busyRiderIds,
    String? errorMessage,
    String? actionMessage,
    int? errorStatusCode,
    Map<String, String>? fieldErrors,
    bool clearMessages = false,
  }) => DeliveryBoyState(
    status: status ?? this.status,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    assigned: assigned ?? this.assigned,
    assignedPage: assignedPage ?? this.assignedPage,
    assignedHasMore: assignedHasMore ?? this.assignedHasMore,
    assignedTotal: assignedTotal ?? this.assignedTotal,
    isLoadingMoreAssigned: isLoadingMoreAssigned ?? this.isLoadingMoreAssigned,
    available: available ?? this.available,
    availablePage: availablePage ?? this.availablePage,
    availableHasMore: availableHasMore ?? this.availableHasMore,
    availableTotal: availableTotal ?? this.availableTotal,
    isLoadingMoreAvailable:
        isLoadingMoreAvailable ?? this.isLoadingMoreAvailable,
    search: search ?? this.search,
    busyRiderIds: busyRiderIds ?? this.busyRiderIds,
    errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
    actionMessage: clearMessages ? null : actionMessage ?? this.actionMessage,
    errorStatusCode: clearMessages
        ? null
        : errorStatusCode ?? this.errorStatusCode,
    fieldErrors: fieldErrors ?? this.fieldErrors,
  );
  @override
  List<Object?> get props => [
    status,
    isRefreshing,
    assigned,
    assignedPage,
    assignedHasMore,
    assignedTotal,
    isLoadingMoreAssigned,
    available,
    availablePage,
    availableHasMore,
    availableTotal,
    isLoadingMoreAvailable,
    search,
    busyRiderIds,
    errorMessage,
    actionMessage,
    errorStatusCode,
    fieldErrors,
  ];
}
