import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/popup_users/repo/popup_users_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

import 'popup_users_state.dart';

export 'popup_users_state.dart';

/// System-user availability for incoming-order popups, for the main seller
/// owner. Nothing in the user data marks the owner, so the first load also
/// decides whether the Orders page offers the dashboard at all: a 403 hides
/// it for the rest of the session.
class PopupUsersCubit extends Cubit<PopupUsersState> {
  final PopupUsersRepo _repo;
  final Duration pollInterval;
  Timer? _timer;
  Future<void>? _inFlight;
  int _session = 0;

  PopupUsersCubit(
    this._repo, {
    this.pollInterval = const Duration(seconds: 30),
  }) : super(const PopupUsersState());

  Future<void> refresh() {
    if (isClosed || state.isForbidden) return Future.value();
    if (_inFlight != null) return _inFlight!;
    final task = _read(_session);
    _inFlight = task;
    return task.whenComplete(() {
      if (identical(_inFlight, task)) _inFlight = null;
    });
  }

  /// Loads once to learn whether this user may see the dashboard.
  Future<void> checkAccess() {
    if (state.data != null || state.isForbidden) return Future.value();
    return refresh();
  }

  Future<void> _read(int session) async {
    emit(state.copyWith(isLoading: state.data == null, clearError: true));
    try {
      final data = await _repo.getAvailability();
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
        debugPrint('[PopupUsers] refresh failed: $error');
        emit(
          state.copyWith(
            isLoading: false,
            error: error is ApiException ? error.message : '',
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

  /// On logout, so the next user's access is checked afresh.
  void reset() {
    stopPolling();
    _session++;
    _inFlight = null;
    emit(const PopupUsersState());
  }

  @override
  Future<void> close() {
    stopPolling();
    _session++;
    return super.close();
  }
}
