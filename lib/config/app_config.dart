/// App Configuration
/// Change these values to customize for different WebTV Solutions sites
///
/// Sites:
/// - jammukashmir.tv (free, no login)
/// - raplay.se (free, no login)
/// - fcplay.se (paid, with login)

class AppConfig {
  // ===========================================
  // SITE CONFIGURATION - CHANGE THESE VALUES
  // ===========================================

  /// Site identifier: 'jammukashmir', 'raplay', 'fcplay'
  static const String siteId = 'jammukashmir';

  /// API base URL (using HTTP like the original app)
  static const String apiBaseUrl = 'http://jammukashmir.tv';

  /// App display name
  static const String appName = 'JKTV Live';

  /// App tagline
  static const String appTagline = '24/7 The Voice of Voiceless';

  /// Primary color (hex without #)
  static const int primaryColorValue = 0xFF1E88E5; // Blue

  /// Accent color
  static const int accentColorValue = 0xFFFF5722; // Orange

  /// Whether login is required
  static const bool requiresLogin = false;

  /// Whether this is a paid/subscription site
  static const bool isPaidSite = false;

  /// Live stream URL (if different from API)
  static const String? liveStreamUrl = null;

  /// App version
  static const String appVersion = '2.0.47';

  // ===========================================
  // API CREDENTIALS - From WebTV Solutions
  // ===========================================

  /// API Key
  static const String apiKey = 'db40ade832c4eaaa19c6c45c5bd0509b';

  /// Security Key for signature generation
  static const String securityKey = 'ZGI0MGFkZTgzMmM0ZWFhYTE5YzZjNDVjNWJkMDUwOWIxNzc0MGI1NGE4YmE2NmY1';

  // ===========================================
  // FIREBASE CONFIGURATION
  // ===========================================

  /// Firebase project ID (optional, for push notifications)
  static const String? firebaseProjectId = null;

  // ===========================================
  // COMPUTED PROPERTIES
  // ===========================================

  static String get apiUrl => '$apiBaseUrl/api.php';

  static bool get showLoginButton => requiresLogin || isPaidSite;
}


/// Configuration presets for different sites
class SiteConfigs {
  static const jammukashmir = {
    'siteId': 'jammukashmir',
    'apiBaseUrl': 'http://jammukashmir.tv',
    'appName': 'JKTV',
    'appTagline': 'Kashmir\'s First Independent WebTV',
    'primaryColor': 0xFF1E88E5,
    'accentColor': 0xFFFF5722,
    'requiresLogin': false,
    'isPaidSite': false,
  };

  static const raplay = {
    'siteId': 'raplay',
    'apiBaseUrl': 'https://raplay.se',
    'appName': 'RaPlay',
    'appTagline': 'Your Entertainment Hub',
    'primaryColor': 0xFF9C27B0,
    'accentColor': 0xFFE91E63,
    'requiresLogin': false,
    'isPaidSite': false,
  };

  static const fcplay = {
    'siteId': 'fcplay',
    'apiBaseUrl': 'https://fcplay.se',
    'appName': 'FCPlay',
    'appTagline': 'FilmCentrum Distribution',
    'primaryColor': 0xFF2196F3,
    'accentColor': 0xFF4CAF50,
    'requiresLogin': true,
    'isPaidSite': true,
  };
}
