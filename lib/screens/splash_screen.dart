import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/app_config.dart';
import '../api/webtv_api.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _videoError = false;
  bool _showVideo = false; // Start with logo, show video after tap

  @override
  void initState() {
    super.initState();
    _preloadVideo();
  }

  Future<void> _preloadVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/intro.mp4');
      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });

        // Listen for video completion
        _videoController!.addListener(_videoListener);
      }
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _videoError = true;
        });
      }
    }
  }

  void _videoListener() {
    if (_videoController != null &&
        _videoController!.value.isInitialized &&
        _videoController!.value.position >= _videoController!.value.duration) {
      // Video finished, navigate to next screen
      _navigateToNextScreen();
    }
  }

  void _onTapScreen() {
    if (_showVideo) {
      // If video is playing, skip to next screen
      _navigateToNextScreen();
    } else {
      // Show and play the video
      if (_isVideoInitialized && !_videoError) {
        setState(() {
          _showVideo = true;
        });
        _videoController!.play();
      } else {
        // Video not ready or error, go to next screen
        _navigateToNextScreen();
      }
    }
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    Widget nextScreen;

    if (AppConfig.requiresLogin && !WebTVApi().isLoggedIn) {
      nextScreen = const LoginScreen();
    } else {
      nextScreen = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTapScreen,
        child: _showVideo && _isVideoInitialized && !_videoError
            ? _buildVideoPlayer()
            : _buildLogoSplash(),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildLogoSplash() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // JKTV Logo
          Image.asset(
            'assets/images/logo.png',
            width: 220,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            AppConfig.appTagline,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Text(
            'Tap to continue',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
