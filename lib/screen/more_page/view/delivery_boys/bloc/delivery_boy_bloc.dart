import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/model/delivery_boy_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/repo/delivery_boy_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/service/json_parser.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';

part 'delivery_boy_event.dart';
part 'delivery_boy_state.dart';

class DeliveryBoyBloc extends Bloc<DeliveryBoyEvent, DeliveryBoyState> {
  final DeliveryBoyRepo _repo;
  int _fetchVersion = 0;
  int _sessionVersion = 0;

  DeliveryBoyBloc({required DeliveryBoyRepo repo})
    : _repo = repo,
      super(const DeliveryBoyState()) {
    on<FetchRiders>(_fetch);
    on<LoadMoreAssigned>((event, emit) => _loadMore(true, emit));
    on<LoadMoreAvailable>((event, emit) => _loadMore(false, emit));
    // The page debounces this event by 400 ms.
    on<SearchChanged>((event, emit) {
      _fetchVersion++;
      emit(state.copyWith(search: event.query.trim()));
      add(const FetchRiders());
    });
    on<ClaimRider>((event, emit) => _write(event.id, event, emit));
    on<CreateRider>(
      (event, emit) =>
          _write(event is UpdateRider ? event.id : -1, event, emit),
    );
    on<DeleteRider>((event, emit) => _write(event.id, event, emit));
    on<ApproveLogin>((event, emit) => _write(event.id, event, emit));
    on<RejectLogin>((event, emit) => _write(event.id, event, emit));
    on<ClearMessages>(
      (event, emit) => emit(state.copyWith(clearMessages: true)),
    );
    on<DeliveryBoyReset>((event, emit) {
      _sessionVersion++;
      _fetchVersion++;
      emit(const DeliveryBoyState());
    });
  }

  static bool get canView =>
      PermissionChecker.hasPermission(AppPermissions.deliveryBoyView);
  static bool get canManage =>
      PermissionChecker.hasPermission(AppPermissions.deliveryBoyManage);

  Future<void> _fetch(FetchRiders event, Emitter<DeliveryBoyState> emit) async {
    if (!canView) return;
    final version = ++_fetchVersion;
    emit(
      state.copyWith(
        status: event.silent ? state.status : DeliveryBoyStatus.loading,
        isRefreshing: event.silent,
        isLoadingMoreAssigned: false,
        isLoadingMoreAvailable: false,
      ),
    );
    try {
      final response = await _repo.getRiders(search: state.search);
      if (version != _fetchVersion) return;
      emit(
        state.copyWith(
          status: DeliveryBoyStatus.success,
          isRefreshing: false,
          assigned: response.assigned.data,
          assignedPage: response.assigned.currentPage,
          assignedHasMore: response.assigned.hasMore,
          assignedTotal: response.assigned.total,
          available: canManage ? response.available.data : [],
          availablePage: response.available.currentPage,
          availableHasMore: canManage && response.available.hasMore,
          availableTotal: canManage ? response.available.total : 0,
        ),
      );
    } catch (error) {
      if (version != _fetchVersion) return;
      emit(
        state.copyWith(
          status: event.silent && state.status == DeliveryBoyStatus.success
              ? DeliveryBoyStatus.success
              : DeliveryBoyStatus.failure,
          isRefreshing: false,
          errorMessage: error is ApiException ? error.message : '',
          errorStatusCode: error is ApiException ? error.statusCode : null,
        ),
      );
    }
  }

  Future<void> _loadMore(bool assigned, Emitter<DeliveryBoyState> emit) async {
    if (!canView ||
        (!assigned && !canManage) ||
        state.isRefreshing ||
        state.status != DeliveryBoyStatus.success ||
        (assigned
            ? state.isLoadingMoreAssigned || !state.assignedHasMore
            : state.isLoadingMoreAvailable || !state.availableHasMore)) {
      return;
    }
    final version = _fetchVersion;
    final next = (assigned ? state.assignedPage : state.availablePage) + 1;
    emit(
      state.copyWith(
        isLoadingMoreAssigned: assigned ? true : null,
        isLoadingMoreAvailable: assigned ? null : true,
      ),
    );
    try {
      final response = await _repo.getRiders(
        page: assigned ? next : 1,
        availablePage: assigned ? 1 : next,
        search: state.search,
      );
      if (version != _fetchVersion) return;
      final page = assigned ? response.assigned : response.available;
      final current = assigned ? state.assigned : state.available;
      final seen = current.map((rider) => rider.id).toSet();
      final merged = [
        ...current,
        ...page.data.where((rider) => !seen.contains(rider.id)),
      ];
      emit(
        assigned
            ? state.copyWith(
                assigned: merged,
                assignedPage: page.currentPage,
                assignedTotal: page.total,
                assignedHasMore: page.hasMore,
                isLoadingMoreAssigned: false,
              )
            : state.copyWith(
                available: merged,
                availablePage: page.currentPage,
                availableTotal: page.total,
                availableHasMore: page.hasMore,
                isLoadingMoreAvailable: false,
              ),
      );
    } catch (error) {
      if (version != _fetchVersion) return;
      emit(
        state.copyWith(
          isLoadingMoreAssigned: assigned ? false : null,
          isLoadingMoreAvailable: assigned ? null : false,
          errorMessage: error is ApiException ? error.message : '',
          errorStatusCode: error is ApiException ? error.statusCode : null,
        ),
      );
      if (error is ApiException && error.statusCode == 404) {
        add(const FetchRiders(silent: true));
      }
    }
  }

  Future<void> _write(
    int id,
    DeliveryBoyEvent event,
    Emitter<DeliveryBoyState> emit,
  ) async {
    if (!canManage || state.busyRiderIds.contains(id)) return;
    final session = _sessionVersion;
    emit(
      state.copyWith(
        busyRiderIds: {...state.busyRiderIds, id},
        clearMessages: true,
        fieldErrors: {},
      ),
    );
    try {
      DeliveryBoyResult? riderResult;
      String message = "";
      Map<String, dynamic>? decision;
      if (event is ClaimRider) {
        riderResult = await _repo.claimRider(id);
      } else if (event is UpdateRider) {
        riderResult = await _repo.updateRider(
          id,
          fullName: event.fullName,
          email: event.email,
          mobile: event.mobile,
          password: event.password,
          deliveryZoneId: event.deliveryZoneId,
        );
      } else if (event is CreateRider) {
        riderResult = await _repo.createRider(
          fullName: event.fullName,
          email: event.email,
          mobile: event.mobile,
          password: event.password,
          deliveryZoneId: event.deliveryZoneId,
        );
      } else if (event is DeleteRider) {
        message = await _repo.deleteRider(id);
      } else if (event is ApproveLogin) {
        decision = await _repo.approveLogin(
          id,
          durationHours: event.durationHours,
        );
      } else if (event is RejectLogin) {
        decision = await _repo.rejectLogin(id);
      }
      if (session != _sessionVersion) return;
      final rider = riderResult?.rider;
      if (riderResult != null) message = riderResult.message;
      if (decision != null) {
        message = JsonParser.string(decision['message']);
        decision = Map<String, dynamic>.from(decision['data']);
      }
      var assigned = [...state.assigned];
      var available = [...state.available];
      var total = state.assignedTotal;
      var availableTotal = state.availableTotal;
      if (rider != null) {
        final index = assigned.indexWhere((item) => item.id == rider.id);
        if (index < 0) {
          assigned.insert(0, rider);
          total++;
        } else {
          assigned[index] = rider;
        }
        if (event is ClaimRider) {
          available.removeWhere((item) => item.id == id);
          availableTotal = (availableTotal - 1).clamp(0, 1 << 30);
        }
      } else if (event is DeleteRider) {
        assigned.removeWhere((item) => item.id == id);
        total = (total - 1).clamp(0, 1 << 30);
      } else if (decision != null) {
        assigned = assigned
            .map(
              (item) => item.id != id
                  ? item
                  : item.copyWith(
                      // Approval never activates a rider. Only use an explicit response status.
                      status: decision!['status'] == 'active'
                          ? RiderStatus.active
                          : RiderStatus.inactive,
                      loginApproval: event is RejectLogin
                          ? RiderLoginApproval.disapproved
                          : RiderLoginApproval.approved,
                      loginApprovedUntil: riderLocalDate(
                        decision['login_approved_until'],
                      ),
                      clearApprovedUntil:
                          decision['login_approved_until'] == null,
                    ),
            )
            .toList();
      }
      _fetchVersion++; // Ignore reads started before this mutation completed.
      emit(
        state.copyWith(
          assigned: assigned,
          assignedTotal: total,
          available: available,
          availableTotal: availableTotal,
          busyRiderIds: {...state.busyRiderIds}..remove(id),
          actionMessage: message,
        ),
      );
      add(const FetchRiders(silent: true));
    } catch (error) {
      if (session != _sessionVersion) return;
      final apiError = error is ApiException ? error : null;
      final conflict =
          event is ClaimRider &&
          apiError?.statusCode == 409 &&
          apiError?.responseData?['data'] is Map &&
          apiError!.responseData!['data']['code'] == 'rider_already_assigned';
      final errors = apiError?.responseData?['errors'];
      emit(
        state.copyWith(
          busyRiderIds: {...state.busyRiderIds}..remove(id),
          errorMessage: apiError?.message ?? '',
          errorStatusCode: apiError?.statusCode,
          fieldErrors: event is CreateRider && errors is Map
              ? errors.map(
                  (key, value) => MapEntry(
                    key.toString(),
                    value is List
                        ? value.map((v) => v.toString()).join('\n')
                        : value.toString(),
                  ),
                )
              : {},
          available: conflict
              ? state.available.where((item) => item.id != id).toList()
              : null,
          availableTotal: conflict
              ? (state.availableTotal - 1).clamp(0, 1 << 30)
              : null,
        ),
      );
      if (conflict || apiError?.statusCode == 404) {
        add(const FetchRiders(silent: true));
      }
    }
  }
}
