import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AnalogClock extends StatefulWidget {
  final Color textColor;
  final Color dominantColor;

  const AnalogClock({
    super.key,
    required this.textColor,
    required this.dominantColor,
  });

  @override
  State<AnalogClock> createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
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
    return SizedBox(
      width: 175,
      height: 175,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100), // circular clipping
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: widget.dominantColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: CustomPaint(
              painter: ClockPainter(_now, widget.dominantColor, widget.textColor),
            ),
          ),
        ),
      )
    );
  }
}

class ClockPainter extends CustomPainter {
  final DateTime now;
  final Color dominantColor;
  final Color textColor;

  ClockPainter(this.now, this.dominantColor, this.textColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Clock face
    final paintCircle = Paint()
      ..color = dominantColor.withOpacity(0.5)
      ..style = PaintingStyle.fill;


    canvas.drawCircle(center, radius, paintCircle);

    // Numbers
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30) * pi / 180;
      final x = center.dx + (radius - 25) * sin(angle);
      final y = center.dy - (radius - 25) * cos(angle);

      final tp = TextPainter(
        text: TextSpan(text: i.toString(), style: textStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }

    // Hour hand
    final hourAngle = ((now.hour % 12) + now.minute / 60) * 30 * pi / 180;
    final hourHandLength = radius * 0.5;
    final hourHandPaint = Paint()
      ..color = textColor
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + hourHandLength * sin(hourAngle),
        center.dy - hourHandLength * cos(hourAngle),
      ),
      hourHandPaint,
    );

    // Minute hand
    final minuteAngle = (now.minute + now.second / 60) * 6 * pi / 180;
    final minuteHandLength = radius * 0.7;
    final minuteHandPaint = Paint()
      ..color = textColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + minuteHandLength * sin(minuteAngle),
        center.dy - minuteHandLength * cos(minuteAngle),
      ),
      minuteHandPaint,
    );

    // Center dot
    final centerDotPaint = Paint()..color = textColor;
    canvas.drawCircle(center, 5, centerDotPaint);
  }

  @override
  bool shouldRepaint(ClockPainter oldDelegate) => true;
}
