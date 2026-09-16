import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final GlobalKey<CurvedNavigationBarState>? navKey;

  const CustomBottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
    this.navKey,
  });

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      key: navKey,
      index: currentIndex,
      items: const [
        CurvedNavigationBarItem(
          child: Icon(Icons.home_rounded, color: Color(0xFF0072FF)),
          label: 'Home',
        ),
        CurvedNavigationBarItem(
          child: Icon(Icons.medical_services_outlined, color: Color(0xFF0072FF)),
          label: 'Services',
        ),
        CurvedNavigationBarItem(
          child: Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF0072FF)),
          label: 'Consult',
        ),
        CurvedNavigationBarItem(
          child: Icon(Icons.folder_shared_outlined, color: Color(0xFF0072FF)),
          label: 'Records',
        ),
        CurvedNavigationBarItem(
          child: Icon(Icons.person_outline_rounded, color: Color(0xFF0072FF)),
          label: 'Profile',
        ),
      ],
      color: Colors.white,
      buttonBackgroundColor: Colors.white,
      backgroundColor: const Color(0xFFF0F4F8),
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 400),
      onTap: (index) {
        if (onTap != null) {
          onTap!(index);
        }
      },
      letIndexChange: (index) => true,
    );
  }
}