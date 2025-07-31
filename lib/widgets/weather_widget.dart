import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  String? _temperature;
  String? _weatherDescription;
  String? _weatherIcon;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchWeather(); // Initial call
    _refreshTimer = Timer.periodic(Duration(minutes: 5), (_) => _fetchWeather());
  }

  Future<void> _fetchWeather() async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null) {
      print('API key not found in .env file');
      return;
    }

    const city = 'Pune';
    final url = 'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final temp = data['main']['temp'].toStringAsFixed(0);
        final description = data['weather'][0]['description'];
        final icon = data['weather'][0]['icon'];

        // Only update UI if values changed
        if (_temperature != '$temp°C' || _weatherDescription != description || _weatherIcon != icon) {
          setState(() {
            _temperature = '$temp°C';
            _weatherDescription = description;
            _weatherIcon = icon;
          });
        }
      } else {
        print('Weather API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to fetch weather: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isNight = now.hour < 6 || now.hour > 18;

    if (_temperature == null || _weatherIcon == null) return const SizedBox.shrink();

    final iconUrl = "https://openweathermap.org/img/wn/${_weatherIcon}@2x.png";
    final tempString = "${_temperature}\n${_weatherDescription ?? ''}";

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.network(iconUrl, width: 50, height: 50),
        const SizedBox(width: 8),
        Text(
          tempString,
          style: TextStyle(
            fontSize: 20,
            color: isNight ? Colors.white : Colors.black,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
