import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weather_icons/weather_icons.dart';

class WeatherWidget extends StatefulWidget {
  final Color textColor;

  const WeatherWidget({super.key, required this.textColor});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Timer? _refreshTimer;
  Map<String, dynamic>? weatherData;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _refreshTimer =
        Timer.periodic(const Duration(minutes: 5), (_) => _loadWeather());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null) {
      print('OpenWeatherMap API key missing');
      return;
    }

    const city = 'Chinchwad';
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      if (mounted) {
        setState(() => weatherData = data);
      }
    } catch (e) {
      print('Weather fetch failed: $e');
    }
  }

  String _chooseAnimation(String desc, double temp) {
    final now = DateTime.now();
    final isNight = now.hour < 6 || now.hour > 18;

    desc = desc.toLowerCase();
    if (desc.contains('rain') || desc.contains('drizzle')) {
      return 'assets/lottie/rain.json';
    } else if (desc.contains('thunder') || desc.contains('storm')) {
      return 'assets/lottie/storm.json';
    } else if (desc.contains('overcast')) {
      return 'assets/lottie/overcast.json';
    } else if (desc.contains('partly')) {
      return 'assets/lottie/partly-cloudy.json';
    } else if (desc.contains('cloud')) {
      return 'assets/lottie/cloudy.json';
    } else if (desc.contains('wind') || desc.contains('breeze')) {
      return 'assets/lottie/windy.json';
    } else if (temp > 35) {
      return 'assets/lottie/hot.json';
    } else {
      return isNight ? 'assets/lottie/night.json' : 'assets/lottie/clear.json';
    }
  }

  String formatTime(int timestamp) {
    return DateFormat.Hm().format(
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));
  }

  @override
  Widget build(BuildContext context) {
    if (weatherData == null) {
      return const SizedBox.shrink();
    }

    final city = weatherData!['name'] ?? '';
    final country = weatherData!['sys']['country'] ?? '';
    final temp = weatherData!['main']['temp'] ?? 0.0;
    final description = weatherData!['weather'][0]['description'] ?? '';
    final humidity = weatherData!['main']['humidity'] ?? 0;
    final pressure = weatherData!['main']['pressure'] ?? 0;
    final wind = weatherData!['wind']['speed'] ?? 0.0;
    final clouds = weatherData!['clouds']['all'] ?? 0;
    final sunrise = weatherData!['sys']['sunrise'];
    final sunset = weatherData!['sys']['sunset'];

    final animAsset = _chooseAnimation(description, temp.toDouble());

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.20,
          child: Container(
            padding: const EdgeInsets.all(2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Lottie weather animation
                Lottie.asset(
                  animAsset,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),

                // Location and description
                Text(
                  '$city, $country',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: widget.textColor,
                  ),
                ),
                Text(
                  '${temp.toStringAsFixed(1)}°C \n ${description.toString().toUpperCase()}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: widget.textColor.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),

                // Weather info tiles in a wrap (2-3 per row)
                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildInfoTile(Icons.water_drop, "$humidity%", "Humidity", Colors.cyan),
                    _buildInfoTile(Icons.speed, "$pressure hPa", "Pressure", Colors.deepPurple),
                    _buildInfoTile(Icons.air, "${wind.toString()} m/s", "Wind", Colors.teal),
                    _buildInfoTile(Icons.cloud, "$clouds%", "Clouds", Colors.grey),
                    _buildInfoTile(WeatherIcons.sunrise, formatTime(sunrise), "Sunrise", Colors.orange),
                    _buildInfoTile(WeatherIcons.sunset, formatTime(sunset), "Sunset", Colors.deepOrange),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );


  }

  Widget _buildInfoTile(IconData icon, String value, String label, Color iconColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.robotoMono(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.textColor)),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: widget.textColor.withOpacity(0.6))),
      ],
    );
  }
}
