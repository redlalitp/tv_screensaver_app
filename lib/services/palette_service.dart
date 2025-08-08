import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

Future<Color> generateContrastColor(String imageUrl, Color dominantColor) async {
  final hsl = HSLColor.fromColor(dominantColor);
  final comp = hsl.withHue((hsl.hue + 180) % 360);
  final contrastBase = comp.withLightness(hsl.lightness < 0.3 ? 0.8 : 0.2).toColor();

  // Ensure minimum contrast ratio
  return contrastBase.computeLuminance() > 0.5
      ? Colors.white.withOpacity(0.8)
      : Colors.black.withOpacity(0.8);
}

Future<Color> generateDominantColor(String imageUrl) async {
  final palette = await PaletteGenerator.fromImageProvider(NetworkImage(imageUrl));
  final dominant = palette.dominantColor?.color ?? Colors.black;
  return dominant;
}
