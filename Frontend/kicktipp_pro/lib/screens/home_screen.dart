import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'tips_screen.dart';
import 'my_tips_screen.dart';
import 'admin_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userName = 'Demo User';
  AppThemeMode _currentTheme = AppThemeMode.goldenTrophy;
  late final GlobalKey _tipsScreenKey;
  late final GlobalKey _myTipsScreenKey;
  late final GlobalKey _adminScreenKey;

  @override
  void initState() {
    super.initState();
    _tipsScreenKey = GlobalKey();
    _myTipsScreenKey = GlobalKey();
    _adminScreenKey = GlobalKey();
    ApiService.getUser(1).then((u) {
      if (mounted) setState(() => _userName = u.name);
    }).catchError((_) {});
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('app_theme');
      if (themeIndex != null && mounted) {
        setState(() {
          _currentTheme = AppThemeMode.values[themeIndex];
        });
      }
    } catch (e) {
      // Falls SharedPreferences nicht verfügbar ist, verwende Default
    }
  }

  Future<void> _setTheme(AppThemeMode theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('app_theme', theme.index);
    } catch (e) {
      // Falls SharedPreferences nicht verfügbar ist, speichern im Memory
    }
    setState(() {
      _currentTheme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: IndexedStack(
          key: ValueKey(_currentIndex),
          index: _currentIndex,
          children: [
            TipsScreen(
              key: _tipsScreenKey,
              userName: _userName,
              themeColor: AppTheme.getPrimaryColor(_currentTheme),
              onTipSaved: () {
                (_myTipsScreenKey.currentState as dynamic)?.refreshTips();
              },
            ),
            LeaderboardScreen(
              userName: _userName,
              themeColor: AppTheme.getPrimaryColor(_currentTheme),
            ),
            MyTipsScreen(
              key: _myTipsScreenKey,
              userName: _userName,
              themeColor: AppTheme.getPrimaryColor(_currentTheme),
            ),
            AdminScreen(
              key: _adminScreenKey,
              userName: _userName,
              themeColor: AppTheme.getPrimaryColor(_currentTheme),
              onResultSaved: () {
                // Refresh TipsScreen, MyTipsScreen und AdminScreen
                (_tipsScreenKey.currentState as dynamic)?.refreshMatches();
                (_myTipsScreenKey.currentState as dynamic)?.refreshTips();
                (_adminScreenKey.currentState as dynamic)?.refreshMatches();
              },
            ),
            ProfileScreen(
              userName: _userName,
              currentTheme: _currentTheme,
              onThemeChanged: _setTheme,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home,
                  label: 'Tipps',
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                  themeColor: AppTheme.getPrimaryColor(_currentTheme),
                ),
                _NavItem(
                  icon: Icons.emoji_events,
                  label: 'Bestenliste',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                  themeColor: AppTheme.getPrimaryColor(_currentTheme),
                ),
                _NavItem(
                  icon: Icons.list_alt,
                  label: 'Meine Tipps',
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                  themeColor: AppTheme.getPrimaryColor(_currentTheme),
                ),
                _NavItem(
                  icon: Icons.admin_panel_settings,
                  label: 'Admin',
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                  themeColor: AppTheme.getPrimaryColor(_currentTheme),
                ),
                _NavItem(
                  icon: Icons.person,
                  label: 'Profil',
                  isSelected: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                  themeColor: AppTheme.getPrimaryColor(_currentTheme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color themeColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? themeColor : AppTheme.mediumGray;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
