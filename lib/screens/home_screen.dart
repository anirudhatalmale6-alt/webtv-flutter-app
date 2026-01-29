import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../api/webtv_api.dart';
import '../models/category.dart';
import '../models/video.dart';
import '../widgets/video_row.dart';
import '../widgets/featured_carousel.dart';
import '../widgets/browse_videos_section.dart';
import 'search_screen.dart';
import 'video_player_screen.dart';
import 'login_screen.dart';
import 'live_tv_screen.dart';
import 'webview_screen.dart';
import 'introduction_screen.dart';
import 'who_we_are_screen.dart';
import 'contact_screen.dart';
import 'advertise_screen.dart';
import 'support_screen.dart';
import 'category_videos_screen.dart';
import 'mission_screen.dart';

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
      List<Category> categories = [];
      try {
        categories = await _api.getCategories();
        print('Got ${categories.length} categories');
      } catch (e) {
        print('Categories error: $e');
        setState(() {
          _errorMessage = 'Failed to load categories: $e';
          _isLoading = false;
        });
        return;
      }

      if (categories.isEmpty) {
        setState(() {
          _errorMessage = 'No categories found. The API may be down or your connection blocked.';
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
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      print('Opening video: ${video.id} - ${video.title}');
      // Get full video details with media URL
      final fullVideo = await _api.getVideo(video.id);

      // Hide loading indicator
      if (mounted) Navigator.of(context).pop();

      if (fullVideo != null) {
        print('Got video: youtubeId=${fullVideo.youtubeId}, vimeoId=${fullVideo.vimeoId}, mediaUrl=${fullVideo.mediaUrl}, embedUrl=${fullVideo.embedUrl}');
        // Check if we can play this video (has mediaUrl, youtubeId, vimeoId, or embedUrl)
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
        } else {
          print('Video not playable - no media URLs found');
        }
      } else {
        print('Failed to get video details');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load video')),
      );
    } catch (e) {
      print('Error opening video: $e');
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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

  void _openLiveTV() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LiveTVScreen()),
    );
  }

  void _openContact() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ContactScreen()),
    );
  }

  void _openSupportUs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupportScreen()),
    );
  }

  void _openWebsite(String path, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          title: title,
          url: 'https://jammukashmir.tv$path',
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return SafeArea(
      child: SingleChildScrollView(
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
            // Main menu items
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: const Text('Home', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.live_tv, color: Colors.red),
              title: const Text('JKTV Live', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Watch Live TV', style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _openLiveTV();
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
            const Divider(color: Colors.white24),
            // Website links
            ListTile(
              leading: const Icon(Icons.article, color: Colors.white),
              title: const Text('News', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _openWebsite('/index.php/category/11/news-update/', 'News');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.white),
              title: const Text('About Us', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IntroductionScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.white),
              title: const Text('Who We Are', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WhoWeAreScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.white),
              title: const Text('Mission Statement', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MissionScreen()),
                );
              },
            ),
            const Divider(color: Colors.white24),
            // Contact & Support
            ListTile(
              leading: const Icon(Icons.email, color: Colors.white),
              title: const Text('Contact Us', style: TextStyle(color: Colors.white)),
              subtitle: const Text('contact@jktv.live', style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _openContact();
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text('Support Us', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _openSupportUs();
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign, color: Colors.orange),
              title: const Text('Advertise With Us', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdvertiseScreen()),
                );
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
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text('About', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),
            // Version info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Version ${AppConfig.appVersion}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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

  Widget _buildFocusableButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isFocused = false;
        return Focus(
          onFocusChange: (focused) {
            setState(() => isFocused = focused);
          },
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.gameButtonA) {
                onPressed();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isFocused ? Colors.white.withOpacity(0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isFocused ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: IconButton(
              icon: Icon(icon, color: isFocused ? Colors.white : null),
              onPressed: onPressed,
              tooltip: tooltip,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
      },
      child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: _isAppBarTransparent
            ? Colors.transparent
            : Colors.black.withOpacity(0.9),
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: const Text(
          'JKTV Live',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          _buildFocusableButton(
            icon: Icons.search,
            onPressed: _openSearch,
            tooltip: 'Search',
          ),
          _buildFocusableButton(
            icon: Icons.menu,
            onPressed: _openMenu,
            tooltip: 'Menu',
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
              : (_categories.isEmpty && _featuredVideos.isEmpty)
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.video_library_outlined, size: 64, color: Colors.white54),
                            const SizedBox(height: 16),
                            const Text(
                              'No content available',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pull down to refresh or tap retry',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white38),
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

                  // Browse Videos section (Featured, By Date, Most Viewed, Top Rated)
                  SliverToBoxAdapter(
                    child: BrowseVideosSection(
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
                          onSeeAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryVideosScreen(
                                  categoryId: category.id,
                                  categoryTitle: category.title,
                                ),
                              ),
                            );
                          },
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
