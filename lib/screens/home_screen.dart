import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../api/webtv_api.dart';
import '../models/category.dart';
import '../models/video.dart';
import '../widgets/video_row.dart';
import '../widgets/featured_carousel.dart';
import 'search_screen.dart';
import 'video_player_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WebTVApi _api = WebTVApi();
  final ScrollController _scrollController = ScrollController();

  List<Category> _categories = [];
  Map<int, List<Video>> _videosByCategory = {};
  List<Video> _featuredVideos = [];
  bool _isLoading = true;
  bool _isAppBarTransparent = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final isTransparent = _scrollController.offset < 100;
    if (isTransparent != _isAppBarTransparent) {
      setState(() {
        _isAppBarTransparent = isTransparent;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Loading categories...');
      // Load categories first
      final categories = await _api.getCategories();
      print('Got ${categories.length} categories');

      if (categories.isEmpty) {
        setState(() {
          _errorMessage = 'No categories found. Please check your connection.';
          _isLoading = false;
        });
        return;
      }

      // Load featured videos
      print('Loading featured videos...');
      final featured = await _api.getFeaturedVideos();
      print('Got ${featured.length} featured videos');

      // Load videos for each category (limit to first 10 categories for speed)
      final videosByCategory = <int, List<Video>>{};
      final categoriesToLoad = categories.take(10).toList();

      for (final category in categoriesToLoad) {
        print('Loading videos for category: ${category.title}');
        final videos = await _api.getVideosByCategory(category.id);
        print('Got ${videos.length} videos');
        if (videos.isNotEmpty) {
          videosByCategory[category.id] = videos;
        }
      }

      setState(() {
        _featuredVideos = featured;
        _categories = categories.where((c) => videosByCategory.containsKey(c.id)).toList();
        _videosByCategory = videosByCategory;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading data: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to load content: $e';
        _isLoading = false;
      });
    }
  }

  void _openVideo(Video video) async {
    // Get full video details with media URL
    final fullVideo = await _api.getVideo(video.id);
    if (fullVideo != null && fullVideo.mediaUrl != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(video: fullVideo),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load video')),
      );
    }
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
  }

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildMenu(),
    );
  }

  Widget _buildMenu() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.white),
            title: const Text('Home', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.live_tv, color: Colors.red),
            title: const Text('Live', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to live stream
            },
          ),
          ListTile(
            leading: const Icon(Icons.search, color: Colors.white),
            title: const Text('Search', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _openSearch();
            },
          ),
          if (AppConfig.showLoginButton) ...[
            const Divider(color: Colors.white24),
            ListTile(
              leading: Icon(
                _api.isLoggedIn ? Icons.logout : Icons.login,
                color: Colors.white,
              ),
              title: Text(
                _api.isLoggedIn ? 'Logout' : 'Login',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                if (_api.isLoggedIn) {
                  _api.logout();
                  setState(() {});
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white),
            title: const Text('About', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(AppConfig.appName),
        content: Text(AppConfig.appTagline),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: _isAppBarTransparent
            ? Colors.transparent
            : Colors.black.withOpacity(0.9),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Color(AppConfig.primaryColorValue),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                AppConfig.appName.substring(0, 2).toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          AppConfig.appName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _openMenu,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Featured carousel
                  if (_featuredVideos.isNotEmpty)
                    SliverToBoxAdapter(
                      child: FeaturedCarousel(
                        videos: _featuredVideos,
                        onVideoTap: _openVideo,
                      ),
                    ),

                  // Category rows
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = _categories[index];
                        final videos = _videosByCategory[category.id] ?? [];
                        if (videos.isEmpty) return const SizedBox.shrink();

                        return VideoRow(
                          title: category.title,
                          videos: videos,
                          onVideoTap: _openVideo,
                        );
                      },
                      childCount: _categories.length,
                    ),
                  ),

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 32),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
