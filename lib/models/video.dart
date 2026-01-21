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
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    final titleUrl = json['title_url']?.toString() ?? '';
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
      mediaUrl: json['live_ios']?.toString() ?? json['media_mbr_html5']?.toString() ?? json['embed_flash']?.toString(),
      isLive: titleUrl.toLowerCase().contains('live'),
    );
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
