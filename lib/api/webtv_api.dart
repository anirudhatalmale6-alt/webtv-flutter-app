import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/category.dart';
import '../models/video.dart';
import '../models/user.dart';

class WebTVApi {
  static final WebTVApi _instance = WebTVApi._internal();
  factory WebTVApi() => _instance;

  late Dio _dio;

  WebTVApi._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'JKTV/2.0 Android',
      },
      // Important: follow redirects automatically
      followRedirects: true,
      maxRedirects: 5,
      // Validate status to include redirects
      validateStatus: (status) => status != null && status < 500,
    ));
  }

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

  /// Build API URL with authentication credentials
  /// The WebTV Solutions API requires these auth parameters
  String _buildUrl(String action) {
    // Using the same static credentials that worked in the old Android app
    // These are hardcoded in the old app's ReqConst.REQ_REQUIRED
    const timestamp = '1505628889855';
    const salt = '6273954f9c6ee2dba41fdcd6a84319fb';
    const key = 'db40ade832c4eaaa19c6c45c5bd0509b';
    const signature = 'DT7wO87nO41w9pjVoTH5JkBJ60JBNgqp0tOyDapNpgk=';

    return '${AppConfig.apiUrl}?$action'
        '&timestamp=$timestamp'
        '&salt=$salt'
        '&key=$key'
        '&signature=${Uri.encodeComponent(signature)}';
  }

  /// Parse response body - handles various edge cases
  dynamic _parseResponse(Response response) {
    var data = response.data;

    // If data is already parsed (dio can do this automatically)
    if (data is Map || data is List) {
      return data;
    }

    // If data is a string, try to parse it
    if (data is String) {
      var body = data.trim();

      // Try to find the start of JSON object/array
      final jsonStart = body.indexOf('{');
      final arrayStart = body.indexOf('[');

      int startIndex = -1;
      if (jsonStart >= 0 && (arrayStart < 0 || jsonStart < arrayStart)) {
        startIndex = jsonStart;
      } else if (arrayStart >= 0) {
        startIndex = arrayStart;
      }

      if (startIndex < 0) {
        throw Exception('No JSON found in response: ${body.substring(0, body.length.clamp(0, 100))}');
      }

      if (startIndex > 0) {
        print('Found JSON starting at index $startIndex, stripping prefix');
        body = body.substring(startIndex);
      }

      return json.decode(body);
    }

    throw Exception('Unexpected response type: ${data.runtimeType}');
  }

  /// Get all categories
  Future<List<Category>> getCategories() async {
    final url = _buildUrl('go=categories&do=list&includeData=1&resultsPerPageFilter=100&current_page=1');
    print('Fetching categories from: $url');

    try {
      final response = await _dio.get(url);

      print('Categories response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = _parseResponse(response);

        if (data['error'] != null) {
          print('API Error: ${data['error']} - ${data['error_long']}');
          throw Exception('API Error: ${data['error_long'] ?? data['error']}');
        }
        if (data['list'] != null) {
          final categoryList = data['list'] as List;
          print('Got ${categoryList.length} categories from list');

          // The list API doesn't return titles, so we need to fetch each category's details
          final categories = <Category>[];
          for (final item in categoryList) {
            final catId = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
            if (catId > 0 && item['status']?.toString() == '1') {
              // Fetch full category details to get the title
              final category = await _getCategoryDetails(catId);
              if (category != null) {
                categories.add(category);
              }
            }
          }

          print('Parsed ${categories.length} active categories with titles');
          return categories;
        }
        throw Exception('No categories in response');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Dio error: ${e.type} - ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout - please check your internet');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Server took too long to respond');
      } else if (e.response != null) {
        throw Exception('HTTP ${e.response?.statusCode}: ${e.message}');
      }
      throw Exception('Network error: ${e.message}');
    } on FormatException catch (e) {
      print('JSON parse error: $e');
      throw Exception('Failed to parse server response: $e');
    } catch (e, stackTrace) {
      print('Error fetching categories: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get single category details (to get title which list endpoint doesn't return)
  Future<Category?> _getCategoryDetails(int categoryId) async {
    final url = _buildUrl('go=categories&do=get&iq=$categoryId&fields=*');

    try {
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
        if (data['data'] != null) {
          return Category.fromJson(data['data']);
        }
      }
    } catch (e) {
      print('Error fetching category $categoryId: $e');
    }
    return null;
  }

  /// Get videos for a category
  Future<List<Video>> getVideosByCategory(int categoryId, {int page = 1, int perPage = 20}) async {
    final url = _buildUrl('go=clips&do=list&fields=*&resultsPerPageFilter=$perPage&current_page=$page&categoriesFilter=$categoryId');

    try {
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
        if (data['list'] != null) {
          return (data['list'] as List)
              .map((item) => Video.fromJson(item))
              .toList();
        }
      }
    } catch (e) {
      print('Error fetching videos for category $categoryId: $e');
    }
    return [];
  }

  /// Get featured videos
  Future<List<Video>> getFeaturedVideos() async {
    final url = _buildUrl('go=clips&do=list&fields=*&resultsPerPageFilter=20&statusFilter=featuredActiveAndApproved');

    try {
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
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
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
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
    final encodedQuery = Uri.encodeComponent(query);
    final url = _buildUrl('go=clips&do=list&fields=*&resultsPerPageFilter=50&searchFilter=$encodedQuery');

    try {
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
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
      final response = await _dio.post(
        url,
        data: {
          'email': email,
          'password': password,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
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
      final response = await _dio.post(
        url,
        data: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        return _parseResponse(response);
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
        await _dio.get(url);
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
      final response = await _dio.post(
        url,
        data: {
          'session_id': _sessionId!,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
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
