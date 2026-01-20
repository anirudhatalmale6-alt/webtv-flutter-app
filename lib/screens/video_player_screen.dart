import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/video.dart';
import '../config/app_config.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Video video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final videoUrl = widget.video.mediaUrl;
      if (videoUrl == null || videoUrl.isEmpty) {
        setState(() {
          _error = 'No video URL available';
          _isLoading = false;
        });
        return;
      }

      // Handle Vimeo URLs
      String actualUrl = videoUrl;
      if (videoUrl.contains('vimeo.com') && !videoUrl.contains('.m3u8')) {
        // Extract Vimeo video ID and get config
        final vimeoId = _extractVimeoId(videoUrl);
        if (vimeoId != null) {
          actualUrl = await _getVimeoStreamUrl(vimeoId) ?? videoUrl;
        }
      }

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
      print('Error initializing player: $e');
      setState(() {
        _error = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }

  String? _extractVimeoId(String url) {
    // Extract Vimeo ID from URL
    final regex = RegExp(r'vimeo\.com/(\d+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  Future<String?> _getVimeoStreamUrl(String vimeoId) async {
    // TODO: Implement Vimeo config API call
    // This would fetch the actual stream URL from Vimeo
    return null;
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
          child: SingleChildScrollView(
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
          ),
        ),
      ],
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
