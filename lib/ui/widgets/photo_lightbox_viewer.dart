import 'package:flutter/material.dart';
import 'package:family_transit_home/core/constants/colors.dart';
import 'package:family_transit_home/ui/widgets/fth_image.dart';

class PhotoLightboxViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String title;

  const PhotoLightboxViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    required this.title,
  });

  static void show(
    BuildContext context, {
    required List<String> images,
    int initialIndex = 0,
    required String title,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => PhotoLightboxViewer(
          images: images,
          initialIndex: initialIndex,
          title: title,
        ),
      ),
    );
  }

  @override
  State<PhotoLightboxViewer> createState() => _PhotoLightboxViewerState();
}

class _PhotoLightboxViewerState extends State<PhotoLightboxViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${_currentIndex + 1} of ${widget.images.length}',
              style: const TextStyle(fontSize: 12, color: AppColors.goldAccent),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (idx) {
              setState(() => _currentIndex = idx);
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                child: Center(
                  child: FthImage(
                    imagePath: widget.images[index],
                    fit: BoxFit.contain,
                    fallbackIcon: Icons.broken_image_rounded,
                  ),
                ),
              );
            },
          ),
          Container(
            height: 80,
            color: Colors.black.withValues(alpha: 0.7),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              separatorBuilder: (ctx, idx) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isSelected = index == _currentIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.goldAccent
                            : Colors.white24,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FthImage(
                      imagePath: widget.images[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
