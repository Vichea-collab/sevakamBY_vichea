import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../constants/app_colors.dart';

Future<DateTime?> showAppCalendarDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  String confirmText = 'Apply',
  String cancelText = 'Cancel',
  SelectableDayPredicate? selectableDayPredicate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => _AdvancedCalendarDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
      confirmText: confirmText,
      cancelText: cancelText,
      selectableDayPredicate: selectableDayPredicate,
    ),
  );
}

class _AdvancedCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? helpText;
  final String confirmText;
  final String cancelText;
  final SelectableDayPredicate? selectableDayPredicate;

  const _AdvancedCalendarDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.helpText,
    required this.confirmText,
    required this.cancelText,
    this.selectableDayPredicate,
  });

  @override
  State<_AdvancedCalendarDialog> createState() => _AdvancedCalendarDialogState();
}

class _AdvancedCalendarDialogState extends State<_AdvancedCalendarDialog> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    // Clamp initialDate within range to prevent TableCalendar crash
    final safeDate = widget.initialDate.isBefore(widget.firstDate)
        ? widget.firstDate
        : widget.initialDate.isAfter(widget.lastDate)
            ? widget.lastDate
            : widget.initialDate;
            
    _focusedDay = safeDate;
    _selectedDay = safeDate;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.helpText != null) ...[
              Text(
                widget.helpText!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            TableCalendar(
              firstDay: widget.firstDate,
              lastDay: widget.lastDate,
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (widget.selectableDayPredicate != null &&
                    !widget.selectableDayPredicate!(selectedDay)) {
                  return;
                }
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              enabledDayPredicate: widget.selectableDayPredicate,
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(color: AppColors.primary),
                disabledTextStyle: const TextStyle(color: AppColors.danger),
              ),
              calendarBuilders: CalendarBuilders(
                disabledBuilder: (context, day, focusedDay) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(4.0),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: const TextStyle(color: AppColors.danger),
                          ),
                          Transform.rotate(
                            angle: -0.5,
                            child: Container(
                              width: 20,
                              height: 1,
                              color: AppColors.danger.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(widget.cancelText),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedDay),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(widget.confirmText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
