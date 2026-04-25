import 'package:flutter/material.dart';

import 'deepfake/deepfake_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'reports/reports_list_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const Color bgColor = Color(0xFF0B1220);
  static const Color navColor = Color(0xFF111827);
  static const Color cyan = Color(0xFF06B6D4);

  late final List<Widget> _screens = const [
    HomeScreen(),
    ReportsListScreen(),
    DeepfakeScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: navColor,
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: navColor,
              indicatorColor: cyan.withOpacity(0.14),
              labelTextStyle: MaterialStateProperty.resolveWith((states) {
                final selected = states.contains(MaterialState.selected);

                return TextStyle(
                  color: selected ? cyan : Colors.white54,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                );
              }),
              iconTheme: MaterialStateProperty.resolveWith((states) {
                final selected = states.contains(MaterialState.selected);

                return IconThemeData(
                  color: selected ? cyan : Colors.white54,
                  size: selected ? 27 : 24,
                );
              }),
            ),
            child: NavigationBar(
              height: 72,
              elevation: 0,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'الرئيسية',
                ),
                NavigationDestination(
                  icon: Icon(Icons.report_gmailerrorred_outlined),
                  selectedIcon: Icon(Icons.report_gmailerrorred_rounded),
                  label: 'البلاغات',
                ),
                NavigationDestination(
                  icon: Icon(Icons.image_search_outlined),
                  selectedIcon: Icon(Icons.image_search_rounded),
                  label: 'Deepfake',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'حسابي',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}