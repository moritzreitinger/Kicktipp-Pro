import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String userName;
  final IconData icon;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.userName,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: CustomAppBar(userName: userName),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppTheme.mediumGray),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: AppTheme.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
