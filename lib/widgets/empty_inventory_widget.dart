import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'custom_glasses_painter.dart';

class EmptyInventoryWidget extends StatelessWidget {
  final VoidCallback onAddFrameTap;
  final String searchQuery;
  final VoidCallback? onClearSearchTap;
  final ValueChanged<String>? onSuggestionTap;

  const EmptyInventoryWidget({
    super.key,
    required this.onAddFrameTap,
    this.searchQuery = '',
    this.onClearSearchTap,
    this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSearching = searchQuery.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 36.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular Red Glasses Container
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: isSearching
                  ? const Icon(
                      Icons.search_off_rounded,
                      color: Color(0xFFDC2626),
                      size: 44,
                    )
                  : const CustomGlassesIcon(
                      color: Color(0xFFDC2626),
                      size: 48,
                      strokeWidth: 3.2,
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            isSearching ? 'No Frames Found' : 'Your Inventory is Empty',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF121212),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          // Subtitle
          Text(
            isSearching
                ? 'We couldn\'t find any eyewear models matching "$searchQuery". Try checking spelling or search a different brand.'
                : 'Start building your optical catalog by adding your first frame.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8E8E93),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),

          if (isSearching) ...[
            // Popular Suggestions Header
            const Text(
              'POPULAR SUGGESTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8E8E93),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                'Ray-Ban',
                'Plastic Frame',
                'Metal Frame',
                'Cat Eye',
                'Gold',
                'Black'
              ].map((term) {
                return ActionChip(
                  label: Text(term),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF121212),
                  ),
                  backgroundColor: Colors.white,
                  elevation: 0,
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (onSuggestionTap != null) onSuggestionTap!(term);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (onClearSearchTap != null) onClearSearchTap!();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Clear Search',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // "Add First Frame" Pill Button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onAddFrameTap();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'Add First Frame',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF121212),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
