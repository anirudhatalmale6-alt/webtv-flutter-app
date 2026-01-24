import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/video.dart';
import '../config/app_config.dart';

// Social share
class SocialShare {
  static String _shareText(String url, String title) {
    return '$title - Watch on JKTV Live app\n$url';
  }

  static Future<void> shareGeneral(String url, String title) async {
    await Share.share(_shareText(url, title));
  }

  static Future<void> shareToWhatsApp(String url, String title) async {
    final text = _shareText(url, title);
    final shareUrl = 'https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}';
    await _launchUrl(shareUrl);
  }

  static Future<void> shareToTelegram(String url, String title) async {
    final text = _shareText(url, title);
    final shareUrl = 'https://t.me/share/url?url=${Uri.encodeComponent(url)}&text=${Uri.encodeComponent('$title - Watch on JKTV Live app')}';
    await _launchUrl(shareUrl);
  }

  static Future<void> copyLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')),
      );
    }
  }

  static Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching URL: $e');
    }
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final Video video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  InAppWebViewController? _webViewController;

  bool _isLoading = true;
  bool _showSplash = true;
  String? _error;
  String _playerType = 'none'; // 'youtube', 'vimeo', 'native'
  bool _isFullscreen = false;

  late AnimationController _splashAnimController;
  late Animation<double> _splashFadeAnimation;

  // InAppWebView settings for YouTube/Vimeo
  final InAppWebViewSettings _webViewSettings = InAppWebViewSettings(
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllowFullscreen: true,
    javaScriptEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    useWideViewPort: true,
    loadWithOverviewMode: true,
    supportMultipleWindows: false,
    javaScriptCanOpenWindowsAutomatically: false,
    userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  );

  @override
  void initState() {
    super.initState();

    _splashAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _splashFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _splashAnimController, curve: Curves.easeOut),
    );
    _splashAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showSplash = false);
      }
    });

    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (widget.video.videoType == 'youtube' && widget.video.youtubeId != null) {
        _setupWebViewPlayer('youtube', widget.video.youtubeId!);
      } else if (widget.video.videoType == 'vimeo' && widget.video.vimeoId != null) {
        _setupWebViewPlayer('vimeo', widget.video.vimeoId!);
      } else if (widget.video.embedUrl != null && widget.video.embedUrl!.isNotEmpty) {
        final youtubeId = _extractYouTubeIdFromUrl(widget.video.embedUrl!);
        if (youtubeId != null) {
          _setupWebViewPlayer('youtube', youtubeId);
        } else {
          final vimeoId = _extractVimeoId(widget.video.embedUrl!);
          if (vimeoId != null) {
            _setupWebViewPlayer('vimeo', vimeoId);
          } else {
            setState(() {
              _error = 'Unsupported video format';
              _isLoading = false;
            });
          }
        }
      } else if (widget.video.mediaUrl != null && widget.video.mediaUrl!.isNotEmpty) {
        await _initializeNativePlayer(widget.video.mediaUrl!);
      } else {
        setState(() {
          _error = 'No video URL available';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }

  void _setupWebViewPlayer(String type, String videoId) {
    if (videoId.isEmpty) {
      setState(() {
        _error = 'Invalid video ID';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _playerType = type;
      _isLoading = false;
    });

    // Hide splash after 2 seconds (video should start loading by then)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _splashAnimController.forward();
    });
  }

  String _getYouTubeEmbedHtml(String videoId) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
    .video-container { position: relative; width: 100%; height: 100%; }
    iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: none; }
  </style>
</head>
<body>
  <div class="video-container">
    <iframe
      src="https://www.youtube.com/embed/$videoId?autoplay=1&playsinline=1&rel=0&modestbranding=1&fs=1&enablejsapi=1"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
      allowfullscreen
      frameborder="0">
    </iframe>
  </div>
</body>
</html>
''';
  }

  String _getVimeoEmbedHtml(String videoId) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
    .video-container { position: relative; width: 100%; height: 100%; }
    iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: none; }
  </style>
</head>
<body>
  <div class="video-container">
    <iframe
      src="https://player.vimeo.com/video/$videoId?autoplay=1&playsinline=1&title=0&byline=0&portrait=0"
      allow="autoplay; fullscreen; picture-in-picture"
      allowfullscreen>
    </iframe>
  </div>
</body>
</html>
''';
  }

  String? _extractYouTubeIdFromUrl(String url) {
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

  String? _extractVimeoId(String url) {
    final patterns = [
      RegExp(r'vimeo\.com/(\d+)'),
      RegExp(r'vimeo\.com/video/(\d+)'),
      RegExp(r'player\.vimeo\.com/video/(\d+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  Future<void> _initializeNativePlayer(String videoUrl) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: widget.video.isLive,
        aspectRatio: _videoController!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Color(AppConfig.primaryColorValue),
          handleColor: Color(AppConfig.primaryColorValue),
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white24,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(errorMessage, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              ],
            ),
          );
        },
      );

      setState(() {
        _playerType = 'native';
        _isLoading = false;
      });

      // Hide splash after 1 second for native player (already buffered)
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _splashAnimController.forward();
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreen ? null : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.video.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorView();
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              _buildVideoPlayer(),
              if (_showSplash) _buildSplashOverlay(),
            ],
          ),
        ),
        if (!_isFullscreen)
          Expanded(child: _buildVideoInfo()),
      ],
    );
  }

  Widget _buildSplashOverlay() {
    return AnimatedBuilder(
      animation: _splashFadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _splashFadeAnimation.value.clamp(0.0, 1.0),
          child: Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'JKTV Live',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '24/7 The Voice of Voiceless',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(AppConfig.primaryColorValue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    if ((_playerType == 'youtube' || _playerType == 'vimeo') && !_isLoading) {
      final videoId = _playerType == 'youtube'
          ? (widget.video.youtubeId ?? _extractYouTubeIdFromUrl(widget.video.embedUrl ?? '') ?? '')
          : (widget.video.vimeoId ?? _extractVimeoId(widget.video.embedUrl ?? '') ?? '');

      final htmlContent = _playerType == 'youtube'
          ? _getYouTubeEmbedHtml(videoId)
          : _getVimeoEmbedHtml(videoId);

      return InAppWebView(
        initialData: InAppWebViewInitialData(
          data: htmlContent,
          mimeType: 'text/html',
          encoding: 'utf-8',
          baseUrl: WebUri('https://jammukashmir.tv'),
        ),
        initialSettings: _webViewSettings,
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final url = navigationAction.request.url?.toString() ?? '';
          // Block any navigation away from the embed (prevents opening YouTube app)
          if (url.startsWith('intent://') ||
              url.startsWith('vnd.youtube:') ||
              url.startsWith('youtube:') ||
              url.contains('youtube.com/redirect') ||
              url.contains('accounts.google.com')) {
            return NavigationActionPolicy.CANCEL;
          }
          // Allow YouTube and Vimeo embed URLs
          if (url.contains('youtube.com') || url.contains('vimeo.com') || url.contains('googlevideo.com')) {
            return NavigationActionPolicy.ALLOW;
          }
          return NavigationActionPolicy.CANCEL;
        },
      );
    }

    if (_playerType == 'native' && _chewieController != null) {
      return Chewie(controller: _chewieController!);
    }

    return Container(
      color: Colors.black,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initializePlayer();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoInfo() {
    final videoUrl = 'https://jammukashmir.tv/index.php/video/${widget.video.id}/${widget.video.titleUrl}/';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.video.dateFormatted.isNotEmpty) ...[
                const Icon(Icons.calendar_today, size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text(widget.video.dateFormatted, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                const SizedBox(width: 16),
              ],
              const Icon(Icons.visibility, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Text(widget.video.formattedViews, style: const TextStyle(fontSize: 12, color: Colors.white54)),
              if (widget.video.likes > 0) ...[
                const SizedBox(width: 16),
                const Icon(Icons.thumb_up, size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text('${widget.video.likes}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ],
          ),
          if (widget.video.author.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.white54),
                const SizedBox(width: 8),
                Text(widget.video.author, style: const TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          const Text('Share', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildShareButton(
                icon: Icons.share,
                color: Color(AppConfig.primaryColorValue),
                label: 'Share',
                onTap: () => SocialShare.shareGeneral(videoUrl, widget.video.title),
              ),
              const SizedBox(width: 12),
              _buildShareButton(
                icon: Icons.message,
                color: const Color(0xFF25D366),
                label: 'WhatsApp',
                onTap: () => SocialShare.shareToWhatsApp(videoUrl, widget.video.title),
              ),
              const SizedBox(width: 12),
              _buildShareButton(
                icon: Icons.send,
                color: const Color(0xFF0088CC),
                label: 'Telegram',
                onTap: () => SocialShare.shareToTelegram(videoUrl, widget.video.title),
              ),
              const SizedBox(width: 12),
              _buildShareButton(
                icon: Icons.link,
                color: Colors.grey,
                label: 'Copy',
                onTap: () => SocialShare.copyLink(context, videoUrl),
              ),
            ],
          ),
          if (widget.video.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            Text(widget.video.description, style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _splashAnimController.dispose();
    _chewieController?.dispose();
    _videoController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
