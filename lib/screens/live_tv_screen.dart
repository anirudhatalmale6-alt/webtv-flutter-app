import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:share_plus/share_plus.dart';

class LiveTVScreen extends StatefulWidget {
  const LiveTVScreen({super.key});

  @override
  State<LiveTVScreen> createState() => _LiveTVScreenState();
}

class _LiveTVScreenState extends State<LiveTVScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;

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

  // CSS to hide jktv.live header/nav/footer and show only player + share
  static const String _hideHeaderCss = '''
    .site-header, .site-nav, .nav-logo, .nav-links, footer,
    .site-footer, .footer, nav, header {
      display: none !important;
    }
    body {
      background: #000 !important;
      padding-top: 0 !important;
      margin-top: 0 !important;
    }
    .container, .main-content, main {
      max-width: 100vw !important;
      padding: 0 !important;
      margin: 0 !important;
    }
    .video-container, .video-player, iframe, video {
      margin-top: 0 !important;
      max-width: 100% !important;
      width: 100vw !important;
      height: 100vh !important;
      position: fixed !important;
      top: 0 !important;
      left: 0 !important;
    }
  ''';

  void _injectCss(InAppWebViewController controller) {
    controller.evaluateJavascript(source: '''
      (function() {
        var style = document.createElement('style');
        style.textContent = `$_hideHeaderCss`;
        document.head.appendChild(style);
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // In landscape, go fullscreen
    if (isLandscape) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: isLandscape ? null : AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text('JKTV Live'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share('Watch JKTV Live - Kashmir\'s First Independent WebTV\nhttps://jktv.live');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri('https://jktv.live')),
            initialSettings: _webViewSettings,
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStop: (controller, url) {
              _injectCss(controller);
              setState(() => _isLoading = false);
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url?.toString() ?? '';
              // Allow jktv.live and related CDN/streaming domains
              if (url.contains('jktv.live') ||
                  url.contains('jammukashmir.tv') ||
                  url.contains('googlevideo.com') ||
                  url.contains('googleapis.com') ||
                  url.contains('vjs.zencdn.net') ||
                  url.contains('cdn.') ||
                  url.startsWith('blob:') ||
                  url.startsWith('data:')) {
                return NavigationActionPolicy.ALLOW;
              }
              // Block external navigation
              return NavigationActionPolicy.CANCEL;
            },
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          // Back button overlay in landscape
          if (isLandscape)
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }
}
