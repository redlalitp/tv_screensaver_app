import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_screensaver_app/services/unsplash_service.dart';
import 'package:tv_screensaver_app/widgets/time_widget.dart';
import 'package:tv_screensaver_app/widgets/weather_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class _ScreensaverScreenState extends State<ScreensaverScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Timer _countdownTimer;
  int _currentImageIndex = 0;
  int _secondsLeft = 30;
  final _categories = [
    'animation movie background kids',
    'nature kids friendly landscape',
    'animals kids friendly'
  ];

  List<String> _imageUrls = [];
  Color _textColor = Colors.black;
  bool _showGradient = false;
  final Map<String, Color> _paletteCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeImages());
  }

  Future<void> _initializeImages() async {
    await _loadImages();

    if (_imageUrls.isNotEmpty) {
      _updatePalette(_imageUrls[_currentImageIndex]);
      _timer = Timer.periodic(Duration(seconds: 30), (_) => _nextImage());
      _countdownTimer = Timer.periodic(Duration(seconds: 1), (_) {
        setState(() => _secondsLeft = (_secondsLeft - 1) % 30);
      });
    }
  }

  void _nextImage() {
    setState(() {
      _currentImageIndex = (_currentImageIndex + 1) % _imageUrls.length;
      _secondsLeft = 30;
    });
    _updatePalette(_imageUrls[_currentImageIndex]);
  }

  Future<void> _loadImages() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetch = prefs.getString('lastFetchDate');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (lastFetch != today) {
      final service = UnsplashService();
      final urls = await service.fetchDailyImages(_categories);
      if (urls.isNotEmpty) {
        _imageUrls = urls;
        prefs.setStringList('cachedImages', urls);
        prefs.setString('lastFetchDate', today);
      }
    } else {
      _imageUrls = prefs.getStringList('cachedImages') ?? [];
    }

    if (mounted) setState(() {});
  }

  Future<void> _updatePalette(String imageUrl) async {
    if (_paletteCache.containsKey(imageUrl)) {
      setState(() {
        _textColor = _paletteCache[imageUrl]!;
        _showGradient = true;
      });
      return;
    }

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
      );
      final dominantColor = palette.dominantColor?.color ?? Colors.black;
      final hsl = HSLColor.fromColor(dominantColor);
      final complementary = hsl.withHue((hsl.hue + 180) % 360);
      final adjustedLightness = hsl.lightness < 0.3
          ? 0.8
          : (hsl.lightness > 0.7 ? 0.2 : hsl.lightness);
      final contrastColor =
      complementary.withLightness(adjustedLightness).toColor().withOpacity(0.7);

      _paletteCache[imageUrl] = contrastColor;

      setState(() {
        _textColor = contrastColor;
        _showGradient = false;
      });

      await Future.delayed(Duration(milliseconds: 100));
      if (mounted) {
        setState(() => _showGradient = true);
      }
    } catch (_) {
      setState(() {
        _textColor = Colors.black.withOpacity(0.9);
        _showGradient = true;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNight = DateTime.now().hour < 6 || DateTime.now().hour > 18;
    final currentImage =
    _imageUrls.isNotEmpty ? _imageUrls[_currentImageIndex] : null;

    return Scaffold(
      backgroundColor: isNight ? Colors.black : Colors.blueGrey.shade100,
      body: Stack(
        children: [
          if (currentImage != null)
            FadeInImage.assetNetwork(
              placeholder: '',
              image: currentImage,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          if (currentImage != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: Duration(seconds: 2),
                opacity: _showGradient ? 1.0 : 0.0,
                child: Container(
                  margin: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    // gradient: LinearGradient(
                    //   begin: Alignment.bottomCenter,
                    //   end: Alignment.topCenter,
                    //   colors: isNight
                    //       ? [Colors.black.withOpacity(0.6), Colors.transparent]
                    //       : [Colors.white.withOpacity(0.6), Colors.transparent],
                    // ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 24, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            WeatherWidget(textColor: _textColor),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                TimeWidget(textColor: _textColor),
                                SizedBox(height: 4),
                                Animate(
                                  effects: [FadeEffect()],
                                  child: Text(
                                    '$_secondsLeft s',
                                    style: GoogleFonts.lato(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: _textColor.withOpacity(0.9),
                                      shadows: [
                                        Shadow(
                                          blurRadius: 2,
                                          color: Colors.black,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
