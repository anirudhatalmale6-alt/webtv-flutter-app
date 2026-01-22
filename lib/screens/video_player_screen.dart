import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/video.dart';
import '../config/app_config.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Video video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  // For direct video playback
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // For WebView embedded videos
  WebViewController? _webViewController;

  bool _isLoading = true;
  String? _error;
  bool _isEmbedded = false; // YouTube or Vimeo embedded
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      print('Video type: ${widget.video.videoType}');
      print('YouTube ID: ${widget.video.youtubeId}');
      print('Vimeo ID: ${widget.video.vimeoId}');
      print('Media URL: ${widget.video.mediaUrl}');
      print('Embed URL: ${widget.video.embedUrl}');

      if (widget.video.videoType == 'youtube' && widget.video.youtubeId != null) {
        // For YouTube videos, embed using WebView
        _initializeYouTubeEmbed(widget.video.youtubeId!);
      } else if (widget.video.videoType == 'vimeo' && widget.video.vimeoId != null) {
        // For Vimeo videos, embed using WebView
        _initializeVimeoEmbed(widget.video.vimeoId!);
      } else if (widget.video.embedUrl != null && widget.video.embedUrl!.isNotEmpty) {
        // Try to extract YouTube/Vimeo ID from embed URL
        final youtubeId = _extractYouTubeId(widget.video.embedUrl!);
        if (youtubeId != null) {
          _initializeYouTubeEmbed(youtubeId);
        } else {
          final vimeoId = _extractVimeoId(widget.video.embedUrl!);
          if (vimeoId != null) {
            _initializeVimeoEmbed(vimeoId);
          } else {
            // Generic embed URL
            _initializeGenericEmbed(widget.video.embedUrl!);
          }
        }
      } else if (widget.video.mediaUrl != null && widget.video.mediaUrl!.isNotEmpty) {
        // Initialize native video player for direct URLs
        await _initializeNativePlayer(widget.video.mediaUrl!);
      } else {
        setState(() {
          _error = 'No video URL available';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing player: $e');
      setState(() {
        _error = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeYouTubeEmbed(String youtubeId) {
    print('Initializing YouTube embed for ID: $youtubeId');

    // YouTube embed HTML with no branding, autoplay, and controls
    final html = '''
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
          src="https://www.youtube.com/embed/$youtubeId?autoplay=1&playsinline=1&rel=0&modestbranding=1&showinfo=0&controls=1&fs=1"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen"
          allowfullscreen>
        </iframe>
      </div>
    </body>
    </html>
    ''';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString(html);

    setState(() {
      _isEmbedded = true;
      _isLoading = false;
    });
  }

  void _initializeVimeoEmbed(String vimeoId) {
    print('Initializing Vimeo embed for ID: $vimeoId');

    // Vimeo embed HTML with no branding
    final html = '''
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
          src="https://player.vimeo.com/video/$vimeoId?autoplay=1&title=0&byline=0&portrait=0&badge=0"
          allow="autoplay; fullscreen; picture-in-picture"
          allowfullscreen>
        </iframe>
      </div>
    </body>
    </html>
    ''';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString(html);

    setState(() {
      _isEmbedded = true;
      _isLoading = false;
    });
  }

  void _initializeGenericEmbed(String embedUrl) {
    print('Initializing generic embed for URL: $embedUrl');

    final html = '''
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
          src="$embedUrl"
          allow="autoplay; fullscreen; picture-in-picture"
          allowfullscreen>
        </iframe>
      </div>
    </body>
    </html>
    ''';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString(html);

    setState(() {
      _isEmbedded = true;
      _isLoading = false;
    });
  }

  String? _extractYouTubeId(String url) {
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
      String actualUrl = videoUrl;

      _videoController = VideoPlayerController.networkUrl(Uri.parse(actualUrl));

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
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing native player: $e');
      setState(() {
        _error = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleFullscreen,
          child: _buildVideoPlayer(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: _toggleFullscreen,
            tooltip: 'Fullscreen',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorView();
    }

    return Column(
      children: [
        // Video player
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildVideoPlayer(),
        ),

        // Video info
        Expanded(
          child: _buildVideoInfo(),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    if (_isEmbedded && _webViewController != null) {
      return WebViewWidget(controller: _webViewController!);
    }

    if (_chewieController != null) {
      return Chewie(controller: _chewieController!);
    }

    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
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
            Text(
              _error!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.video.dateFormatted.isNotEmpty) ...[
                const Icon(Icons.calendar_today,
                    size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  widget.video.dateFormatted,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              const Icon(Icons.visibility, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                widget.video.formattedViews,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              if (widget.video.likes > 0) ...[
                const SizedBox(width: 16),
                const Icon(Icons.thumb_up, size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  '${widget.video.likes}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ],
          ),
          if (widget.video.author.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.white54),
                const SizedBox(width: 8),
                Text(
                  widget.video.author,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
          if (widget.video.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              widget.video.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    // Reset orientation when leaving player
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
