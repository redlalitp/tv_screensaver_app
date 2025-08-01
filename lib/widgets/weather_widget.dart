import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

class WeatherWidget extends StatefulWidget {
  final Color textColor;

  const WeatherWidget({super.key, required this.textColor});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  String? _temperature;
  String? _weatherDescription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _refreshTimer = Timer.periodic(Duration(minutes: 5), (_) => _loadWeather());
  }

  Future<void> _loadWeather() async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null) {
      print('OpenWeatherMap API key missing');
      return;
    }

    const city = 'Pune';
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      setState(() {
        _temperature = '${data['main']['temp'].round()}°C';
        _weatherDescription = (data['weather'][0]['main'] as String).toLowerCase();
      });
    } catch (e) {
      print('Weather fetch failed: $e');
    }
  }

  String _chooseAnimation(String desc, String temperature) {
    final now = DateTime.now();
    final isNight = now.hour < 6 || now.hour > 18;
    if (desc.contains('rain') || desc.contains('drizzle')) {
      return 'assets/lottie/rain.json';
    } else if (desc.contains('thunder') || desc.contains('storm')) {
      return 'assets/lottie/storm.json';
    } else if (desc.contains('cloud')) {
      return 'assets/lottie/cloudy.json';
    } else if (desc.contains('wind') || desc.contains('breeze')) {
      return 'assets/lottie/windy.json';
    }else if (int.parse(temperature) > 35) {
      return 'assets/lottie/hot.json';
    } else {
      return isNight ? 'assets/lottie/night.json' : 'assets/lottie/clear.json';
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_temperature == null || _weatherDescription == null) {
      return const SizedBox.shrink();
    }

    final animAsset = _chooseAnimation(_weatherDescription!,_temperature!);
    final tempText = '$_temperature\n${_weatherDescription![0].toUpperCase()}${_weatherDescription!.substring(1)}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: Lottie.asset(animAsset, repeat: true, fit: BoxFit.contain),
        ),
        const SizedBox(width: 8),
        Text(
          tempText,
          style: TextStyle(fontSize: 20, color: widget.textColor),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
