import 'package:flutter/material.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class MediaViewerScreen extends StatefulWidget {
  final String? mediaUrl;
  final String? imageAsset;
  final String? title;

  const MediaViewerScreen({
    super.key,
    this.mediaUrl,
    this.imageAsset,
    this.title,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  YoutubePlayerController? _youtubeController;

  bool get _isYouTubeVideo {
    final mediaUrl = widget.mediaUrl;
    return mediaUrl != null && (mediaUrl.contains('youtube.com') || mediaUrl.contains('youtu.be'));
  }

  @override
  void initState() {
    super.initState();
    if (_isYouTubeVideo) {
      final videoId = YoutubePlayer.convertUrlToId(widget.mediaUrl!);
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId ?? '',
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(widget.title ?? 'Media Viewer'),
      ),
      body: SafeArea(
        child: Center(
          child: _isYouTubeVideo
              ? _youtubeController == null
                  ? const SizedBox.shrink()
                  : YoutubePlayerBuilder(
                      player: YoutubePlayer(
                        controller: _youtubeController!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: AppColors.primary,
                        progressColors: const ProgressBarColors(
                          playedColor: AppColors.primary,
                          handleColor: AppColors.secondary,
                        ),
                      ),
                      builder: (context, player) {
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: player,
                          ),
                        );
                      },
                    )
              : InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: widget.imageAsset != null
                      ? Image.asset(
                          widget.imageAsset!,
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          widget.mediaUrl ?? '',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_rounded,
                                color: Colors.white70,
                                size: 56,
                              ),
                            );
                          },
                        ),
                ),
        ),
      ),
    );
  }
}