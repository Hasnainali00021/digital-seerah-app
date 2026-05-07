import 'package:flutter/material.dart';

class CustomNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  String _getThumbnailUrl(String url) {
    if (url.contains("youtube.com") || url.contains("youtu.be")) {
       RegExp regExp = RegExp(
        r'.*(?:(?:youtu\.be\/|v\/|vi\/|u\/\w\/|embed\/|e\/)|(?:(?:watch)?\?v(?:i)?=|\&v(?:i)?=))([^#\&\?]*).*',
        caseSensitive: false,
        multiLine: false,
      );
      final match = regExp.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        String id = match.group(1)!;
        return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
      }
    }
    return url;
  }

  bool _isVideoUrl(String url) {
    return url.contains("youtube.com") || url.contains("youtu.be");
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = _getThumbnailUrl(imageUrl);
    return Image.network(
      effectiveUrl,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? Container(
          color: Colors.teal.shade300,
          child: const Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: Colors.white70,
              size: 36,
            ),
          ),
        );
      },
    );
  }
}
