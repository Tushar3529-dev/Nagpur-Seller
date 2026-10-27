import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/dispatch/repo/dispatch_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'rider_availability_state.dart';

export 'rider_availability_state.dart';

class RiderAvailabilityCubit extends Cubit<RiderAvailabilityState> {
  final DispatchRepo _repo;
  final Duration pollInterval;
  Timer? _timer;
  Future<void>? _inFlight;
  int _session = 0;
  final _pollingOwners = <Object>{};
  RiderAvailabilityCubit(
    this._repo, {
    this.pollInterval = const Duration(seconds: 30),
  }) : super(const RiderAvailabilityState());

  Future<void> load() => _fetch();
  Future<void> refresh() => _fetch();
  Future<void> _fetch() {
    if (isClosed || state.isForbidden) return Future.value();
    if (_inFlight != null) return _inFlight!;
    final task = _read(_session);
    _inFlight = task;
    return task.whenComplete(() {
      if (identical(_inFlight, task)) _inFlight = null;
    });
  }

  Future<void> _read(int session) async {
    emit(state.copyWith(isLoading: state.data == null, clearError: true));
    try {
      final data = await _repo.getRiderAvailability();
      if (isClosed || session != _session) return;
      emit(
        state.copyWith(
          data: data,
          isLoading: false,
          clearError: true,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (error) {
      if (isClosed || session != _session) return;
      if (error is ApiException && error.statusCode == 403) {
        stopPolling();
        emit(
          state.copyWith(isForbidden: true, isLoading: false, clearError: true),
        );
      } else {
        debugPrint('Rider availability refresh failed');
        emit(
          state.copyWith(
            isLoading: false,
            error: state.data == null
                ? (error is ApiException ? error.message : '')
                : null,
            clearError: state.data != null,
          ),
        );
      }
    }
  }

  void startPolling() {
    if (isClosed || state.isForbidden || _timer != null) return;
    unawaited(refresh());
    _timer = Timer.periodic(pollInterval, (_) => refresh());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  // Orders and Dispatch center share one timer; releasing one never stops
  // the other (Dispatch opens on top of Orders, so their visibility changes
  // can arrive in either order).
  void setPollingOwner(Object owner, {required bool visible}) {
    if (visible) {
      _pollingOwners.add(owner);
      startPolling();
    } else {
      _pollingOwners.remove(owner);
      if (_pollingOwners.isEmpty) stopPolling();
    }
  }

  void toggleExpanded() => emit(state.copyWith(expanded: !state.expanded));
  void reset() {
    stopPolling();
    _pollingOwners.clear();
    _session++;
    _inFlight = null;
    emit(const RiderAvailabilityState());
  }

  @override
  Future<void> close() {
    stopPolling();
    _pollingOwners.clear();
    _session++;
    return super.close();
  }
}
