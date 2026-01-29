import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/app_config.dart';
import '../api/webtv_api.dart';
import 'selection_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/intro.mp4');
      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });

        // Listen for video completion
        _videoController!.addListener(_videoListener);

        // Auto-play the video immediately
        _videoController!.play();
      }
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _videoError = true;
        });
        // If video fails, go to next screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          _navigateToNextScreen();
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
    // Tap to skip the video
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    Widget nextScreen;

    if (AppConfig.requiresLogin && !WebTVApi().isLoggedIn) {
      nextScreen = const LoginScreen();
    } else {
      // Go to selection screen (JKTV Live or JKTV Play)
      nextScreen = const SelectionScreen();
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
        child: _isVideoInitialized && !_videoError
            ? _buildVideoPlayer()
            : _buildLoadingSplash(),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    // Play video in fullscreen, covering the entire screen
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }

  Widget _buildLoadingSplash() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // JKTV Logo with white background
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              width: 200,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          if (!_videoError)
            const CircularProgressIndicator(
              color: Colors.white,
            ),
        ],
      ),
    );
  }
}
