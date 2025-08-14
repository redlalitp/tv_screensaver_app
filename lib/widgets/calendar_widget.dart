import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CalendarWidget extends StatefulWidget {
  final double width;
  final double height;

  const CalendarWidget({
    super.key,
    this.width = 200,
    this.height = 100,
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
      dayWidgets.add(const SizedBox.shrink()); // Empty spaces
    }

    final today = DateTime.now();
    for (int day = 1; day <= daysInMonth; day++) {
      final isToday = (_currentMonth == today.month &&
          _currentYear == today.year &&
          day == today.day);

      dayWidgets.add(
        Container(
          decoration: BoxDecoration(
            color: isToday ? Colors.orangeAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: TextStyle(
              color: isToday ? Colors.white : Colors.white70,
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              DateFormat.yMMMM().format(DateTime(_currentYear, _currentMonth)),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 1),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ...['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map((d) => Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
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
