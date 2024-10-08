// lib/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      onTap: onTap,
      currentIndex: currentIndex,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(
            icon: Icon(Icons.settings_remote), label: 'Contrôle'),
        BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Sécurité'),
      ],
    );
  }
}
