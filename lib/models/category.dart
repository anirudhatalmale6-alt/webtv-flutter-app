class Category {
  final int id;
  final String title;
  final String titleUrl;
  final String? description;
  final String thumbnail;
  final String poster;
  final String status;
  final int viewsPage;

  Category({
    required this.id,
    required this.title,
    required this.titleUrl,
    this.description,
    required this.thumbnail,
    required this.poster,
    required this.status,
    required this.viewsPage,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      titleUrl: json['title_url'] ?? '',
      description: json['description'],
      thumbnail: json['img_thumbnail'] ?? '',
      poster: json['img_poster'] ?? '',
      status: json['status']?.toString() ?? '0',
      viewsPage: int.tryParse(json['views_page']?.toString() ?? '0') ?? 0,
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
      'status': status,
      'views_page': viewsPage,
    };
  }
}
