import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

import '../bloc/wallet_bloc/wallet_bloc.dart';

class WithdrawRequestPage extends StatefulWidget {
  const WithdrawRequestPage({super.key});

  @override
  State<WithdrawRequestPage> createState() => _WithdrawRequestPageState();
}

class _WithdrawRequestPageState extends State<WithdrawRequestPage> {
  String _amount = '';

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(ClearWithdrawState());
  }

  void _onNumberTap(String number) {
    setState(() {
      _amount += number;
    });
  }

  void _onBackspace() {
    if (_amount.isNotEmpty) {
      setState(() {
        _amount = _amount.substring(0, _amount.length - 1);
      });
    }
  }

  void _onSubmit() {
    if (!PermissionChecker.hasPermission(AppPermissions.withdrawalRequest)) {
      showCustomSnackbar(
        context: context,
        message:
            AppLocalizations.of(context)?.noPermissionRequestWithdrawal ??
            "You don't have permission to request withdrawal",
        isWarning: true,
      );
      return;
    }
    if (!DemoGuard.shouldProceed(context)) {
      return;
    }
    if (_amount.isEmpty || double.tryParse(_amount) == 0) {
      showCustomSnackbar(
        context: context,
        message:
            AppLocalizations.of(context)?.enterValidAmount ??
            'Please enter a valid amount',
        isError: true,
      );
      return;
    }
    context.read<WalletBloc>().add(SubmitWithdrawRequest(amount: _amount));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenType = context.screenType;
    final theme = Theme.of(context);

    return BlocListener<WalletBloc, WalletState>(
      listenWhen: (previous, current) =>
          previous.withdrawStatus != current.withdrawStatus,
      listener: (context, state) {
        if (state.withdrawStatus == WithdrawStatus.success) {
          showCustomSnackbar(
            context: context,
            message:
                state.withdrawMessage ??
                'Withdrawal request submitted successfully',
          );
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else if (state.withdrawStatus == WithdrawStatus.failure) {
          showCustomSnackbar(
            context: context,
            message:
                state.withdrawMessage ??
                'Withdrawal request submitted successfully',
            isError: true,
          );
        }
      },
      child: CustomScaffold(
        title: l10n?.withdrawRequest ?? 'Withdraw Request',
        showAppbar: true,
        centerTitle: true,
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: UIUtils.pagePadding(screenType),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Display
                    Center(
                      child: Column(
                        children: [
                          Text(
                            l10n?.amountToWithdraw ?? 'Amount to Withdraw',
                            style: TextStyle(
                              fontSize: UIUtils.body(screenType),
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: UIUtils.gapMD(screenType)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                HiveStorage.currencySymbol,
                                style: TextStyle(
                                  fontSize: UIUtils.pageTitle(screenType),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                _amount.isEmpty ? '00' : _amount,
                                style: TextStyle(
                                  fontSize: UIUtils.pageTitle(screenType) * 2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: UIUtils.gapSM(screenType)),
                          BlocBuilder<WalletBloc, WalletState>(
                            builder: (context, state) {
                              String balance =
                                  state.walletData?.balance ?? '0.00';
                              return Text(
                                '${HiveStorage.currencySymbol}$balance ${l10n?.availableForWithdraw ?? 'Available for Withdraw'}',
                                style: TextStyle(
                                  fontSize: UIUtils.caption(screenType),
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Submit Button
            Padding(
              padding: UIUtils.pagePadding(screenType),
              child: BlocBuilder<WalletBloc, WalletState>(
                builder: (context, state) {
                  final isLoading =
                      state.withdrawStatus == WithdrawStatus.submitting;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: UIUtils.gapMD(screenType),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            UIUtils.radiusMD(screenType),
                          ),
                        ),
                      ),
                      child: isLoading
                          ? const CustomLoadingIndicator(
                              size: 20,
                              strokeWidth: 2,
                              color: Colors.white,
                            )
                          : Text(
                              l10n?.withdrawRequest ?? 'Withdraw Request',
                              style: TextStyle(
                                fontSize: UIUtils.tileTitle(screenType),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),

            // Custom Numeric Keyboard
            Container(
              padding: UIUtils.pagePadding(screenType),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Row 1: 1, 2, 3
                  _buildKeyboardRow(screenType, ['1', '2', '3']),
                  SizedBox(height: UIUtils.gapSM(screenType)),

                  // Row 2: 4, 5, 6
                  _buildKeyboardRow(screenType, ['4', '5', '6']),
                  SizedBox(height: UIUtils.gapSM(screenType)),

                  // Row 3: 7, 8, 9
                  _buildKeyboardRow(screenType, ['7', '8', '9']),
                  SizedBox(height: UIUtils.gapSM(screenType)),

                  // Row 4: Clear, 0, Backspace
                  Row(
                    children: [
                      Expanded(
                        child: _buildKeyButton(
                          screenType,
                          label: '.',
                          onTap: () => _onNumberTap('.'),
                        ),
                      ),
                      SizedBox(width: UIUtils.gapSM(screenType)),
                      Expanded(
                        child: _buildKeyButton(
                          screenType,
                          label: '0',
                          onTap: () => _onNumberTap('0'),
                        ),
                      ),
                      SizedBox(width: UIUtils.gapSM(screenType)),
                      Expanded(
                        child: _buildKeyButton(
                          screenType,
                          icon: Icons.backspace_outlined,
                          onTap: _onBackspace,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardRow(ScreenType screenType, List<String> numbers) {
    return Row(
      children: numbers.map((number) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: number != numbers.last ? UIUtils.gapSM(screenType) : 0,
            ),
            child: _buildKeyButton(
              screenType,
              label: number,
              onTap: () => _onNumberTap(number),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeyButton(
    ScreenType screenType, {
    String? label,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: label != null
              ? Text(
                  label,
                  style: TextStyle(
                    fontSize: UIUtils.pageTitle(screenType),
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Icon(icon, size: UIUtils.appBarIcon(screenType)),
        ),
      ),
    );
  }
}
