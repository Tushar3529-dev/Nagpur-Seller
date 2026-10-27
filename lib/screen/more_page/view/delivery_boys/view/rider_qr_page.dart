import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/bloc/delivery_boy_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/model/delivery_boy_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/qr/rider_qr_cubit.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/repo/delivery_boy_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_boys/widgets/login_duration_sheet.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';

class RiderQrPage extends StatelessWidget {
  final DeliveryBoy rider;
  const RiderQrPage({super.key, required this.rider});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        RiderQrCubit(repo: context.read<DeliveryBoyRepo>(), riderId: rider.id),
    child: _RiderQrView(rider: rider),
  );
}

class _RiderQrView extends StatefulWidget {
  final DeliveryBoy rider;
  const _RiderQrView({required this.rider});
  @override
  State<_RiderQrView> createState() => _RiderQrViewState();
}

class _RiderQrViewState extends State<_RiderQrView> {
  late final DeliveryBoyBloc _listBloc;
  int _refreshVersion = 0;
  @override
  void initState() {
    super.initState();
    _listBloc = context.read<DeliveryBoyBloc>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.rider.isVerified &&
          DeliveryBoyBloc.canManage &&
          DemoGuard.shouldProceed(context)) {
        context.read<RiderQrCubit>().load();
      }
    });
  }

  @override
  void dispose() {
    if (!_listBloc.isClosed) _listBloc.add(const FetchRiders(silent: true));
    super.dispose();
  }

  Future<void> _rotate() async {
    if (!DeliveryBoyBloc.canManage) return;
    final selection = await LoginDurationSheet.show(context, rotate: true);
    if (!mounted ||
        selection?.hours == null ||
        !DeliveryBoyBloc.canManage ||
        !DemoGuard.shouldProceed(context)) {
      return;
    }
    await context.read<RiderQrCubit>().rotate(selection!.hours!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomScaffold(
      showAppbar: true,
      centerTitle: true,
      title:
          l10n?.riderQrTitle(widget.rider.name) ??
          'Login QR · ${widget.rider.name}',
      body: BlocConsumer<RiderQrCubit, RiderQrState>(
        listener: (context, state) {
          if (state.refreshVersion != _refreshVersion ||
              state.errorStatusCode == 404) {
            _refreshVersion = state.refreshVersion;
            _listBloc.add(const FetchRiders(silent: true));
          }
          if (state.errorMessage != null &&
              (state.credential != null ||
                  state.errorStatusCode == 404 ||
                  state.errorStatusCode == 403)) {
            showCustomSnackbar(
              context: context,
              message: state.errorStatusCode == 403
                  ? l10n?.riderNoManagePermission ??
                        "You don't have permission to manage delivery boys"
                  : state.errorMessage!.isEmpty
                  ? l10n?.somethingWentWrong ?? 'Something went wrong'
                  : state.errorMessage!,
              isError: true,
            );
          }
          if (state.rotatedMessage != null) {
            showCustomSnackbar(
              context: context,
              message: state.rotatedMessage!,
            );
          }
        },
        listenWhen: (previous, current) =>
            previous.refreshVersion != current.refreshVersion ||
            previous.errorMessage != current.errorMessage ||
            previous.rotatedMessage != current.rotatedMessage,
        builder: (context, state) {
          if (!DeliveryBoyBloc.canManage ||
              !widget.rider.isVerified ||
              (state.errorMessage != null && state.credential == null)) {
            return EmptyStateWidget(
              svgPath: ImagesPath.noSearchFoundSvg,
              title: !DeliveryBoyBloc.canManage
                  ? l10n?.riderNoManagePermission ??
                        "You don't have permission to manage delivery boys"
                  : !widget.rider.isVerified
                  ? l10n?.riderQrAfterVerification ??
                        'Available after platform verification'
                  : state.errorStatusCode == 403
                  ? l10n?.riderNoManagePermission ??
                        "You don't have permission to manage delivery boys"
                  : state.errorMessage?.isNotEmpty == true
                  ? state.errorMessage!
                  : l10n?.somethingWentWrong ?? 'Something went wrong',
              actionText: l10n?.riderBack ?? 'Back',
              onAction: () => context.pop(),
            );
          }
          final credential = state.credential;
          if (credential == null) {
            return const Center(child: CustomLoadingIndicator());
          }
          final seconds = state.remaining.inSeconds.clamp(0, 1 << 30);
          final countdown = [
            seconds ~/ 3600,
            seconds ~/ 60 % 60,
            seconds % 60,
          ].map((value) => value.toString().padLeft(2, '0')).join(':');
          return Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: UIUtils.pagePadding(context.screenType),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrImageView(
                        data: credential.qrPayload,
                        size: 240.w.clamp(200, 360).toDouble(),
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Chip(
                        label: Text(
                          l10n?.riderExpiresIn(countdown) ??
                              'Expires in $countdown',
                        ),
                      ),
                      if (credential.expiresAt != null)
                        Text(
                          DateFormat(
                            'd MMM, h:mm a',
                          ).format(credential.expiresAt!),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        l10n?.riderQrCaption ??
                            "The rider scans this in the rider app to log in. Don't share it.",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: state.isRotating || state.loading
                            ? null
                            : _rotate,
                        child: Text(l10n?.riderRegenerateQr ?? 'Regenerate QR'),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.loading || state.isRotating)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x88FFFFFF),
                    child: Center(child: CustomLoadingIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
