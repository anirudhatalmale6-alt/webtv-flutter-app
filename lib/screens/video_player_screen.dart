import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';
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

  bool _isLoading = true;
  String? _error;
  bool _isYouTube = false;
  bool _isVimeo = false;

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
        // For YouTube videos, show a play button that opens in YouTube app
        setState(() {
          _isYouTube = true;
          _isLoading = false;
        });
      } else if (widget.video.videoType == 'vimeo') {
        // For Vimeo videos, show a play button that opens in Vimeo app
        setState(() {
          _isVimeo = true;
          _isLoading = false;
        });
      } else if (widget.video.mediaUrl != null && widget.video.mediaUrl!.isNotEmpty) {
        // Initialize native video player for direct URLs
        await _initializeNativePlayer(widget.video.mediaUrl!);
      } else if (widget.video.embedUrl != null && widget.video.embedUrl!.isNotEmpty) {
        // Try to extract YouTube/Vimeo ID from embed URL as fallback
        final youtubeId = _extractYouTubeId(widget.video.embedUrl!);
        if (youtubeId != null) {
          setState(() {
            _isYouTube = true;
            _isLoading = false;
          });
        } else {
          final vimeoId = _extractVimeoId(widget.video.embedUrl!);
          if (vimeoId != null) {
            setState(() {
              _isVimeo = true;
              _isLoading = false;
            });
          } else {
            setState(() {
              _error = 'No playable video URL available';
              _isLoading = false;
            });
          }
        }
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

  String? _getYouTubeId() {
    if (widget.video.youtubeId != null) {
      return widget.video.youtubeId;
    }
    if (widget.video.embedUrl != null) {
      return _extractYouTubeId(widget.video.embedUrl!);
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

  String? _getVimeoId() {
    if (widget.video.vimeoId != null) {
      return widget.video.vimeoId;
    }
    if (widget.video.embedUrl != null) {
      return _extractVimeoId(widget.video.embedUrl!);
    }
    return null;
  }

  void _openInVimeoApp() async {
    final vimeoId = _getVimeoId();
    if (vimeoId != null) {
      // Try Vimeo app first, then fall back to browser
      final vimeoAppUrl = 'vimeo://app.vimeo.com/videos/$vimeoId';
      final vimeoWebUrl = 'https://vimeo.com/$vimeoId';

      try {
        // Try to open in Vimeo app
        final appUri = Uri.parse(vimeoAppUrl);
        if (await canLaunchUrl(appUri)) {
          await launchUrl(appUri);
          return;
        }
      } catch (e) {
        print('Could not open Vimeo app: $e');
      }

      // Fall back to browser
      final webUri = Uri.parse(vimeoWebUrl);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _initializeNativePlayer(String videoUrl) async {
    try {
      String actualUrl = videoUrl;

      // Note: Vimeo videos are now handled via _isVimeo flag and open in Vimeo app
      // Direct stream URLs (m3u8, mp4) will play natively

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

  void _openInYouTubeApp() async {
    final youtubeId = _getYouTubeId();
    if (youtubeId != null) {
      // Try YouTube app first, then fall back to browser
      final youtubeAppUrl = 'vnd.youtube://$youtubeId';
      final youtubeWebUrl = 'https://www.youtube.com/watch?v=$youtubeId';

      try {
        // Try to open in YouTube app
        final appUri = Uri.parse(youtubeAppUrl);
        if (await canLaunchUrl(appUri)) {
          await launchUrl(appUri);
          return;
        }
      } catch (e) {
        print('Could not open YouTube app: $e');
      }

      // Fall back to browser
      final webUri = Uri.parse(youtubeWebUrl);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          if (_isYouTube)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: _openInYouTubeApp,
              tooltip: 'Open in YouTube',
            ),
          if (_isVimeo)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: _openInVimeoApp,
              tooltip: 'Open in Vimeo',
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

    if (_isYouTube) {
      return _buildYouTubeView();
    }

    if (_isVimeo) {
      return _buildVimeoView();
    }

    return Column(
      children: [
        // Video player
        AspectRatio(
          aspectRatio: _videoController?.value.aspectRatio ?? 16 / 9,
          child: _chewieController != null
              ? Chewie(controller: _chewieController!)
              : const Center(child: CircularProgressIndicator()),
        ),

        // Video info
        Expanded(
          child: _buildVideoInfo(),
        ),
      ],
    );
  }

  Widget _buildYouTubeView() {
    return Column(
      children: [
        // YouTube thumbnail with play button overlay
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Thumbnail
              Container(
                color: Colors.black,
                child: widget.video.poster.isNotEmpty
                    ? Image.network(
                        widget.video.poster,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildYouTubeThumbnail(),
                      )
                    : _buildYouTubeThumbnail(),
              ),
              // Play button overlay
              GestureDetector(
                onTap: _openInYouTubeApp,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              // YouTube logo
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'YouTube',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tap to play message
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[900],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app, color: Colors.white70),
              const SizedBox(width: 8),
              const Text(
                'Tap to play on YouTube',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

        // Video info
        Expanded(
          child: _buildVideoInfo(),
        ),
      ],
    );
  }

  Widget _buildVimeoView() {
    return Column(
      children: [
        // Vimeo thumbnail with play button overlay
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Thumbnail - use poster image or Vimeo thumbnail
              Container(
                color: Colors.black,
                child: widget.video.poster.isNotEmpty
                    ? Image.network(
                        widget.video.poster,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildVimeoThumbnail(),
                      )
                    : _buildVimeoThumbnail(),
              ),
              // Play button overlay
              GestureDetector(
                onTap: _openInVimeoApp,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1AB7EA), // Vimeo blue
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              // Vimeo logo
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1AB7EA), // Vimeo blue
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Vimeo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tap to play message
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[900],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app, color: Colors.white70),
              const SizedBox(width: 8),
              const Text(
                'Tap to play on Vimeo',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

        // Video info
        Expanded(
          child: _buildVideoInfo(),
        ),
      ],
    );
  }

  Widget _buildVimeoThumbnail() {
    // Vimeo thumbnails require API call, so use a placeholder
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.video_library, size: 64, color: Color(0xFF1AB7EA)),
      ),
    );
  }

  Widget _buildYouTubeThumbnail() {
    final youtubeId = _getYouTubeId();
    if (youtubeId != null) {
      return Image.network(
        'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg',
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[900],
          child: const Center(
            child: Icon(Icons.video_library, size: 64, color: Colors.white54),
          ),
        ),
      );
    }
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.video_library, size: 64, color: Colors.white54),
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
            if (widget.video.embedUrl != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  if (await canLaunchUrl(Uri.parse(widget.video.embedUrl!))) {
                    await launchUrl(Uri.parse(widget.video.embedUrl!),
                        mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('Open in Browser'),
              ),
            ],
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
