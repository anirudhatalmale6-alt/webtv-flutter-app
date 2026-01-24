import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/webtv_api.dart';
import '../models/video.dart';
import '../config/app_config.dart';
import 'video_player_screen.dart';

class CategoryVideosScreen extends StatefulWidget {
  final int categoryId;
  final String categoryTitle;

  const CategoryVideosScreen({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
  });

  @override
  State<CategoryVideosScreen> createState() => _CategoryVideosScreenState();
}

class _CategoryVideosScreenState extends State<CategoryVideosScreen> {
  final WebTVApi _api = WebTVApi();
  final ScrollController _scrollController = ScrollController();

  List<Video> _videos = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _perPage = 20;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    });

    final videos = await _api.getVideosByCategory(
      widget.categoryId,
      page: 1,
      perPage: _perPage,
    );

    setState(() {
      _videos = videos;
      _isLoading = false;
      _hasMore = videos.length >= _perPage;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final nextPage = _currentPage + 1;
    final videos = await _api.getVideosByCategory(
      widget.categoryId,
      page: nextPage,
      perPage: _perPage,
    );

    setState(() {
      _currentPage = nextPage;
      _videos.addAll(videos);
      _isLoadingMore = false;
      _hasMore = videos.length >= _perPage;
    });
  }

  void _openVideo(Video video) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final fullVideo = await _api.getVideo(video.id);
      if (mounted) Navigator.of(context).pop();

      if (fullVideo != null) {
        final canPlay = fullVideo.mediaUrl != null ||
            fullVideo.youtubeId != null ||
            fullVideo.vimeoId != null ||
            fullVideo.embedUrl != null;
        if (canPlay) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(video: fullVideo),
            ),
          );
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load video')),
      );
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.categoryTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
              ? const Center(
                  child: Text(
                    'No videos found',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadVideos,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _videos.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _videos.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return _buildVideoGridItem(_videos[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildVideoGridItem(Video video) {
    return GestureDetector(
      onTap: () => _openVideo(video),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: video.thumbnail,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.error, color: Colors.white54),
                    ),
                  ),
                ),
                if (video.durationFormatted.isNotEmpty)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.durationFormatted,
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          // Views
          Text(
            video.formattedViews,
            style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
