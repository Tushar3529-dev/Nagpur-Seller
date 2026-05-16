import 'package:flutter/material.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';

class SchedulingStep extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  const SchedulingStep({super.key, required this.formKey});

  @override
  State<SchedulingStep> createState() => _SchedulingStepState();
}

class _SchedulingStepState extends State<SchedulingStep> {
  final TextEditingController _timingController = TextEditingController();
  final TextEditingController _orderPrepTimeController = TextEditingController();

  // Day configuration
  final Map<String, bool> _dayEnabled = {
    'monday': true,
    'tuesday': false,
    'wednesday': false,
    'thursday': false,
    'friday': false,
    'saturday': false,
    'sunday': false,
  };

  final Map<String, TimeOfDay> _fromTime = {
    'monday': const TimeOfDay(hour: 10, minute: 0),
    'tuesday': const TimeOfDay(hour: 10, minute: 0),
    'wednesday': const TimeOfDay(hour: 10, minute: 0),
    'thursday': const TimeOfDay(hour: 10, minute: 0),
    'friday': const TimeOfDay(hour: 10, minute: 0),
    'saturday': const TimeOfDay(hour: 10, minute: 0),
    'sunday': const TimeOfDay(hour: 10, minute: 0),
  };

  final Map<String, TimeOfDay> _toTime = {
    'monday': const TimeOfDay(hour: 20, minute: 0),
    'tuesday': const TimeOfDay(hour: 20, minute: 0),
    'wednesday': const TimeOfDay(hour: 20, minute: 0),
    'thursday': const TimeOfDay(hour: 20, minute: 0),
    'friday': const TimeOfDay(hour: 20, minute: 0),
    'saturday': const TimeOfDay(hour: 20, minute: 0),
    'sunday': const TimeOfDay(hour: 20, minute: 0),
  };

  @override
  void dispose() {
    _timingController.dispose();
    _orderPrepTimeController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute$period';
  }

  Future<void> _selectTime(BuildContext context, String day, bool isFromTime) async {
    final initialTime = isFromTime ? _fromTime[day]! : _toTime[day]!;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        if (isFromTime) {
          _fromTime[day] = picked;
        } else {
          _toTime[day] = picked;
        }
      });
    }
  }

  String _getDayLabel(String day, AppLocalizations l10n) {
    switch (day) {
      case 'monday':
        return 'monday';
      case 'tuesday':
        return 'tuesday';
      case 'wednesday':
        return 'wednesday';
      case 'thursday':
        return 'thursday';
      case 'friday':
        return 'friday';
      case 'saturday':
        return 'saturday';
      case 'sunday':
        return 'sunday';
      default:
        return day;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tertiary = theme.colorScheme.tertiary;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: 'timing',
            isRequired: true,
            hint: "Enter timing e.g. Mon-Fri 9am-6pm",
            controller: _timingController,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'orderPreparationTime',
            isRequired: true,
            hint: "Enter Order Preparation time in minutes",
            controller: _orderPrepTimeController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          Text(
            'timeSlotConfiguration',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: tertiary,
            ),
          ),
          const SizedBox(height: 16),
          // Day configuration list
          ..._dayEnabled.keys.map((day) => _buildDayRow(context, day, isDark, l10n, tertiary)),
        ],
      ),
    );
  }

  Widget _buildDayRow(BuildContext context, String day, bool isDark, AppLocalizations l10n, Color tertiary) {
    final isEnabled = _dayEnabled[day]!;
    final showTimePickers = day == 'monday' && isEnabled;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _getDayLabel(day, l10n),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: tertiary,
                ),
              ),
            ),
            Switch(
              value: isEnabled,
              onChanged: (value) {
                setState(() {
                  _dayEnabled[day] = value;
                });
              },
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF3B82F6),
            ),
          ],
        ),
        if (showTimePickers) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTimeButton(
                  context,
                  "From",
                  _formatTime(_fromTime[day]!),
                  () => _selectTime(context, day, true),
                  isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeButton(
                  context,
                  "To",
                  _formatTime(_toTime[day]!),
                  () => _selectTime(context, day, false),
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (day != 'sunday') const Divider(height: 1),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTimeButton(
    BuildContext context,
    String label,
    String time,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D1117) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: const TextStyle(fontSize: 14),
                ),
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
