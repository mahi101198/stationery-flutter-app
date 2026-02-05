import 'package:flutter/material.dart';

/// Media item - can be image or video
class _MediaItem {
  final String url;
  final bool isVideo;

  _MediaItem({required this.url, required this.isVideo});
}

/// Unified Carousel - Images and Videos in same carousel (like Flipkart)
class MinimalProductCarousel extends StatefulWidget {
  final List<String> images;
  final List<String> videos;

  const MinimalProductCarousel({
    super.key,
    required this.images,
    this.videos = const [],
  });

  @override
  State<MinimalProductCarousel> createState() => _MinimalProductCarouselState();
}

class _MinimalProductCarouselState extends State<MinimalProductCarousel> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late List<_MediaItem> _allMedia;
  Set<int> _playingVideos = {};

  @override
  void initState() {
    super.initState();
    _buildMediaList();
  }

  void _buildMediaList() {
    _allMedia = [];
    for (var img in widget.images) {
      _allMedia.add(_MediaItem(url: img, isVideo: false));
    }
    for (var vid in widget.videos) {
      _allMedia.add(_MediaItem(url: vid, isVideo: true));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildImageItem(String imageUrl) {
    return Builder(
      builder: (context) => Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: _buildImageWithErrorHandling(imageUrl, context),
        ),
      ),
    );
  }

  Widget _buildImageWithErrorHandling(String imageUrl, BuildContext context) {
    if (imageUrl.isEmpty || imageUrl.contains('example.com')) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Preview unavailable',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      cacheWidth: 800,
      cacheHeight: 800,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        final progress = loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
            : null;
        return Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: const Color(0xFF00BCD4),
              value: progress,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Image load error: $imageUrl');
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'Image unavailable',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoThumbnail(int index) {
    final videoUrl = _allMedia[index].url;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_playingVideos.contains(index)) {
            _playingVideos.remove(index);
          } else {
            _playingVideos.add(index);
          }
        });
        debugPrint('🎬 Video tapped: $videoUrl');
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video thumbnail - load first frame
            Image.network(
              videoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(Icons.video_camera_back, color: Colors.white54),
                  ),
                );
              },
            ),
            // Play Icon Overlay
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(
                Icons.play_arrow,
                size: 48,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaItem(int index) {
    final media = _allMedia[index];
    if (media.isVideo) {
      return _buildVideoThumbnail(index);
    }
    return _buildImageItem(media.url);
  }

  @override
  Widget build(BuildContext context) {
    if (_allMedia.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Stack(
            children: [
              // Unified Media Carousel
              PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _allMedia.length,
                itemBuilder: (context, index) => _buildMediaItem(index),
              ),

              // Pagination Dots
              if (_allMedia.length > 1)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _allMedia.length,
                      (index) => GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentIndex == index ? 24 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? const Color(0xFF00BCD4)
                                : const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
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
