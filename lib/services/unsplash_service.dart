import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class UnsplashService {
  static const _base = 'https://api.unsplash.com';

  // Fetches a single random image for a given category
  Future<String?> fetchRandomImageUrl(String category) async {
    final key = dotenv.env['UNSPLASH_ACCESS_KEY'];
    if (key == null) return null;

    final query = Uri.encodeComponent(category);
    final url = '$_base/photos/random?query=$query&orientation=landscape';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Client-ID $key'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['urls']['regular'];
    } else {
      print('Unsplash API error: ${response.statusCode}');
      return null;
    }
  }

  // Fetches up to 30 images for each category using search endpoint
  Future<List<String>> fetchDailyImages(List<String> categories) async {
    final List<String> urls = [];
    final key = dotenv.env['UNSPLASH_ACCESS_KEY'];
    if (key == null) return urls;

    for (final category in categories) {
      final query = Uri.encodeComponent(category);
      final url =
          '$_base/search/photos?query=$query&orientation=landscape&per_page=30';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Client-ID $key'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>;

        final images = results
            .map<String?>((item) => item['urls']?['regular'] as String?)
            .whereType<String>()
            .toList();

        images.shuffle(Random());

        urls.addAll(images);
      } else {
        print('Unsplash API error for "$category": ${response.statusCode}');
      }
    }

    return urls;
  }
}
