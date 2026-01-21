class Video {
  final int id;
  final String title;
  final String titleUrl;
  final String description;
  final String thumbnail;
  final String poster;
  final String duration;
  final String durationFormatted;
  final int views;
  final int likes;
  final String date;
  final String dateFormatted;
  final String author;
  final int categoryId;
  String? mediaUrl;
  final bool isLive;
  final String videoType; // 'youtube', 'vimeo', 'direct', 'embed'
  final String? youtubeId;
  final String? vimeoId;
  final String? embedUrl;

  Video({
    required this.id,
    required this.title,
    required this.titleUrl,
    required this.description,
    required this.thumbnail,
    required this.poster,
    required this.duration,
    required this.durationFormatted,
    required this.views,
    required this.likes,
    required this.date,
    required this.dateFormatted,
    required this.author,
    required this.categoryId,
    this.mediaUrl,
    this.isLive = false,
    this.videoType = 'direct',
    this.youtubeId,
    this.vimeoId,
    this.embedUrl,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    final titleUrl = json['title_url']?.toString() ?? '';

    // Determine video type and extract URLs
    String videoType = 'direct';
    String? youtubeId;
    String? vimeoId;
    String? embedUrl;
    String? mediaUrl;

    // Check for direct stream URLs first
    final liveIos = json['live_ios']?.toString() ?? '';
    final mediaMbrHtml5 = json['media_mbr_html5']?.toString() ?? '';
    final vodHtml5H264 = json['vod_html5_h264']?.toString() ?? '';

    if (liveIos.isNotEmpty && liveIos != 'null') {
      mediaUrl = liveIos;
      videoType = 'direct';
    } else if (mediaMbrHtml5.isNotEmpty && mediaMbrHtml5 != 'null') {
      mediaUrl = mediaMbrHtml5;
      videoType = 'direct';
    } else if (vodHtml5H264.isNotEmpty && vodHtml5H264 != 'null') {
      mediaUrl = vodHtml5H264;
      videoType = 'direct';
    } else {
      // Check for embed URLs (YouTube, etc.)
      final embedFlash = json['embed_flash']?.toString() ?? '';
      final embedHtml5 = json['embed_html5']?.toString() ?? '';
      embedUrl = embedHtml5.isNotEmpty ? embedHtml5 : embedFlash;

      if (embedUrl.isNotEmpty && embedUrl != 'null') {
        youtubeId = _extractYouTubeId(embedUrl);
        if (youtubeId != null) {
          videoType = 'youtube';
        } else {
          vimeoId = _extractVimeoId(embedUrl);
          if (vimeoId != null) {
            videoType = 'vimeo';
          } else {
            videoType = 'embed';
          }
        }
      }
    }

    // Also check id_import for YouTube/Vimeo ID
    final idImport = json['id_import']?.toString() ?? '';
    if (idImport.startsWith('yt_') && youtubeId == null) {
      youtubeId = idImport.substring(3);
      videoType = 'youtube';
    } else if (idImport.startsWith('vim_') && vimeoId == null) {
      vimeoId = idImport.substring(4);
      videoType = 'vimeo';
    }

    return Video(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      titleUrl: titleUrl,
      description: _stripHtml(json['description']?.toString() ?? ''),
      thumbnail: json['img_thumbnail']?.toString() ?? '',
      poster: json['img_poster']?.toString() ?? json['img_thumbnail']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '0',
      durationFormatted: json['duration_formatted']?.toString() ?? '',
      views: int.tryParse(json['views']?.toString() ?? '0') ?? 0,
      likes: int.tryParse(json['likes']?.toString() ?? '0') ?? 0,
      date: json['date']?.toString() ?? '',
      dateFormatted: json['date_formatted']?.toString() ?? '',
      author: json['user_alias']?.toString() ?? '',
      categoryId: int.tryParse(json['id_category']?.toString() ?? '0') ?? 0,
      mediaUrl: mediaUrl,
      isLive: titleUrl.toLowerCase().contains('live'),
      videoType: videoType,
      youtubeId: youtubeId,
      vimeoId: vimeoId,
      embedUrl: embedUrl,
    );
  }

  /// Extract YouTube video ID from various URL formats
  static String? _extractYouTubeId(String url) {
    // Handle various YouTube URL formats
    final patterns = [
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/v/([a-zA-Z0-9_-]{11})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Extract Vimeo video ID from various URL formats
  static String? _extractVimeoId(String url) {
    // Handle various Vimeo URL formats
    final patterns = [
      RegExp(r'vimeo\.com/(\d+)'),
      RegExp(r'vimeo\.com/video/(\d+)'),
      RegExp(r'player\.vimeo\.com/video/(\d+)'),
      RegExp(r'vimeo\.com/channels/[^/]+/(\d+)'),
      RegExp(r'vimeo\.com/groups/[^/]+/videos/(\d+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_url': titleUrl,
      'description': description,
      'img_thumbnail': thumbnail,
      'img_poster': poster,
      'duration': duration,
      'duration_formatted': durationFormatted,
      'views': views,
      'likes': likes,
      'date': date,
      'date_formatted': dateFormatted,
      'user_alias': author,
      'id_category': categoryId,
    };
  }

  /// Strip HTML tags from description
  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }

  /// Format view count
  String get formattedViews {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M views';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K views';
    }
    return '$views views';
  }
}
