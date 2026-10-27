import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

// A record distinguishes cancelling the sheet from choosing the nullable server default.
typedef LoginDurationSelection = ({int? hours});

class LoginDurationSheet extends StatefulWidget {
  final bool rotate;
  const LoginDurationSheet({super.key, this.rotate = false});
  static Future<LoginDurationSelection?> show(
    BuildContext context, {
    bool rotate = false,
  }) => showModalBottomSheet<LoginDurationSelection>(
    context: context,
    isScrollControlled: true,
    builder: (_) => LoginDurationSheet(rotate: rotate),
  );
  @override
  State<LoginDurationSheet> createState() => _LoginDurationSheetState();
}

class _LoginDurationSheetState extends State<LoginDurationSheet> {
  final _custom = TextEditingController();
  int _preset = 12;
  bool _isCustom = false;
  bool _useDefault = false;
  bool _submitted = false;
  int? get _hours => _isCustom ? int.tryParse(_custom.text) : _preset;
  bool get _valid =>
      _useDefault || (_hours != null && _hours! >= 1 && _hours! <= 720);
  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final until = DateFormat(
      'd MMM, h:mm a',
    ).format(DateTime.now().add(Duration(hours: _hours ?? 12)));
    return SafeArea(
      child: SingleChildScrollView(
        padding: UIUtils.pagePadding(
          context.screenType,
        ).add(EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.rotate
                  ? l10n?.riderRegenerateQr ?? 'Regenerate QR'
                  : l10n?.riderApprovePassword ?? 'Approve password login',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final hours in [1, 4, 6, 12, 24])
                  ChoiceChip(
                    label: Text(l10n?.riderDurationHours(hours) ?? '${hours}h'),
                    selected: !_isCustom && !_useDefault && _preset == hours,
                    onSelected: (_) => setState(() {
                      _preset = hours;
                      _isCustom = false;
                      _useDefault = false;
                    }),
                  ),
                ChoiceChip(
                  label: Text(l10n?.riderCustomDuration ?? 'Custom'),
                  selected: _isCustom && !_useDefault,
                  onSelected: (_) => setState(() {
                    _isCustom = true;
                    _useDefault = false;
                  }),
                ),
              ],
            ),
            if (_isCustom && !_useDefault)
              TextField(
                controller: _custom,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n?.riderDurationLabel ?? 'Duration (hours)',
                  errorText: !_valid && (_submitted || _custom.text.isNotEmpty)
                      ? l10n?.riderDurationError ??
                            'Enter a whole number from 1 to 720'
                      : null,
                ),
              ),
            if (!widget.rotate)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n?.riderUseDefault ?? 'Use platform default'),
                value: _useDefault,
                onChanged: (value) =>
                    setState(() => _useDefault = value ?? false),
              ),
            const SizedBox(height: 8),
            Text(
              l10n?.riderDurationMaximum ??
                  'Maximum duration is set by the platform.',
            ),
            const SizedBox(height: 12),
            Text(
              _useDefault
                  ? l10n?.riderDefaultPreview ??
                        "The platform chooses the login duration. Approval alone doesn't log them in."
                  : widget.rotate
                  ? l10n?.riderRotatePreview(until) ??
                        'New QR valid until $until. The old QR and its session stop working.'
                  : l10n?.riderApprovePreview(until) ??
                        "Rider can log in with email and password until $until. Approval alone doesn't log them in.",
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  setState(() => _submitted = true);
                  if (_valid) {
                    Navigator.pop<LoginDurationSelection>(context, (
                      hours: _useDefault ? null : _hours,
                    ));
                  }
                },
                child: Text(l10n?.confirm ?? 'Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
