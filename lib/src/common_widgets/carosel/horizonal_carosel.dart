import 'package:flutter/material.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';

class CarouselItemData {
  final String title;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final List<Color> gradientColors;
  final String? imagePath;

  const CarouselItemData({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.gradientColors,
    this.imagePath,
  });
}

class HorizontalCarouselWidget extends StatelessWidget {
  final List<CarouselItemData>? items;
  final double height;
  final bool autoPlay;

  const HorizontalCarouselWidget({
    super.key,
    this.items,
    this.height = 180.0,
    this.autoPlay = true,
  });

  static const List<CarouselItemData> defaultItems = [
    CarouselItemData(
      title: 'Offline Tele-Consultation',
      subtitle: 'Connect with specialist doctors anywhere in Nepal',
      badgeText: '24/7 Available',
      icon: Icons.video_call_rounded,
      gradientColors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
    ),
    CarouselItemData(
      title: 'Sync Health Records',
      subtitle: 'Keep your medical history ready even without internet',
      badgeText: 'Offline First',
      icon: Icons.cloud_sync_rounded,
      gradientColors: [Color(0xFF11998E), Color(0xFF38EF7D)],
    ),
    CarouselItemData(
      title: 'Free Rural Health Camp',
      subtitle: 'Upcoming general checkup & medicine distribution camp',
      badgeText: 'Special Event',
      icon: Icons.health_and_safety_rounded,
      gradientColors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final displayItems = items ?? defaultItems;

    return SizedBox(
      height: height,
      child: Swiper(
        itemCount: displayItems.length,
        autoplay: autoPlay,
        autoplayDelay: 4000,
        duration: 800,
        viewportFraction: 0.9,
        scale: 0.95,
        pagination: const SwiperPagination(
          alignment: Alignment.bottomCenter,
          builder: DotSwiperPaginationBuilder(
            color: Colors.white38,
            activeColor: Colors.white,
            size: 8.0,
            activeSize: 10.0,
            space: 4.0,
          ),
        ),
        itemBuilder: (context, index) {
          final item = displayItems[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: item.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: item.gradientColors.first.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background Decorative Circle
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Positioned(
                  right: 40,
                  top: -30,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          item.badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // Title & Subtitle Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12.0,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}