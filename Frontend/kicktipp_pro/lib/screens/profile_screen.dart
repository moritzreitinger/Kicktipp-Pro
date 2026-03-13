import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final AppThemeMode currentTheme;
  final Function(AppThemeMode) onThemeChanged;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _totalPoints = 0;
  int _fullMatches = 0;
  int _submittedTips = 0;
  double _averagePointsPerGame = 0.0;
  bool _pushNotifications = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('push_notifications') ?? false;
      if (mounted) {
        setState(() => _pushNotifications = notificationsEnabled);
      }
    } catch (e) {
      // Falls SharedPreferences nicht verfügbar ist
    }
  }

  Future<void> _saveNotificationPreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('push_notifications', value);
    } catch (e) {
      // Falls SharedPreferences nicht verfügbar ist
    }
  }

  Future<void> _loadStats() async {
    try {
      final tips = await ApiService.getUserTips(1);
      
      int totalPoints = 0;
      int fullMatches = 0;
      
      for (final tip in tips) {
        totalPoints += tip.pointsEarned;
        if (tip.pointsEarned == 3) {
          fullMatches++;
        }
      }
      
      double averagePointsPerGame = tips.isNotEmpty
          ? totalPoints / tips.length
          : 0.0;

      setState(() {
        _totalPoints = totalPoints;
        _fullMatches = fullMatches;
        _submittedTips = tips.length;
        _averagePointsPerGame = averagePointsPerGame;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.getPrimaryColor(widget.currentTheme);
    
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: CustomAppBar(userName: widget.userName, backgroundColor: AppTheme.getPrimaryColor(widget.currentTheme)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: const Text(
                'Profil & Einstellungen',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            // User Profile Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('⚽', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tipp-Profi',
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Statistiken
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: const Text(
                'Statistiken',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        _buildStatCard(
                          label: 'Gesamtpunkte',
                          value: '$_totalPoints',
                          color: primaryColor,
                        ),
                        _buildStatCard(
                          label: 'Volltreffer',
                          value: '$_fullMatches',
                          color: primaryColor,
                        ),
                        _buildStatCard(
                          label: 'Abgegebene Tipps',
                          value: '$_submittedTips',
                          color: primaryColor,
                        ),
                        _buildStatCard(
                          label: 'Ø Punkte/Spiel',
                          value: _averagePointsPerGame.toStringAsFixed(2),
                          color: primaryColor,
                        ),
                      ],
                    ),
            ),
            // Theme Auswahl
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: const Text(
                'Theme auswählen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildThemeOption(
                    'Grass Green',
                    AppThemeMode.grassGreen,
                    [
                      const Color(0xFF27AE60),
                      const Color(0xFF2ECC71),
                      const Color(0xFF229954),
                    ],
                    primaryColor,
                  ),
                  const SizedBox(height: 12),
                  _buildThemeOption(
                    'Floodlight Night',
                    AppThemeMode.floodlightNight,
                    [
                      const Color(0xFF2980B9),
                      const Color(0xFF3498DB),
                      const Color(0xFF2874A6),
                    ],
                    primaryColor,
                  ),
                  const SizedBox(height: 12),
                  _buildThemeOption(
                    'Red Derby',
                    AppThemeMode.redDerby,
                    [
                      const Color(0xFFE74C3C),
                      const Color(0xFFEC7063),
                      const Color(0xFFC0392B),
                    ],
                    primaryColor,
                  ),
                  const SizedBox(height: 12),
                  _buildThemeOption(
                    'Golden Trophy',
                    AppThemeMode.goldenTrophy,
                    [
                      const Color(0xFFE67E22),
                      const Color(0xFFF39C12),
                      const Color(0xFFD68910),
                    ],
                    primaryColor,
                  ),
                  const SizedBox(height: 12),
                  _buildThemeOption(
                    'Steel City',
                    AppThemeMode.steelCity,
                    [
                      const Color(0xFF34495E),
                      const Color(0xFF5D6D7B),
                      const Color(0xFF2C3E50),
                    ],
                    primaryColor,
                  ),
                ],
              ),
            ),
            // Benachrichtigungen
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: const Text(
                'Benachrichtigungen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Push-Benachrichtigungen',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Erhalte Benachrichtigungen für neue Spieltage und Ergebnisse',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.mediumGray,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() => _pushNotifications = value);
                          _saveNotificationPreference(value);
                        },
                        activeColor: primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    String name,
    AppThemeMode theme,
    List<Color> colors,
    Color currentPrimary,
  ) {
    final themePrimary = AppTheme.getPrimaryColor(theme);
    final isSelected = widget.currentTheme == theme;

    return GestureDetector(
      onTap: () {
        widget.onThemeChanged(theme);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? themePrimary : AppTheme.cardBorder,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: colors.map((color) {
                    return Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: themePrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
