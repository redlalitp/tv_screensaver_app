import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tv_screensaver_app/widgets/time_widget.dart';
import 'package:tv_screensaver_app/widgets/weather_widget.dart';
import 'dart:async';

Future<void> main() async {
  await dotenv.load();
  runApp(ScreensaverApp());
}

class ScreensaverApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TV Screensaver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: ScreensaverScreen(),
    );
  }
}

class ScreensaverScreen extends StatefulWidget {
  @override
  _ScreensaverScreenState createState() => _ScreensaverScreenState();
}

class _ScreensaverScreenState extends State<ScreensaverScreen> {
  late Timer _timer;
  int _currentImageIndex = 0;
  final List<String> _imageUrls = [
    'https://picsum.photos/1920/1080?image=100',
    'https://picsum.photos/1920/1080?image=101',
    'https://picsum.photos/1920/1080?image=102',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _imageUrls.length;
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
    final now = DateTime.now();
    final hour = now.hour;
    final isNight = hour < 6 || hour > 18;

    return Scaffold(
      backgroundColor: isNight ? Colors.black : Colors.blueGrey.shade100,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: Duration(seconds: 2),
            child: Image.network(
              _imageUrls[_currentImageIndex],
              key: ValueKey(_imageUrls[_currentImageIndex]),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Bottom-right time/date
          Positioned(
            bottom: 16,
            right: 16,
            child: const TimeWidget(),
          ),

          // Bottom-left weather
          Positioned(
            bottom: 16,
            left: 16,
            child: const WeatherWidget(),
          ),
        ],
      ),
    );
  }
}
