import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/frame_item.dart';
import '../utils/app_translations.dart';
import '../widgets/app_image_widget.dart';
import 'profile_screen.dart';
import 'help_support_screen.dart';
import '../widgets/sync_notification_toast.dart';
import '../widgets/upload_progress_modal.dart';
import '../services/local_database_service.dart';
import '../services/supabase_sync_service.dart';

class InventoryHubScreen extends StatefulWidget {
  final List<FrameItem> frames;
  final VoidCallback? onUploadHistoryTap;
  final Function(String frameId)? onDeleteFrame;
  final ThemeMode currentThemeMode;
  final String currentLanguage;
  final Function(String themeStr) onThemeChanged;
  final Function(String lang) onLanguageChanged;
  final VoidCallback? onLogout;

  const InventoryHubScreen({
    super.key,
    required this.frames,
    this.onUploadHistoryTap,
    this.onDeleteFrame,
    this.currentThemeMode = ThemeMode.light,
    this.currentLanguage = 'English (US)',
    required this.onThemeChanged,
    required this.onLanguageChanged,
    this.onLogout,
  });

  @override
  State<InventoryHubScreen> createState() => _InventoryHubScreenState();
}

class _InventoryHubScreenState extends State<InventoryHubScreen> {
  String get _selectedTheme {
    if (widget.currentThemeMode == ThemeMode.dark) return 'Dark Mode';
    if (widget.currentThemeMode == ThemeMode.light) return 'Light Mode';
    return 'System Default';
  }

  String get _selectedLanguage => widget.currentLanguage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalModels = widget.frames.length;
    final uniqueBrands = widget.frames.map((f) => f.brand).toSet().length;
    final totalUnits = widget.frames.fold<int>(0, (sum, item) => sum + item.stockCount);

    final cardBg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final subTextColor = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);
    final lang = _selectedLanguage;

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) setState(() {});
      },
      color: isDark ? Colors.white : const Color(0xFF121212),
      backgroundColor: isDark ? const Color(0xFF1A1B20) : Colors.white,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
        // Title Header
        Text(
          AppTranslations.tr(lang, 'inventory_hub'),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppTranslations.tr(lang, 'hub_subtitle'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: subTextColor,
          ),
        ),
        const SizedBox(height: 24),

        // Main Inventory Overview Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top Portal Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon Box with Red Active Indicator Dot
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF282A32) : const Color(0xFF121212),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.domain_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            shape: BoxShape.circle,
                            border: Border.all(color: cardBg, width: 2.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Portal Details & Badge
                  Expanded(
                    child: Column(
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
                          AppTranslations.tr(lang, 'portal_tag'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: subTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // System Status Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1B382B)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  size: 13, color: Color(0xFF4CAF50)),
                              const SizedBox(width: 4),
                              Text(
                                AppTranslations.tr(lang, 'system_online'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(color: Colors.grey.withOpacity(0.15), height: 1),
              const SizedBox(height: 18),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.inventory_2_rounded,
                      value: '$totalModels',
                      label: AppTranslations.tr(lang, 'total_models'),
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.grey.withOpacity(0.15),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.style_rounded,
                      value: '$uniqueBrands',
                      label: AppTranslations.tr(lang, 'brands_active'),
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.grey.withOpacity(0.15),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      icon: Icons.warehouse_rounded,
                      value: '$totalUnits',
                      label: AppTranslations.tr(lang, 'stock_units'),
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // APP PREFERENCES & LOGS Section
        Text(
          AppTranslations.tr(lang, 'app_preferences'),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: subTextColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),

        // 1. Stock & Quantity Control Card
        _ManageStockCard(
          totalUnits: totalUnits,
          isDark: isDark,
          currentLanguage: lang,
          onTap: () => _showStockManagerModal(context),
        ),

        const SizedBox(height: 12),

        // 2. Upload History Card
        _HistoryCard(
          framesCount: totalModels,
          isDark: isDark,
          currentLanguage: lang,
          onTap: () {
            if (widget.onUploadHistoryTap != null) {
              widget.onUploadHistoryTap!();
            } else {
              _showUploadHistoryModal(context);
            }
          },
        ),

        const SizedBox(height: 12),

        // 3. Manage & Delete Frames Card
        _ManageFramesCard(
          framesCount: totalModels,
          isDark: isDark,
          currentLanguage: lang,
          onTap: () => _showManageFramesModal(context),
        ),

        const SizedBox(height: 28),

        // SYSTEM SETTINGS & PREFERENCES Section
        Text(
          AppTranslations.tr(lang, 'system_settings'),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: subTextColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),

        // 1. Theme Mode Card
        _SettingsTile(
          icon: Icons.dark_mode_rounded,
          iconColor: const Color(0xFF7C4DFF),
          bgColor: isDark ? const Color(0xFF2C2448) : const Color(0xFFE8EAF6),
          title: AppTranslations.tr(lang, 'theme_mode'),
          subtitle: 'Active: ${_selectedTheme == "Dark Mode" ? AppTranslations.tr(lang, "dark_mode") : _selectedTheme == "Light Mode" ? AppTranslations.tr(lang, "light_mode") : AppTranslations.tr(lang, "system_default")}',
          isDark: isDark,
          onTap: () => _showThemePickerSheet(context),
        ),
        const SizedBox(height: 12),

        // 2. Language Card
        _SettingsTile(
          icon: Icons.translate_rounded,
          iconColor: const Color(0xFF00BFA5),
          bgColor: isDark ? const Color(0xFF1B3D38) : const Color(0xFFE0F2F1),
          title: AppTranslations.tr(lang, 'language'),
          subtitle: 'Active: $_selectedLanguage',
          isDark: isDark,
          onTap: () => _showLanguagePickerSheet(context),
        ),
        const SizedBox(height: 12),

        // 3. About Card
        _SettingsTile(
          icon: Icons.info_outline_rounded,
          iconColor: const Color(0xFF03A9F4),
          bgColor: isDark ? const Color(0xFF1A384A) : const Color(0xFFE1F5FE),
          title: AppTranslations.tr(lang, 'about'),
          subtitle: AppTranslations.tr(lang, 'about_subtitle'),
          isDark: isDark,
          onTap: () => _showAboutModal(context),
        ),
        const SizedBox(height: 12),

        // 4. Privacy Policy Card
        _SettingsTile(
          icon: Icons.privacy_tip_outlined,
          iconColor: const Color(0xFFAB47BC),
          bgColor: isDark ? const Color(0xFF38233C) : const Color(0xFFF3E5F5),
          title: AppTranslations.tr(lang, 'privacy_policy'),
          subtitle: AppTranslations.tr(lang, 'privacy_subtitle'),
          isDark: isDark,
          onTap: () => _showPrivacyPolicyModal(context),
        ),
        const SizedBox(height: 12),

        // 5. Terms & Conditions Card
        _SettingsTile(
          icon: Icons.gavel_rounded,
          iconColor: const Color(0xFFFF9800),
          bgColor: isDark ? const Color(0xFF3D2C1B) : const Color(0xFFFFF3E0),
          title: AppTranslations.tr(lang, 'terms_conditions'),
          subtitle: AppTranslations.tr(lang, 'terms_subtitle'),
          isDark: isDark,
          onTap: () => _showTermsModal(context),
        ),
        const SizedBox(height: 12),

        // 6. Help & Support Card
        _SettingsTile(
          icon: Icons.help_outline_rounded,
          iconColor: const Color(0xFF0288D1),
          bgColor: isDark ? const Color(0xFF1A384A) : const Color(0xFFE1F5FE),
          title: 'Help & Support Center',
          subtitle: 'Staff user manual, FAQs & inventory guide',
          isDark: isDark,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (ctx) => const HelpSupportScreen()));
          },
        ),
        const SizedBox(height: 12),

        // 7. Staff Profile & Session Card
        _SettingsTile(
          icon: Icons.account_circle_outlined,
          iconColor: const Color(0xFF4CAF50),
          bgColor: isDark ? const Color(0xFF1B382B) : const Color(0xFFE8F5E9),
          title: 'Staff Profile & Session',
          subtitle: 'View staff credentials, role & session security',
          isDark: isDark,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (ctx) => ProfileScreen(
              onLogout: () {
                if (widget.onLogout != null) widget.onLogout!();
              },
            )));
          },
        ),
      ],
    ),
  );
}

  // 1. Slide Up Theme Picker Sheet
  void _showThemePickerSheet(BuildContext context) {
    final lang = _selectedLanguage;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bg = isDark ? const Color(0xFF1A1B20) : Colors.white;
          final txt = isDark ? Colors.white : const Color(0xFF121212);
          final subTxt = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);
          final optionBg = isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8);

          final options = [
            {'title': 'Light Mode', 'trKey': 'light_mode', 'icon': Icons.light_mode_rounded, 'sub': 'Clean bright interface (Default)'},
            {'title': 'Dark Mode', 'trKey': 'dark_mode', 'icon': Icons.dark_mode_rounded, 'sub': 'Sleek dark glassmorphic styling'},
            {'title': 'System Default', 'trKey': 'system_default', 'icon': Icons.brightness_auto_rounded, 'sub': 'Match operating system appearance'},
          ];

          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2448) : const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(Icons.dark_mode_rounded, color: Color(0xFF7C4DFF), size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppTranslations.tr(lang, 'theme_mode'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: txt)),
                          const SizedBox(height: 2),
                          Text(AppTranslations.tr(lang, 'theme_subtitle'), style: TextStyle(fontSize: 11.5, color: subTxt)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close_rounded, color: subTxt)),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.withOpacity(0.15), height: 1),
                const SizedBox(height: 14),
                ...options.map((opt) {
                  final isSelected = _selectedTheme == opt['title'];
                  final titleText = AppTranslations.tr(lang, opt['trKey'] as String);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onThemeChanged(opt['title'] as String);
                      Navigator.pop(ctx);
                      SyncToastController().showNotification(
                        title: 'Theme Updated',
                        message: 'Theme set to "$titleText"',
                        eventType: 'edit',
                        icon: titleText == 'Dark Mode'
                            ? Icons.dark_mode_rounded
                            : (titleText == 'Light Mode'
                                ? Icons.light_mode_rounded
                                : Icons.brightness_auto_rounded),
                        accentColor: const Color(0xFF3B82F6),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? (isDark ? Colors.white : const Color(0xFF121212)) : optionBg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Icon(opt['icon'] as IconData, color: isSelected ? (isDark ? const Color(0xFF121212) : Colors.white) : txt, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(titleText, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isSelected ? (isDark ? const Color(0xFF121212) : Colors.white) : txt)),
                                const SizedBox(height: 2),
                                Text(opt['sub'] as String, style: TextStyle(fontSize: 11.5, color: isSelected ? (isDark ? Colors.black54 : Colors.white70) : subTxt)),
                              ],
                            ),
                          ),
                          if (isSelected) Icon(Icons.check_circle_rounded, color: isDark ? const Color(0xFF121212) : Colors.white, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  // 2. Slide Up Language Picker Sheet
  void _showLanguagePickerSheet(BuildContext context) {
    final lang = _selectedLanguage;
    final languages = [
      {'name': 'English (US)', 'flag': '🇺🇸', 'native': 'English'},
      {'name': 'Spanish', 'flag': '🇪🇸', 'native': 'Español'},
      {'name': 'French', 'flag': '🇫🇷', 'native': 'Français'},
      {'name': 'German', 'flag': '🇩🇪', 'native': 'Deutsch'},
      {'name': 'Hindi', 'flag': '🇮🇳', 'native': 'हिन्दी'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF1A1B20) : Colors.white;
        final txt = isDark ? Colors.white : const Color(0xFF121212);
        final subTxt = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);
        final optionBg = isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8);

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(color: isDark ? Colors.grey[700] : const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF1B3D38) : const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(14)),
                    child: const Center(child: Icon(Icons.translate_rounded, color: Color(0xFF00BFA5), size: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppTranslations.tr(lang, 'language'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: txt)),
                        const SizedBox(height: 2),
                        Text(AppTranslations.tr(lang, 'lang_subtitle'), style: TextStyle(fontSize: 11.5, color: subTxt)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close_rounded, color: subTxt)),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.withOpacity(0.15), height: 1),
              const SizedBox(height: 14),
              ...languages.map((l) {
                final isSelected = _selectedLanguage == l['name'];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onLanguageChanged(l['name'] as String);
                    Navigator.pop(ctx);
                    SyncToastController().showNotification(
                      title: 'Language Updated',
                      message: 'Language set to ${l['name']}',
                      eventType: 'edit',
                      icon: Icons.language_rounded,
                      accentColor: const Color(0xFF3B82F6),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? (isDark ? Colors.white : const Color(0xFF121212)) : optionBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Text(l['flag']!, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${l['name']} (${l['native']})',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? (isDark ? const Color(0xFF121212) : Colors.white) : txt,
                            ),
                          ),
                        ),
                        if (isSelected) Icon(Icons.check_circle_rounded, color: isDark ? const Color(0xFF121212) : Colors.white, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // 3. Slide Up About Modal
  void _showAboutModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF121212);
    final subTxt = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);
    final lang = _selectedLanguage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 42, height: 5, decoration: BoxDecoration(color: isDark ? Colors.grey[700] : const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: isDark ? Colors.white : const Color(0xFF121212), borderRadius: BorderRadius.circular(20)),
              child: Center(child: Icon(Icons.domain_rounded, color: isDark ? const Color(0xFF121212) : Colors.white, size: 32)),
            ),
            const SizedBox(height: 14),
            Text('Perfect Optical', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: txt)),
            const SizedBox(height: 4),
            Text(AppTranslations.tr(lang, 'hub_subtitle'), style: TextStyle(fontSize: 12.5, color: subTxt)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF1A384A) : const Color(0xFFE1F5FE), borderRadius: BorderRadius.circular(12)),
              child: const Text('Version 2.4.0 (Build 24001)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF03A9F4))),
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
            const SizedBox(height: 16),
            Text(
              'Designed & Engineered by Google DeepMind Team with Flutter Web & Supabase Cloud.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.5, color: subTxt),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : const Color(0xFF121212),
                  foregroundColor: isDark ? const Color(0xFF121212) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: Text(AppTranslations.tr(lang, 'done'), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Slide Up Privacy Policy Modal
  void _showPrivacyPolicyModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF121212);
    final subTxt = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);
    final lang = _selectedLanguage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF38233C) : const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Center(
                      child: Icon(Icons.privacy_tip_outlined,
                          color: Color(0xFFAB47BC), size: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppTranslations.tr(lang, 'privacy_policy'),
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: txt)),
                      const SizedBox(height: 2),
                      Text(AppTranslations.tr(lang, 'privacy_subtitle'),
                          style: TextStyle(
                              fontSize: 11.5, color: subTxt)),
                    ],
                  ),
                ),
                IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close_rounded,
                        color: subTxt)),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.withOpacity(0.15), height: 1),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  '1. Data Collection & Security\nPerfect Optical values your privacy. We collect minimal inventory logs, product photos, and frame specifications required solely for warehouse operations.\n\n'
                  '2. End-to-End Encryption\nAll uploaded image files and inventory metadata are encrypted using AES-256 standards during transit and storage on Supabase Cloud.\n\n'
                  '3. Data Retention & Control\nTeam members maintain complete authority to delete frame records or update stock levels at any time.\n\n'
                  '4. Compliance\nWe comply with international data security standards and never sell or share warehouse data with third parties.',
                  style: TextStyle(
                      fontSize: 13, height: 1.6, color: subTxt),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Slide Up Terms & Conditions Modal
  void _showTermsModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF121212);
    final subTxt = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);
    final lang = _selectedLanguage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3D2C1B) : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Center(
                      child: Icon(Icons.gavel_rounded,
                          color: Color(0xFFFF9800), size: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppTranslations.tr(lang, 'terms_conditions'),
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: txt)),
                      const SizedBox(height: 2),
                      Text(AppTranslations.tr(lang, 'terms_subtitle'),
                          style: TextStyle(
                              fontSize: 11.5, color: subTxt)),
                    ],
                  ),
                ),
                IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close_rounded,
                        color: subTxt)),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.withOpacity(0.15), height: 1),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  '1. Acceptance of Terms\nBy accessing Perfect Optical Inventory Portal, you agree to comply with authorized team usage guidelines.\n\n'
                  '2. Authorized Warehouse Management\nUsers are responsible for ensuring accurate product pricing, stock counts, and brand categories.\n\n'
                  '3. Intellectual Property\nAll brand monograms, luxury cards, design assets, and custom UI components remain the property of Perfect Optical Inc.\n\n'
                  '4. System Updates & Maintenance\nSystem features may receive automated updates to maintain security and web performance.',
                  style: TextStyle(
                      fontSize: 13, height: 1.6, color: subTxt),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Slide Up Stock Manager Sheet
  void _showStockManagerModal(BuildContext context) {
    final searchCtrl = TextEditingController();
    String query = '';
    String activeFilter = 'All';
    final lang = _selectedLanguage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bg = isDark ? const Color(0xFF1A1B20) : Colors.white;
          final txt = isDark ? Colors.white : const Color(0xFF121212);
          final subTxt = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);
          final itemBg = isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8);

          final filteredList = widget.frames.where((f) {
            final q = query.toLowerCase();
            final matchesSearch = q.isEmpty ||
                f.name.toLowerCase().contains(q) ||
                f.brand.toLowerCase().contains(q) ||
                f.category.toLowerCase().contains(q);

            if (!matchesSearch) return false;

            if (activeFilter == 'Low Stock') return f.stockCount > 0 && f.stockCount < 5;
            if (activeFilter == 'In Stock') return f.stockCount >= 5;
            if (activeFilter == 'Out of Stock') return f.stockCount == 0;
            return true;
          }).toList();

          final lowStockCount = widget.frames.where((f) => f.stockCount > 0 && f.stockCount < 5).length;
          final outOfStockCount = widget.frames.where((f) => f.stockCount == 0).length;
          final totalUnitsCount = widget.frames.fold<int>(0, (sum, f) => sum + f.stockCount);

          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B382B) : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.warehouse_rounded,
                          color: Color(0xFF4CAF50),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppTranslations.tr(lang, 'stock_control')} ($totalUnitsCount ${AppTranslations.tr(lang, 'units')})',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: txt,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${AppTranslations.tr(lang, 'low_stock')} ($lowStockCount) • ${AppTranslations.tr(lang, 'out_of_stock')} ($outOfStockCount)',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: subTxt,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close_rounded, color: subTxt),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.withOpacity(0.15), height: 1),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      {'key': 'All', 'trKey': 'all'},
                      {'key': 'In Stock', 'trKey': 'in_stock'},
                      {'key': 'Low Stock', 'trKey': 'low_stock'},
                      {'key': 'Out of Stock', 'trKey': 'out_of_stock'},
                    ].map((filterObj) {
                      final filterKey = filterObj['key']!;
                      final filterLabel = AppTranslations.tr(lang, filterObj['trKey']!);
                      final isSel = activeFilter == filterKey;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filterLabel),
                          selected: isSel,
                          selectedColor: isDark ? Colors.white : const Color(0xFF121212),
                          backgroundColor: itemBg,
                          labelStyle: TextStyle(
                            color: isSel ? (isDark ? const Color(0xFF121212) : Colors.white) : subTxt,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide.none,
                          ),
                          showCheckmark: false,
                          onSelected: (selected) {
                            if (selected) {
                              HapticFeedback.selectionClick();
                              setSheetState(() => activeFilter = filterKey);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchCtrl,
                  onChanged: (val) => setSheetState(() => query = val),
                  style: TextStyle(color: txt),
                  decoration: InputDecoration(
                    hintText: AppTranslations.tr(lang, 'search_placeholder'),
                    hintStyle: TextStyle(fontSize: 13.5, color: subTxt),
                    prefixIcon: Icon(Icons.search_rounded, color: subTxt, size: 20),
                    filled: true,
                    fillColor: itemBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                if (filteredList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Text(AppTranslations.tr(lang, 'no_frames_found'), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: subTxt)),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        Color badgeColor = const Color(0xFF4CAF50);
                        Color badgeBg = isDark ? const Color(0xFF1B382B) : const Color(0xFFE8F5E9);
                        String badgeText = '${item.stockCount} ${AppTranslations.tr(lang, 'units')}';

                        if (item.stockCount == 0) {
                          badgeColor = const Color(0xFFEF4444);
                          badgeBg = isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFFEBEE);
                          badgeText = AppTranslations.tr(lang, 'out_badge');
                        } else if (item.stockCount < 5) {
                          badgeColor = const Color(0xFFFF9800);
                          badgeBg = isDark ? const Color(0xFF3D2C1B) : const Color(0xFFFFF3E0);
                          badgeText = '${item.stockCount} ${AppTranslations.tr(lang, 'left_low')}';
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: itemBg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1B20) : Colors.white, borderRadius: BorderRadius.circular(14)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: AppImageWidget(
                                    imagePath: item.imagePath,
                                    fit: BoxFit.cover,
                                    iconSize: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: txt)),
                                    const SizedBox(height: 2),
                                    Text('${item.brand} • ₹${item.price.toInt()}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: subTxt)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                                      child: Text(badgeText, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: badgeColor)),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (item.stockCount > 0) {
                                        HapticFeedback.lightImpact();
                                        setSheetState(() => item.stockCount--);
                                        setState(() {});
                                      }
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(color: isDark ? const Color(0xFF383A42) : Colors.white, shape: BoxShape.circle),
                                      child: Center(child: Icon(Icons.remove_rounded, size: 16, color: txt)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 24,
                                    child: Center(
                                      child: Text('${item.stockCount}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: txt)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setSheetState(() => item.stockCount++);
                                      setState(() {});
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(color: isDark ? Colors.white : const Color(0xFF121212), shape: BoxShape.circle),
                                      child: Center(child: Icon(Icons.add_rounded, size: 16, color: isDark ? const Color(0xFF121212) : Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Slide Up Manage & Delete Frames Sheet
  void _showManageFramesModal(BuildContext context) {
    final searchCtrl = TextEditingController();
    String query = '';
    final lang = _selectedLanguage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final bg = isDark ? const Color(0xFF1A1B20) : Colors.white;
          final txt = isDark ? Colors.white : const Color(0xFF121212);
          final subTxt = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);
          final itemBg = isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8);

          final filteredList = widget.frames.where((f) {
            final q = query.toLowerCase();
            return q.isEmpty ||
                f.name.toLowerCase().contains(q) ||
                f.brand.toLowerCase().contains(q) ||
                f.category.toLowerCase().contains(q) ||
                f.color.toLowerCase().contains(q);
          }).toList();

          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(color: isDark ? Colors.grey[700] : const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444), size: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppTranslations.tr(lang, 'manage_delete')} (${widget.frames.length})',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: txt, letterSpacing: -0.3),
                          ),
                          const SizedBox(height: 2),
                          Text(AppTranslations.tr(lang, 'manage_subtitle'), overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: 11.5, color: subTxt)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close_rounded, color: subTxt)),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.withOpacity(0.15), height: 1),
                const SizedBox(height: 14),
                TextField(
                  controller: searchCtrl,
                  onChanged: (val) => setSheetState(() => query = val),
                  style: TextStyle(color: txt),
                  decoration: InputDecoration(
                    hintText: AppTranslations.tr(lang, 'search_placeholder'),
                    hintStyle: TextStyle(fontSize: 13.5, color: subTxt),
                    prefixIcon: Icon(Icons.search_rounded, color: subTxt, size: 20),
                    filled: true,
                    fillColor: itemBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                if (filteredList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Center(child: Text(AppTranslations.tr(lang, 'no_frames_found'), style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: subTxt))),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: itemBg, borderRadius: BorderRadius.circular(18)),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1B20) : Colors.white, borderRadius: BorderRadius.circular(14)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: AppImageWidget(
                                    imagePath: item.imagePath,
                                    fit: BoxFit.cover,
                                    iconSize: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: txt)),
                                    const SizedBox(height: 2),
                                    Text('${item.brand} • ${AppTranslations.trCategory(lang, item.category)} • ₹${item.price.toInt()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: subTxt)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (dialogCtx) => UploadProgressModal(
                                      frameName: item.name,
                                      brand: item.brand,
                                      price: item.price,
                                      imagePath: item.imagePath,
                                      isDeleteMode: true,
                                      uploadTask: () async {
                                        if (widget.onDeleteFrame != null) {
                                          widget.onDeleteFrame!(item.id);
                                        }
                                        LocalDatabaseService().deleteFrame(item.id, markPending: true);
                                        await SupabaseSyncService().broadcastAction(action: 'delete', frame: item);
                                        return item;
                                      },
                                      onSuccess: (deletedFrame) {
                                        setSheetState(() {});
                                        SyncToastController().showNotification(
                                          title: 'Frame Deleted',
                                          message: 'Deleted "${deletedFrame.name}" from inventory',
                                          eventType: 'delete',
                                          icon: Icons.delete_forever_rounded,
                                          accentColor: const Color(0xFFEF4444),
                                        );
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(color: isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFFEBEE), shape: BoxShape.circle),
                                  child: const Center(child: Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Slide Up Upload History Sheet (Matches Screenshot EXACTLY!)
  void _showUploadHistoryModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF121212);
    final subTxt = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);
    final itemBg = isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8);
    final lang = _selectedLanguage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: isDark ? Colors.grey[700] : const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Icon(Icons.history_rounded, color: Color(0xFFEF4444), size: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${AppTranslations.tr(lang, 'upload_history')} (${widget.frames.length})', overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: txt, letterSpacing: -0.3)),
                      const SizedBox(height: 2),
                      Text(AppTranslations.tr(lang, 'history_subtitle'), overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontSize: 11.5, color: subTxt)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close_rounded, color: subTxt)),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.withOpacity(0.15), height: 1),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.frames.length,
                itemBuilder: (ctx, index) {
                  final item = widget.frames[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: itemBg, borderRadius: BorderRadius.circular(12)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AppImageWidget(
                          imagePath: item.imagePath,
                          fit: BoxFit.cover,
                          iconSize: 20,
                        ),
                      ),
                    ),
                    title: Text(item.name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: txt)),
                    subtitle: Text('Uploaded ${item.formattedDate} • ${item.brand}', style: TextStyle(fontSize: 12, color: subTxt)),
                    trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 18),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String value,
    required String label,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: textColor),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.3)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: subTextColor)),
      ],
    );
  }
}

// Reusable Dynamic Settings Tile Card Widget
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final subTextColor = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: subTextColor,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDark ? const Color(0xFF555555) : const Color(0xFFC7C7CC),
        ),
      ),
    );
  }
}

class _ManageStockCard extends StatelessWidget {
  final int totalUnits;
  final bool isDark;
  final String currentLanguage;
  final VoidCallback onTap;

  const _ManageStockCard({required this.totalUnits, required this.isDark, required this.currentLanguage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final subTextColor = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1B382B) : const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14)),
          child: const Center(child: Icon(Icons.warehouse_rounded, color: Color(0xFF4CAF50), size: 22)),
        ),
        title: Text(AppTranslations.tr(currentLanguage, 'stock_control'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.2)),
        subtitle: Text('${AppTranslations.tr(currentLanguage, 'stock_subtitle')} ($totalUnits ${AppTranslations.tr(currentLanguage, 'units')})', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: subTextColor)),
        trailing: Icon(Icons.chevron_right_rounded, color: isDark ? const Color(0xFF555555) : const Color(0xFFC7C7CC)),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final int framesCount;
  final bool isDark;
  final String currentLanguage;
  final VoidCallback onTap;

  const _HistoryCard({required this.framesCount, required this.isDark, required this.currentLanguage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final subTextColor = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(14)),
          child: const Center(child: Icon(Icons.history_rounded, color: Color(0xFFEF4444), size: 22)),
        ),
        title: Text(AppTranslations.tr(currentLanguage, 'upload_history'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.2)),
        subtitle: Text('${AppTranslations.tr(currentLanguage, 'history_subtitle')} ($framesCount)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: subTextColor)),
        trailing: Icon(Icons.chevron_right_rounded, color: isDark ? const Color(0xFF555555) : const Color(0xFFC7C7CC)),
      ),
    );
  }
}

class _ManageFramesCard extends StatelessWidget {
  final int framesCount;
  final bool isDark;
  final String currentLanguage;
  final VoidCallback onTap;

  const _ManageFramesCard({required this.framesCount, required this.isDark, required this.currentLanguage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final subTextColor = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(14)),
          child: const Center(child: Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444), size: 22)),
        ),
        title: Text(AppTranslations.tr(currentLanguage, 'manage_delete'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.2)),
        subtitle: Text('${AppTranslations.tr(currentLanguage, 'manage_subtitle')} ($framesCount)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: subTextColor)),
        trailing: Icon(Icons.chevron_right_rounded, color: isDark ? const Color(0xFF555555) : const Color(0xFFC7C7CC)),
      ),
    );
  }
}
