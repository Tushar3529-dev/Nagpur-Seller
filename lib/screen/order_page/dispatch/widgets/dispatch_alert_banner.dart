import 'package:flutter/material.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

class DispatchAlertBanner extends StatelessWidget {
  final int count;
  final bool compact;
  final VoidCallback onTap;
  const DispatchAlertBanner({
    super.key,
    required this.count,
    this.compact = false,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.red.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(UIUtils.radiusMD(context.screenType)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          UIUtils.radiusMD(context.screenType),
        ),
        child: Padding(
          padding: EdgeInsets.all(UIUtils.gapMD(context.screenType)),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.dispatchNoRiderAlertTitle(count) ??
                          (count == 1
                              ? '1 order has no nearby rider'
                              : '$count orders have no nearby rider'),
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!compact)
                      Text(
                        l10n?.dispatchNoRiderAlertBody ??
                            'Deliver it yourself or wait for a rider nearby.',
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}
