import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../views/video_player_screen.dart';

class GifPlayer extends StatefulWidget {
  final String videoName;

  const GifPlayer({
    Key? key,
    required this.videoName,
  }) : super(key: key);

  @override
  State<GifPlayer> createState() => _GifPlayerState();
}

class _GifPlayerState extends State<GifPlayer>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = true;
  int _currentFrame = 0;
  final int _totalFrames = 66;
  final String _lastFrameAsset = 'assets/video_last_frame-min.png';

  void _navigateToVideo() {
    Get.to(() => VideoPlayerScreen(), arguments: widget.videoName);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToVideo,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Image.asset(
          _isPlaying ? 'assets/video.gif' : _lastFrameAsset,
          gaplessPlayback: true,
          frameBuilder: (BuildContext context, Widget child, int? frame,
              bool wasSynchronouslyLoaded) {
            if (frame == null) {
              return Container();
            }

            if (frame != _currentFrame) {
              _currentFrame = frame;

              if (_currentFrame >= _totalFrames && _isPlaying) {
                Future.microtask(() {
                  if (mounted) {
                    setState(() {
                      _isPlaying = false;
                    });
                  }
                });
              }
            }

            return child;
          },
        ),
      ),
    );
  }
}
