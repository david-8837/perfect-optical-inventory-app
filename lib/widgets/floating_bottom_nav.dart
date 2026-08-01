import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/app_translations.dart';

class NavItemData {
  final String id;
  final String labelKey;
  final IconData icon;

  const NavItemData({
    required this.id,
    required this.labelKey,
    required this.icon,
  });
}

class FloatingBottomNav extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChanged;
  final String currentLanguage;

  const FloatingBottomNav({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    this.currentLanguage = 'English (US)',
  });

  static const List<NavItemData> _items = [
    NavItemData(id: 'home', labelKey: 'home', icon: Icons.home_rounded),
    NavItemData(id: 'catalog', labelKey: 'category', icon: Icons.grid_view_rounded),
    NavItemData(
      id: 'add',
      labelKey: 'add_frame',
      icon: Icons.add_circle_outline_rounded,
    ),
    NavItemData(id: 'store', labelKey: 'hub', icon: Icons.domain_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(29),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 325),
              height: 58,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2023).withOpacity(0.96),
                borderRadius: BorderRadius.circular(29),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 32,
                    spreadRadius: 1,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _items.map((item) {
                  final isActive = activeTab == item.id;
                  return _NavBarItem(
                    item: item,
                    isActive: isActive,
                    currentLanguage: currentLanguage,
                    onTap: () => onTabChanged(item.id),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  final NavItemData item;
  final bool isActive;
  final String currentLanguage;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isActive,
    this.currentLanguage = 'English (US)',
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.fastOutSlowIn,
          height: 46,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isActive ? 16 : 11,
          ),
          decoration: BoxDecoration(
            color: widget.isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(23),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: Icon(
                  widget.item.icon,
                  key: ValueKey('${widget.item.id}_${widget.isActive}'),
                  size: widget.isActive ? 20 : 22,
                  color: widget.isActive
                      ? const Color(0xFF1C1C1E)
                      : const Color(0xFF8E8E93),
                ),
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastOutSlowIn,
                  alignment: Alignment.centerLeft,
                  child: widget.isActive
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 6),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              opacity: widget.isActive ? 1.0 : 0.0,
                              child: Text(
                                AppTranslations.tr(
                                    widget.currentLanguage, widget.item.labelKey),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: const TextStyle(
                                  color: Color(0xFF1C1C1E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
