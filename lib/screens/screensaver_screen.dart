import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_screensaver_app/services/unsplash_service.dart';
import 'package:tv_screensaver_app/widgets/time_widget.dart';
import 'package:tv_screensaver_app/widgets/weather_widget.dart';
import 'dart:math' hide log;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'dart:developer';

import '../services/palette_service.dart';
import '../utils/LruCache.dart';
import '../widgets/calendar_widget.dart';

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
    'nature',
    'planets',
    'astronomy'
  ];

  List<String> _imageUrls = [];
  Color _textColor = Colors.black;
  Color _dominantColor = Colors.black;
  bool _showGradient = false;
  final _paletteCache = LruCache<String, Color>(maxSize: 100);

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeImages());
  }

  Future<void> _initializeImages() async {
    await _loadImages();

    if (_imageUrls.isNotEmpty) {
      await _updatePalette(_imageUrls[_currentImageIndex]);
      _timer = Timer.periodic(Duration(seconds: 30), (_) => _nextImage());
      _countdownTimer = Timer.periodic(Duration(seconds: 1), (_) {
        setState(() => _secondsLeft = (_secondsLeft - 1) % 30);
      });
    }
    if (mounted) {
      setState(() {
        _isLoading = false; // Now set loading to false
      });
    }
  }

  void _nextImage() {
    setState(() {
      _currentImageIndex = (_currentImageIndex + Random().nextInt(100)) % _imageUrls.length;
      _secondsLeft = 30;
    });
    _updatePalette(_imageUrls[_currentImageIndex]); // Still commented out from previous step
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
    if (_paletteCache.containsKey('${imageUrl}-dominant')) {
      print('Palette cache hit for $imageUrl');
      setState(() {
        _textColor = getContrastColorFromPaletteCache(imageUrl)!;
        _dominantColor = getDominantColorFromPaletteCache(imageUrl)!;
        _showGradient = true;
      });
      return;
    }

    print('Palette cache miss for $imageUrl');

    try {

      final dominantColor = await generateDominantColor(imageUrl);

      final contrastColor = await generateContrastColor(imageUrl, dominantColor);

      print('Contrast color: $contrastColor');
      print('Dominant color: $dominantColor');

      setContrastColorToPaletteCache(imageUrl, contrastColor);
      setDominantColorToPaletteCache(imageUrl, dominantColor);

      print("cache updated successfully");

      setState(()  {
        _textColor = contrastColor;
        _showGradient = false;
        _dominantColor = dominantColor;
      });

      print("state updated successfully");

      await Future.delayed(Duration(milliseconds: 100));
      if (mounted) {
        setState(() => _showGradient = true);
      }

      print("gradient updated successfully");

    } catch (_) {
      print('Error generating palette for $imageUrl');
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black, // Or a placeholder color
        body: Center(
          child: SizedBox( // Constrain the size
            width: 60.0,
            height: 60.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 5.0, // Make it a bit thicker for visibility
            ),
          ),
        ),
      );
    }

    final isNight = DateTime.now().hour < 6 || DateTime.now().hour > 18;
    final currentImage =
    _imageUrls.isNotEmpty ? _imageUrls[_currentImageIndex] : null;

    if (currentImage == null) {
      // This is a fallback if still no image after loading attempt
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "No images available for screensaver.",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isNight ? Colors.black : Colors.blueGrey.shade100,
      body: Stack(
        children: [
          if (currentImage != null)
            FadeInImage.assetNetwork(
              placeholder: 'assets/images/placeholder.png',
              image: currentImage,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

          // Weather widget - right vertical column
          Positioned(
            top: 24,
            bottom: 24,
            right: 24,
            child: AnimatedOpacity(
              duration: Duration(seconds: 2),
              opacity: 1.0,
              child: _buildFrostedBox(
                isNight: isNight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WeatherWidget(textColor: _textColor),
                    SizedBox(height: 12),
                    // Add more widgets here if needed
                  ],
                ),
              ),
            ),
          ),

          // Time widget - bottom left
          Positioned(
            bottom: 24,
            left: 24,
            child: AnimatedOpacity(
              duration: Duration(seconds: 2),
              opacity: 1.0,
              child: _buildFrostedBox(
                isNight: isNight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 24, left: 24),
              child: _buildFrostedBox(
                isNight: isNight,

                  child: SizedBox(
                    height: 310, // adjust based on your design
                    child: CalendarWidget(textColor: _textColor, dominantColor: _dominantColor), // your month view widget
                  ),
                ),
              ),
          )
        ],
      ),

    );

  }

  Widget _buildFrostedBox({required Widget child, required bool isNight}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isNight
                ?  _dominantColor.withOpacity(0.2)
                : _dominantColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: child,
        ),
      ),
    );
  }

  Color? getContrastColorFromPaletteCache(String imageUrl) {
    return _paletteCache.get('${imageUrl}-contrast');
  }

  Color? getDominantColorFromPaletteCache(String imageUrl) {
    return _paletteCache.get('${imageUrl}-dominant');
  }

  void setContrastColorToPaletteCache(String imageUrl, Color contrastColor) {
   try {
     _paletteCache.put('${imageUrl}-contrast', contrastColor);
   }
   catch(e) {
     print("Error setting contrast color to palette cache: $e");
   }
  }

  void setDominantColorToPaletteCache(String imageUrl, Color dominantColor) {
    _paletteCache.put('${imageUrl}-dominant', dominantColor);
  }
}
