import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final Color? backgroundColor;

  const CustomAppBar({
    super.key,
    required this.userName,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final themeColor = backgroundColor ?? AppTheme.primaryOrange;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 160,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: themeColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sports_soccer,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Kicktipp Pro',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Text(
          userName,
          style: const TextStyle(
            color: AppTheme.darkGray,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_soccer,
              color: AppTheme.mediumGray,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
