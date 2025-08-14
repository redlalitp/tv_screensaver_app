import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CalendarWidget extends StatefulWidget {
  final double width;
  final double height;
  final Color textColor;
  final Color dominantColor;

  const CalendarWidget({
    super.key,
    this.width = 280,
    this.height = 200,
    required this.textColor,
    required this.dominantColor
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late int _currentMonth;
  late int _currentYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = now.month;
    _currentYear = now.year;
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = (_currentMonth % 12) + 1;
    });
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = (_currentMonth == 1) ? 12 : _currentMonth - 1;
    });
  }

  List<Widget> _buildCalendarDays() {
    final firstDayOfMonth = DateTime(_currentYear, _currentMonth, 1);
    final daysInMonth = DateTime(_currentYear, _currentMonth + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final List<Widget> dayWidgets = [];
    for (int i = 0; i < startWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    final today = DateTime.now();
    for (int day = 1; day <= daysInMonth; day++) {
      final isToday = (_currentMonth == today.month &&
          _currentYear == today.year &&
          day == today.day);

      dayWidgets.add(
        Container(
          margin: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: isToday ? widget.textColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            // border: isToday
            //     ? Border.all(color: Colors.white.withOpacity(0.8), width: 1)
            //     : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 14,
              color: isToday ? this.widget.dominantColor : this.widget.textColor,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }
    return dayWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKey: (node, event) {
        if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
          _nextMonth();
          return KeyEventResult.handled;
        }
        if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
          _prevMonth();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Month & Year
                Text(
                  DateFormat.yMMMM().format(DateTime(_currentYear, _currentMonth)),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                // Calendar Grid
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ...['S', 'M', 'T', 'W', 'T', 'F', 'S']
                        .map((d) => Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: widget.textColor,
                        ),
                      ),
                    )),
                    ..._buildCalendarDays(),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}
