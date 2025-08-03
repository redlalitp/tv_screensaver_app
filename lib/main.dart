import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tv_screensaver_app/screens/screensaver_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(ScreensaverApp());
}

class ScreensaverApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Advit's Screensaver",
      initialRoute: '/',
      routes: {
        '/': (context) => ScreensaverScreen(),
        '/screensaver': (context) => ScreensaverScreen(),
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
    );
  }
}
