import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerComponent extends StatefulWidget {
  const VideoPlayerComponent({
    super.key,
    required this.chewieController,
    this.autoPlay = false,
  });

  final VideoPlayerController chewieController;
  final bool autoPlay;

  @override
  State<VideoPlayerComponent> createState() => _VideoPlayerComponentState();
}

class _VideoPlayerComponentState extends State<VideoPlayerComponent> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.chewieController;
    final isAutoPlay = widget.autoPlay;

    return Chewie(
      controller: ChewieController(
        videoPlayerController: controller,
        aspectRatio: controller.value.aspectRatio,
        autoPlay: isAutoPlay,
      ),
    );
  }
}
