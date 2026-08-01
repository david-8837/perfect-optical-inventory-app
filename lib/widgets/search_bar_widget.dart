import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_translations.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final String currentLanguage;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onChanged,
    this.onFilterTap,
    this.currentLanguage = 'English (US)',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final cardBg = isDark ? const Color(0xFF1A1B20) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Tagline Header
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: AppTranslations.tr(currentLanguage, 'look_sharp'),
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: AppTranslations.tr(currentLanguage, 'find_frames'),
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF9E9E9E),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Search input bar
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 18),
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF9E9E9E),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: AppTranslations.tr(currentLanguage, 'search_placeholder'),
                      hintStyle: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFB0B0B0),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.clear();
                      if (onChanged != null) onChanged!('');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.cancel_rounded, color: Color(0xFF8E8E93), size: 20),
                    ),
                  ),
                // Filter Button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (onFilterTap != null) onFilterTap!();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : const Color(0xFF121212),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.tune_rounded,
                        color: isDark ? const Color(0xFF121212) : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
