import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;

  bool _isLoading = true;
  String? _error;
  String _playerType = 'none'; // 'youtube', 'vimeo', 'native'
  bool _isFullscreen = false;

  // For Vimeo - we'll open externally since there's no good Flutter package
  String? _vimeoUrl;

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
        _initializeYouTubePlayer(widget.video.youtubeId!);
      } else if (widget.video.videoType == 'vimeo' && widget.video.vimeoId != null) {
        _initializeVimeoPlayer(widget.video.vimeoId!);
      } else if (widget.video.embedUrl != null && widget.video.embedUrl!.isNotEmpty) {
        final youtubeId = YoutubePlayer.convertUrlToId(widget.video.embedUrl!);
        if (youtubeId != null) {
          _initializeYouTubePlayer(youtubeId);
        } else {
          final vimeoId = _extractVimeoId(widget.video.embedUrl!);
          if (vimeoId != null) {
            _initializeVimeoPlayer(vimeoId);
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
      print('Error initializing player: $e');
      setState(() {
        _error = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeYouTubePlayer(String youtubeId) {
    print('Initializing YouTube player for ID: $youtubeId');

    _youtubeController = YoutubePlayerController(
      initialVideoId: youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        hideControls: false,
        hideThumbnail: true,
        forceHD: false,
        controlsVisibleAtStart: true,
      ),
    );

    setState(() {
      _playerType = 'youtube';
      _isLoading = false;
    });
  }

  void _initializeVimeoPlayer(String vimeoId) {
    print('Initializing Vimeo player for ID: $vimeoId');
    // Vimeo doesn't have a good native Flutter player
    // Store the URL and show a play button to open externally
    _vimeoUrl = 'https://vimeo.com/$vimeoId';

    setState(() {
      _playerType = 'vimeo';
      _isLoading = false;
    });
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
    } catch (e) {
      print('Error initializing native player: $e');
      setState(() {
        _error = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }

  void _openVimeoExternal() async {
    if (_vimeoUrl != null) {
      try {
        final uri = Uri.parse(_vimeoUrl!);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        print('Error opening Vimeo: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Vimeo')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: _youtubeController != null
        ? YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Color(AppConfig.primaryColorValue),
            progressColors: ProgressBarColors(
              playedColor: Color(AppConfig.primaryColorValue),
              handleColor: Color(AppConfig.primaryColorValue),
            ),
          )
        : YoutubePlayer(
            controller: YoutubePlayerController(initialVideoId: ''),
          ),
      onEnterFullScreen: () {
        setState(() => _isFullscreen = true);
      },
      onExitFullScreen: () {
        setState(() => _isFullscreen = false);
      },
      builder: (context, player) {
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
          body: _buildBody(player),
        );
      },
    );
  }

  Widget _buildBody(Widget youtubePlayer) {
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
          child: _buildVideoPlayer(youtubePlayer),
        ),
        if (!_isFullscreen)
          Expanded(child: _buildVideoInfo()),
      ],
    );
  }

  Widget _buildVideoPlayer(Widget youtubePlayer) {
    if (_playerType == 'youtube' && _youtubeController != null) {
      return youtubePlayer;
    }

    if (_playerType == 'vimeo') {
      return _buildVimeoPlayer();
    }

    if (_playerType == 'native' && _chewieController != null) {
      return Chewie(controller: _chewieController!);
    }

    return Container(
      color: Colors.black,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildVimeoPlayer() {
    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Show video thumbnail if available
          if (widget.video.poster.isNotEmpty)
            Image.network(
              widget.video.poster,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
            ),
          // Dark overlay
          Container(color: Colors.black54),
          // Play button
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _openVimeoExternal,
                icon: const Icon(Icons.play_circle_fill, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tap to play on Vimeo',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ],
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

  @override
  void dispose() {
    _youtubeController?.dispose();
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
