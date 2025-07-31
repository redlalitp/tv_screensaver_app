import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeWidget extends StatefulWidget {
  const TimeWidget({super.key});

  @override
  State<TimeWidget> createState() => _TimeWidgetState();
}

class _TimeWidgetState extends State<TimeWidget> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNight = _now.hour < 6 || _now.hour > 18;

    final timeString = DateFormat('HH:mm').format(_now);
    final dayString = DateFormat('EEEE').format(_now);
    final dateString = DateFormat('d MMM yyyy').format(_now);
    final textColor = isNight ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          timeString,
          style: TextStyle(fontSize: 48, color: textColor),
        ),
        const SizedBox(height: 4),
        Text(
          '$dayString, $dateString',
          style: TextStyle(fontSize: 20, color: textColor),
        ),
      ],
    );
  }
}
