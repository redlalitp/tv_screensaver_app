import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

class _ScreensaverScreenState extends State<ScreensaverScreen> {
  late Timer _timer;
  int _currentImageIndex = 0;
  final _categories = [
    'animation movie background kids',
    'nature kids friendly landscape',
    'animals kids friendly'
  ];

  List<String> _imageUrls = [];
  Color _textColor = Colors.white;
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
      _timer = Timer.periodic(Duration(seconds: 30), (timer) {
        _nextImage();
      });
    }
  }

  void _nextImage() {
    setState(() {
      _currentImageIndex = (_currentImageIndex + 1) % _imageUrls.length;
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
      final palette = await PaletteGenerator.fromImageProvider(NetworkImage(imageUrl));
      final dominantColor = palette.dominantColor?.color ?? Colors.black;

      final hsl = HSLColor.fromColor(dominantColor);
      final complementary = hsl.withHue((hsl.hue + 180) % 360);
      final adjustedLightness = hsl.lightness < 0.3
          ? 0.8
          : (hsl.lightness > 0.7 ? 0.2 : hsl.lightness);
      final contrastColor = complementary.withLightness(adjustedLightness).toColor().withOpacity(0.7);

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
        _textColor = Colors.white.withOpacity(0.9);
        _showGradient = true;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNight = DateTime.now().hour < 6 || DateTime.now().hour > 18;
    final currentImage = _imageUrls.isNotEmpty ? _imageUrls[_currentImageIndex] : null;

    return Scaffold(
      backgroundColor: isNight ? Colors.black : Colors.blueGrey.shade100,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: Duration(seconds: 2),
            child: currentImage != null
                ? Image.network(
              currentImage,
              key: ValueKey(currentImage),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const SizedBox.shrink();
              },
            )
                : const SizedBox.shrink(),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: RadialGradient(
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            WeatherWidget(textColor: _textColor),
                            TimeWidget(textColor: _textColor),
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
