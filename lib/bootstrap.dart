import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> bootstrap() async {
  await dotenv.load(fileName: ".env");
  await Future.wait([
    SharedPreferences.getInstance(), // trigger caching
    Future.delayed(Duration(milliseconds: 10)), // simulate async parallel
  ]);
}
