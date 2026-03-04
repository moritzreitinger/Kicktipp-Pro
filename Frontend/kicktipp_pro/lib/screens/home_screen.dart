import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'tips_screen.dart';
import 'my_tips_screen.dart';
import 'placeholder_screen.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userName = 'Demo User';
  late final GlobalKey _myTipsScreenKey;

  @override
  void initState() {
    super.initState();
    _myTipsScreenKey = GlobalKey();
    ApiService.getUser(1).then((u) {
      if (mounted) setState(() => _userName = u.name);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          TipsScreen(
            userName: _userName,
            onTipSaved: () {
              (_myTipsScreenKey.currentState as dynamic)?.refreshTips();
            },
          ),
          PlaceholderScreen(
            title: 'Bestenliste',
            userName: _userName,
            icon: Icons.emoji_events,
          ),
          MyTipsScreen(
            key: _myTipsScreenKey,
            userName: _userName,
          ),
          PlaceholderScreen(
            title: 'Admin',
            userName: _userName,
            icon: Icons.admin_panel_settings,
          ),
          PlaceholderScreen(
            title: 'Profil',
            userName: _userName,
            icon: Icons.person,
          ),
        ],
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
                ),
                _NavItem(
                  icon: Icons.emoji_events,
                  label: 'Bestenliste',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.list_alt,
                  label: 'Meine Tipps',
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.admin_panel_settings,
                  label: 'Admin',
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _NavItem(
                  icon: Icons.person,
                  label: 'Profil',
                  isSelected: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 8),
        child: FloatingActionButton(
          mini: true,
          onPressed: () {},
          backgroundColor: AppTheme.darkGray,
          child: const Icon(Icons.help, color: Colors.white, size: 24),
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

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.primaryOrange : AppTheme.mediumGray;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
