import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video.dart';
import '../utils/tv_detector.dart';

class VideoRow extends StatelessWidget {
  final String title;
  final List<Video> videos;
  final Function(Video) onVideoTap;
  final VoidCallback? onSeeAll;

  const VideoRow({
    super.key,
    required this.title,
    required this.videos,
    required this.onVideoTap,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final isTV = TVDetector.isTV(context);
    final scale = TVDetector.getScaleFactor(context);
    final cardWidth = isTV ? 220.0 : 140.0;
    final cardHeight = isTV ? 280.0 : 180.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 24 * scale, 16, 12 * scale),
          child: GestureDetector(
            onTap: onSeeAll,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isTV ? 24 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (onSeeAll != null)
                  Row(
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(fontSize: isTV ? 18 : 13, color: Colors.white54),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: isTV ? 16 : 12, color: Colors.white54),
                    ],
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return VideoCard(
                video: video,
                onTap: () => onVideoTap(video),
                width: cardWidth,
                isTV: isTV,
                autofocus: index == 0,
              );
            },
          ),
        ),
      ],
    );
  }
}

class VideoCard extends StatefulWidget {
  final Video video;
  final VoidCallback onTap;
  final double width;
  final bool isTV;
  final bool autofocus;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
    this.width = 140,
    this.isTV = false,
    this.autofocus = false,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final thumbnailHeight = widget.width * 0.75;

    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          print('VideoCard tapped: ${widget.video.id} - ${widget.video.title}');
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          transform: _isFocused ? (Matrix4.identity()..scale(1.1)) : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: _isFocused
                ? Border.all(color: Colors.white, width: 3)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.video.thumbnail,
                      width: widget.width,
                      height: thumbnailHeight,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.error, color: Colors.white54),
                      ),
                    ),
                  ),
                  // Duration badge
                  if (widget.video.durationFormatted.isNotEmpty)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.isTV ? 6 : 4,
                          vertical: widget.isTV ? 3 : 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.video.durationFormatted,
                          style: TextStyle(
                            fontSize: widget.isTV ? 14 : 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  // Live badge
                  if (widget.video.isLive)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.isTV ? 8 : 6,
                          vertical: widget.isTV ? 3 : 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: widget.isTV ? 14 : 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Focus indicator play icon
                  if (_isFocused)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            size: widget.isTV ? 60 : 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.isTV ? 16 : 12,
                    color: _isFocused ? Colors.white : Colors.white,
                    fontWeight: _isFocused ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Views
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.video.formattedViews,
                  style: TextStyle(
                    fontSize: widget.isTV ? 14 : 10,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
