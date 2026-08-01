import 'package:flutter/material.dart';
import '../utils/app_translations.dart';
import 'sync_status_indicator.dart';

class HeaderWidget extends StatelessWidget {
  final VoidCallback? onNotificationTap;
  final String currentLanguage;
  final bool hasUnread;

  const HeaderWidget({
    super.key,
    this.onNotificationTap,
    this.currentLanguage = 'English (US)',
    this.hasUnread = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Brand Info
          Row(
            children: [
              // Monogram Icon Box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : const Color(0xFF121212),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.domain_rounded,
                    color: isDark ? const Color(0xFF121212) : Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Brand Title & Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perfect Optical',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppTranslations.tr(currentLanguage, 'portal_tag'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE53935),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right Controls: SyncStatusIndicator + Notification Bell Button
          Row(
            children: [
              const SyncStatusIndicator(),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onNotificationTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1B20) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: textColor,
                          size: 22,
                        ),
                      ),
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 10,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
