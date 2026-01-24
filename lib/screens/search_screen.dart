import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/webtv_api.dart';
import '../models/video.dart';
import 'video_player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final WebTVApi _api = WebTVApi();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Video> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final results = await _api.searchVideos(query.trim());

    setState(() {
      _results = results;
      _isLoading = false;
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search videos...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _results = [];
                        _hasSearched = false;
                      });
                    },
                  )
                : null,
          ),
          onSubmitted: _search,
          onChanged: (value) => setState(() {}),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(_searchController.text),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Search for videos',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final video = _results[index];
        return SearchResultCard(
          video: video,
          onTap: () => _openVideo(video),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class SearchResultCard extends StatelessWidget {
  final Video video;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: video.thumbnail,
                    width: 160,
                    height: 90,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 160,
                      height: 90,
                      color: Colors.grey[900],
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 160,
                      height: 90,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.durationFormatted,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (video.author.isNotEmpty)
                    Text(
                      video.author,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${video.formattedViews} • ${video.dateFormatted}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
