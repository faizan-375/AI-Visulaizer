class UnsplashConfig {
  // TODO: Replace with your actual Unsplash API key
  // Get your API key from: https://unsplash.com/developers
  static const String accessKey = '-YewkPeK7UbtSxZSVuw_4tETgAgPUi7pWVOICi52Wuo';
  
  // Unsplash API settings
  static const String baseUrl = 'https://api.unsplash.com';
  static const String apiVersion = 'v1';
  
  // Image settings
  static const int defaultWidth = 600;
  static const int defaultHeight = 400;
  static const int maxImagesPerSection = 5;
  
  // Rate limiting
  static const int hourlyLimit = 50; // Free tier limit
  static const int dailyLimit = 500; // Free tier limit
  
  /// Check if API key is configured
  static bool get isConfigured => accessKey != 'YOUR_UNSPLASH_ACCESS_KEY_HERE' && accessKey.isNotEmpty;
  
  /// Get authorization header
  static Map<String, String> get headers => {
    'Authorization': 'Client-ID $accessKey',
    'Accept-Version': apiVersion,
  };
}
