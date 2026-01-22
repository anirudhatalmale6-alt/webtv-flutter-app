import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video.dart';
import '../api/webtv_api.dart';

class BrowseVideosSection extends StatefulWidget {
  final Function(Video) onVideoTap;

  const BrowseVideosSection({
    super.key,
    required this.onVideoTap,
  });

  @override
  State<BrowseVideosSection> createState() => _BrowseVideosSectionState();
}

class _BrowseVideosSectionState extends State<BrowseVideosSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WebTVApi _api = WebTVApi();

  List<Video> _featuredVideos = [];
  List<Video> _byDateVideos = [];
  List<Video> _mostViewedVideos = [];
  List<Video> _topRatedVideos = [];

  bool _isLoading = true;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTabIndex = _tabController.index);
        _loadTabData(_tabController.index);
      }
    });
    _loadTabData(0);
  }

  Future<void> _loadTabData(int index) async {
    // Only load if data is empty
    switch (index) {
      case 0:
        if (_featuredVideos.isEmpty) {
          setState(() => _isLoading = true);
          _featuredVideos = await _api.getFeaturedVideos(limit: 40);
          setState(() => _isLoading = false);
        }
        break;
      case 1:
        if (_byDateVideos.isEmpty) {
          setState(() => _isLoading = true);
          _byDateVideos = await _api.getVideosByDate(limit: 40);
          setState(() => _isLoading = false);
        }
        break;
      case 2:
        if (_mostViewedVideos.isEmpty) {
          setState(() => _isLoading = true);
          _mostViewedVideos = await _api.getMostViewedVideos(limit: 40);
          setState(() => _isLoading = false);
        }
        break;
      case 3:
        if (_topRatedVideos.isEmpty) {
          setState(() => _isLoading = true);
          _topRatedVideos = await _api.getTopRatedVideos(limit: 40);
          setState(() => _isLoading = false);
        }
        break;
    }
  }

  List<Video> get _currentVideos {
    switch (_currentTabIndex) {
      case 0:
        return _featuredVideos;
      case 1:
        return _byDateVideos;
      case 2:
        return _mostViewedVideos;
      case 3:
        return _topRatedVideos;
      default:
        return [];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Browse Videos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        // Tabs
        Container(
          color: Colors.black.withOpacity(0.3),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.blue,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Featured'),
              Tab(text: 'By Date'),
              Tab(text: 'Most Viewed'),
              Tab(text: 'Top Rated'),
            ],
          ),
        ),
        // Videos grid
        if (_isLoading)
          const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_currentVideos.isEmpty)
          const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'No videos found',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          )
        else
          SizedBox(
            height: 400,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: _currentVideos.length,
              itemBuilder: (context, index) {
                final video = _currentVideos[index];
                return _VideoGridCard(
                  video: video,
                  onTap: () => widget.onVideoTap(video),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _VideoGridCard extends StatelessWidget {
  final Video video;
  final VoidCallback onTap;

  const _VideoGridCard({
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        print('BrowseGridCard tapped: ${video.id} - ${video.title}');
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: CachedNetworkImage(
                      imageUrl: video.thumbnail,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.error, color: Colors.white54),
                      ),
                    ),
                  ),
                  // Duration badge
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
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  // Play icon overlay
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Title
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      video.formattedViews,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
