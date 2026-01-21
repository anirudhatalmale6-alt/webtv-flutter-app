import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/category.dart';
import '../models/video.dart';
import '../models/user.dart';

class WebTVApi {
  static final WebTVApi _instance = WebTVApi._internal();
  factory WebTVApi() => _instance;
  WebTVApi._internal();

  String? _sessionId;
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _sessionId != null;

  /// Generate timestamp in milliseconds
  String _getTimestamp() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Generate random salt and MD5 hash it
  String _getSalt() {
    final random = Random();
    final randomNum = random.nextInt(9000000000) + 1000000000;
    final bytes = utf8.encode(randomNum.toString());
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Generate HMAC-SHA256 signature
  String _getSignature(String salt, String timestamp) {
    final data = salt + timestamp;
    final key = utf8.encode(AppConfig.securityKey);
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return base64.encode(digest.bytes);
  }

  /// Build API URL (authentication not required for public endpoints)
  String _buildUrl(String action) {
    // WebTV Solutions API doesn't require authentication for public endpoints
    // The old app used static/hardcoded credentials
    return '${AppConfig.apiUrl}?$action';
  }

  /// Get all categories
  Future<List<Category>> getCategories() async {
    final url = _buildUrl('go=categories&do=list');

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'includeData': '1',
          'resultsPerPageFilter': '100',
          'current_page': '1',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['list'] != null) {
          return (data['list'] as List)
              .map((item) => Category.fromJson(item))
              .where((cat) => cat.status == '1') // Only active categories
              .toList();
        }
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
    return [];
  }

  /// Get videos for a category
  Future<List<Video>> getVideosByCategory(int categoryId, {int page = 1, int perPage = 20}) async {
    final url = _buildUrl('go=clips&do=list');

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'fields': '*',
          'resultsPerPageFilter': perPage.toString(),
          'current_page': page.toString(),
          'categoriesFilter': categoryId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['list'] != null) {
          return (data['list'] as List)
              .map((item) => Video.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      print('Error fetching videos: $e');
    }
    return [];
  }

  /// Get featured videos
  Future<List<Video>> getFeaturedVideos() async {
    final url = _buildUrl('go=clips&do=list');

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'fields': '*',
          'resultsPerPageFilter': '20',
          'statusFilter': 'featuredActiveAndApproved',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['list'] != null) {
          return (data['list'] as List)
              .map((item) => Video.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      print('Error fetching featured videos: $e');
    }
    return [];
  }

  /// Get single video details
  Future<Video?> getVideo(int videoId) async {
    final url = _buildUrl('go=clips&do=get&iq=$videoId');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final video = Video.fromJson(data['data']);
          // Get media URLs
          if (data['media'] != null && (data['media'] as List).isNotEmpty) {
            final media = data['media'][0];
            video.mediaUrl = media['live_ios'] ?? media['media_mbr_html5'] ?? media['embed_flash'];
          }
          return video;
        }
      }
    } catch (e) {
      print('Error fetching video: $e');
    }
    return null;
  }

  /// Search videos
  Future<List<Video>> searchVideos(String query) async {
    final url = _buildUrl('go=clips&do=list');

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'fields': '*',
          'resultsPerPageFilter': '50',
          'searchFilter': query,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['list'] != null) {
          return (data['list'] as List)
              .map((item) => Video.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      print('Error searching videos: $e');
    }
    return [];
  }

  /// Login user (for paid sites like fcplay.se)
  Future<bool> login(String email, String password) async {
    if (!AppConfig.requiresLogin) return true;

    final url = _buildUrl('go=users&do=log_in');

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['session_id'] != null) {
          _sessionId = data['session_id'];
          _currentUser = User.fromJson(data);
          return true;
        }
      }
    } catch (e) {
      print('Error logging in: $e');
    }
    return false;
  }

  /// Register user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final url = _buildUrl('go=users&do=create');

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error registering: $e');
    }
    return {'error': 'Registration failed'};
  }

  /// Logout
  Future<void> logout() async {
    if (_sessionId != null) {
      final url = _buildUrl('go=users&do=log_out&iq=$_sessionId');
      try {
        await http.get(Uri.parse(url));
      } catch (e) {
        print('Error logging out: $e');
      }
    }
    _sessionId = null;
    _currentUser = null;
  }

  /// Check subscription status (for paid sites)
  Future<bool> hasActiveSubscription() async {
    if (!AppConfig.isPaidSite) return true;
    if (_sessionId == null) return false;

    final url = _buildUrl('go=store&do=list_subscriptions');

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'session_id': _sessionId!,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Check if user has active subscription
        if (data['list'] != null && (data['list'] as List).isNotEmpty) {
          for (var sub in data['list']) {
            if (sub['status'] == 'active') {
              return true;
            }
          }
        }
      }
    } catch (e) {
      print('Error checking subscription: $e');
    }
    return false;
  }
}
