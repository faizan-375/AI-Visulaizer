import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/unsplash_config.dart';

class UnsplashService {
  
  /// Search for images on Unsplash
  static Future<List<UnsplashImage>> searchImages(String query, {int page = 1, int perPage = 10}) async {
    try {
      // Check if API key is configured
      if (!UnsplashConfig.isConfigured) {
        print('🔍 Unsplash: API key not configured. Please set your Unsplash API key in UnsplashConfig.');
        return [];
      }
      
      final url = Uri.parse('${UnsplashConfig.baseUrl}/search/photos?query=$query&page=$page&per_page=$perPage');
      
      final response = await http.get(
        url,
        headers: UnsplashConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        return results.map((json) => UnsplashImage.fromJson(json)).toList();
      } else {
        print('Unsplash API Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Unsplash API Exception: $e');
      return [];
    }
  }

  /// Get minimal images for infographic (only 2-3 images total)
  static Future<Map<String, String>> getInfographicImages(String topic) async {
    final images = <String, String>{};
    
    // Only get 2-3 strategic images: header + 1-2 content images
    final searchQueries = _getMinimalSearchQueriesForTopic(topic);
    
    try {
      // Get images for selected sections only
      for (final entry in searchQueries.entries) {
        final section = entry.key;
        final query = entry.value;
        
        final searchResults = await searchImages(query, perPage: 3);
        
        if (searchResults.isNotEmpty) {
          // Use the first result for this section
          final image = searchResults.first;
          images[section] = image.urls['regular'] ?? image.urls['small'] ?? '';
          print('🔍 Unsplash: Found image for $section: ${image.urls['regular']}');
        } else {
          print('🔍 Unsplash: No images found for $section with query: $query');
        }
      }
    } catch (e) {
      print('🔍 Unsplash: Error getting infographic images: $e');
    }
    
    return images;
  }

  /// Get minimal search queries for only 2-3 strategic images
  static Map<String, String> _getMinimalSearchQueriesForTopic(String topic) {
    final lowerTopic = topic.toLowerCase();
    
    // Cricket/World Cup topics - only 3 images
    if (lowerTopic.contains('cricket') || lowerTopic.contains('world cup')) {
      return {
        'header': 'cricket world cup',
        'content1': 'cricket stadium',
        'content3': 'cricket players',
      };
    }
    
    // Food topics - only 3 images
    if (lowerTopic.contains('food') || lowerTopic.contains('biryani') || lowerTopic.contains('cuisine')) {
      return {
        'header': 'food cuisine cooking',
        'content1': 'food ingredients spices',
        'content3': 'restaurant dining',
      };
    }
    
    // Technology topics - only 3 images
    if (lowerTopic.contains('ai') || lowerTopic.contains('technology') || lowerTopic.contains('digital')) {
      return {
        'header': 'artificial intelligence technology',
        'content1': 'AI robots artificial intelligence',
        'content3': 'digital technology innovation',
      };
    }
    
    // Country topics - only 3 images
    if (lowerTopic.contains('pakistan') || lowerTopic.contains('india') || lowerTopic.contains('country')) {
      return {
        'header': 'country landmarks culture',
        'content1': 'country culture heritage',
        'content3': 'country tourism landmarks',
      };
    }
    
    // Default/general topics - only 3 images
    return {
      'header': topic,
      'content1': '$topic main topic',
      'content3': '$topic additional info',
    };
  }


  /// Get a single random image for a topic
  static Future<String?> getRandomImage(String query) async {
    try {
      final results = await searchImages(query, perPage: 1);
      if (results.isNotEmpty) {
        return results.first.urls['regular'] ?? results.first.urls['small'];
      }
    } catch (e) {
      print('🔍 Unsplash: Error getting random image: $e');
    }
    return null;
  }
}

class UnsplashImage {
  final String id;
  final String description;
  final Map<String, String> urls;
  final String altDescription;
  final Map<String, dynamic> user;

  UnsplashImage({
    required this.id,
    required this.description,
    required this.urls,
    required this.altDescription,
    required this.user,
  });

  factory UnsplashImage.fromJson(Map<String, dynamic> json) {
    return UnsplashImage(
      id: json['id'] ?? '',
      description: json['description'] ?? json['alt_description'] ?? '',
      urls: Map<String, String>.from(json['urls'] ?? {}),
      altDescription: json['alt_description'] ?? '',
      user: Map<String, dynamic>.from(json['user'] ?? {}),
    );
  }

  /// Get the best available image URL
  String get bestUrl {
    return urls['regular'] ?? urls['small'] ?? urls['thumb'] ?? '';
  }

  /// Get a formatted URL with specific dimensions
  String getFormattedUrl({int width = 600, int height = 400}) {
    final baseUrl = urls['raw'] ?? urls['full'] ?? urls['regular'] ?? '';
    if (baseUrl.isNotEmpty) {
      return '$baseUrl&w=$width&h=$height&fit=crop';
    }
    return bestUrl;
  }
}
