import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/bloc/delivery_boy_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/model/delivery_boy_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/repo/delivery_boy_repo.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';

// No diagnostic serialization: QR credentials live only in this page's state.
class RiderQrState {
  final bool loading;
  final RiderQrCredential? credential;
  final Duration remaining;
  final bool isRotating;
  final String? errorMessage;
  final String? rotatedMessage;
  final int refreshVersion;
  final int? errorStatusCode;
  const RiderQrState({
    this.loading = false,
    this.credential,
    this.remaining = Duration.zero,
    this.isRotating = false,
    this.errorMessage,
    this.rotatedMessage,
    this.refreshVersion = 0,
    this.errorStatusCode,
  });
}

class RiderQrCubit extends Cubit<RiderQrState> {
  final DeliveryBoyRepo _repo;
  final int riderId;
  Timer? _timer;
  RiderQrCubit({required DeliveryBoyRepo repo, required this.riderId})
    : _repo = repo,
      super(const RiderQrState());

  Future<void> load({bool expired = false}) async {
    if (isClosed ||
        state.loading ||
        state.isRotating ||
        !DeliveryBoyBloc.canManage) {
      return;
    }
    _timer?.cancel();
    emit(
      RiderQrState(
        loading: true,
        credential: state.credential,
        refreshVersion: state.refreshVersion + (expired ? 1 : 0),
      ),
    );
    try {
      final credential = await _repo.getLoginQr(riderId);
      if (isClosed) return;
      _show(credential);
    } catch (error) {
      if (isClosed) return;
      emit(
        RiderQrState(
          errorMessage: error is ApiException ? error.message : '',
          errorStatusCode: error is ApiException ? error.statusCode : null,
          refreshVersion: state.refreshVersion,
        ),
      );
    }
  }

  Duration _remaining(RiderQrCredential credential) {
    final remaining =
        credential.expiresAt?.difference(DateTime.now()) ?? Duration.zero;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _show(
    RiderQrCredential credential, {
    String? message,
    bool rotated = false,
  }) {
    _timer?.cancel();
    emit(
      RiderQrState(
        credential: credential,
        remaining: _remaining(credential),
        rotatedMessage: message,
        refreshVersion: state.refreshVersion + (rotated ? 1 : 0),
      ),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed) return;
      final credential = state.credential;
      if (credential == null) return;
      final remaining = _remaining(credential);
      if (remaining <= Duration.zero) {
        _timer?.cancel();
        load(expired: true);
      } else {
        emit(
          RiderQrState(
            credential: credential,
            remaining: remaining,
            refreshVersion: state.refreshVersion,
          ),
        );
      }
    });
  }

  Future<void> rotate(int hours) async {
    if (isClosed ||
        state.loading ||
        state.isRotating ||
        !DeliveryBoyBloc.canManage ||
        hours < 1 ||
        hours > 720) {
      return;
    }
    _timer?.cancel();
    emit(
      RiderQrState(
        credential: state.credential,
        remaining: state.remaining,
        isRotating: true,
        refreshVersion: state.refreshVersion,
      ),
    );
    try {
      final result = await _repo.rotateLoginQr(riderId, durationHours: hours);
      if (isClosed) return;
      _show(result.credential, message: result.message, rotated: true);
    } catch (error) {
      if (isClosed) return;
      final credential = state.credential;
      if (credential != null) _show(credential);
      emit(
        RiderQrState(
          credential: state.credential,
          remaining: state.remaining,
          errorMessage: error is ApiException ? error.message : '',
          errorStatusCode: error is ApiException ? error.statusCode : null,
          refreshVersion: state.refreshVersion,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    if (!isClosed) emit(const RiderQrState());
    return super.close();
  }
}
