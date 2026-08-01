import 'package:flutter/material.dart';
import '../models/frame_item.dart';
import '../widgets/image_crop_rotate_editor_modal.dart';
import '../services/supabase_sync_service.dart';
import '../services/local_image_cache_service.dart';
import '../widgets/app_image_widget.dart';
import '../utils/app_image_picker.dart';
import '../widgets/sync_notification_toast.dart';

import '../widgets/upload_progress_modal.dart';

class ColorSwatchItem {
  final String name;
  final Color color;

  const ColorSwatchItem(this.name, this.color);
}

class AddFrameScreen extends StatefulWidget {
  final Function(FrameItem) onAddFrame;
  final List<FrameItem> recentFrames;

  const AddFrameScreen({
    super.key,
    required this.onAddFrame,
    this.recentFrames = const [],
  });

  @override
  State<AddFrameScreen> createState() => _AddFrameScreenState();
}

class _AddFrameScreenState extends State<AddFrameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedCategory = 'Plastic Frame';
  String _selectedBrand = 'Ray-Ban';
  String _selectedColor = 'Matte Black';

  final List<String> _categories = [
    'Plastic Frame',
    'Metal Frame',
    'Half Frame',
    'Sunglass',
    'Cat Eye',
  ];

  final List<String> _brands = [
    'Ray-Ban',
    'Oakley',
    'Gucci',
    'Prada',
    'Tom Ford',
    'Persol',
    'Vogue Eyewear',
  ];

  final List<ColorSwatchItem> _colorSwatches = [
    const ColorSwatchItem('Matte Black', Color(0xFF121212)),
    const ColorSwatchItem('Rose Gold', Color(0xFFB76E79)),
    const ColorSwatchItem('Tortoise', Color(0xFF8B4513)),
    const ColorSwatchItem('Gunmetal', Color(0xFF2A3439)),
    const ColorSwatchItem('Crystal Clear', Color(0xFF81D4FA)),
  ];

  final List<String> _photoUrls = [];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_photoUrls.isEmpty) {
      SyncToastController().showNotification(
        title: 'Photo Required',
        message: 'Please upload at least one frame photo',
        eventType: 'delete',
        icon: Icons.image_not_supported_rounded,
        accentColor: const Color(0xFFEF4444),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      final double price =
          double.tryParse(_priceController.text.trim()) ?? 195.0;
      final String frameName = _nameController.text.trim();
      final String brand = _selectedBrand;
      final String firstPhoto = _photoUrls.firstWhere(
        (p) => p.trim().isNotEmpty,
        orElse: () => '',
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => UploadProgressModal(
          frameName: frameName,
          brand: brand,
          price: price,
          imagePath: firstPhoto,
          uploadTask: () async {
            final List<String> finalImagePaths = [];
            for (final rawPath in _photoUrls) {
              if (rawPath.trim().isEmpty) continue;
              String processedPath = rawPath;
              if (processedPath.startsWith('data:image')) {
                final cdnUrl = await SupabaseSyncService()
                    .uploadDataUriToStorage(processedPath);
                if (cdnUrl != null && cdnUrl.isNotEmpty) {
                  processedPath = cdnUrl;
                }
              }
              await LocalImageCacheService()
                  .cacheImageData(imagePathOrUrl: processedPath);
              finalImagePaths.add(processedPath);
            }

            final newFrame = FrameItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: frameName,
              brand: brand,
              category: _selectedCategory,
              price: price,
              color: _selectedColor,
              imagePath:
                  finalImagePaths.isNotEmpty ? finalImagePaths.first : '',
              imagePaths: finalImagePaths,
              rating: 5.0,
              reviewCount: 1,
            );

            widget.onAddFrame(newFrame);
            await SupabaseSyncService()
                .broadcastAction(action: 'add', frame: newFrame);
            return newFrame;
          },
          onSuccess: (savedFrame) {
            if (mounted) {
              setState(() {
                _nameController.clear();
                _priceController.clear();
                _photoUrls.clear();
              });
              SyncToastController().showNotification(
                title: 'Frame Added',
                message:
                    'Successfully added "${savedFrame.name}" to inventory',
                eventType: 'add',
                icon: Icons.check_circle_outline_rounded,
                accentColor: const Color(0xFF10B981),
              );
            }
          },
        ),
      );
    }
  }

  void _openAddCustomColorDialog() {
    Color selectedColorVal = const Color(0xFFB76E79); // Default Rose Gold
    final textCtrl = TextEditingController(text: 'Rose Gold');
    double sliderPercent = 0.05; // 0.0 to 1.0 position on rainbow bar

    final List<Map<String, dynamic>> palette = [
      {'name': 'Rose Gold', 'color': const Color(0xFFB76E79)},
      {'name': 'Champagne', 'color': const Color(0xFFF7E7CE)},
      {'name': 'Amber Gold', 'color': const Color(0xFFFFBF00)},
      {'name': 'Tortoise', 'color': const Color(0xFF8B4513)},
      {'name': 'Espresso', 'color': const Color(0xFF362819)},
      {'name': 'Havana', 'color': const Color(0xFF6E473B)},
      {'name': 'Gunmetal', 'color': const Color(0xFF2A3439)},
      {'name': 'Titanium', 'color': const Color(0xFF5A6577)},
      {'name': 'Platinum', 'color': const Color(0xFFE5E4E2)},
      {'name': 'Matte Black', 'color': const Color(0xFF121212)},
      {'name': 'Obsidian', 'color': const Color(0xFF0B0B0C)},
      {'name': 'Crystal Clear', 'color': const Color(0xFF81D4FA)},
      {'name': 'Sapphire Blue', 'color': const Color(0xFF0F4C81)},
      {'name': 'Midnight Blue', 'color': const Color(0xFF1B365D)},
      {'name': 'Ocean Teal', 'color': const Color(0xFF008080)},
      {'name': 'Emerald Green', 'color': const Color(0xFF50C878)},
      {'name': 'Olive Green', 'color': const Color(0xFF556B2F)},
      {'name': 'Ruby Red', 'color': const Color(0xFFE0115F)},
      {'name': 'Crimson Red', 'color': const Color(0xFFE53935)},
      {'name': 'Coral Pink', 'color': const Color(0xFFFF6F61)},
      {'name': 'Hot Pink', 'color': const Color(0xFFFF69B4)},
      {'name': 'Deep Purple', 'color': const Color(0xFF4B0082)},
      {'name': 'Lavender', 'color': const Color(0xFFE6E6FA)},
      {'name': 'Copper Bronze', 'color': const Color(0xFFB87333)},
    ];

    String autoDetectColorName(Color c) {
      for (final item in palette) {
        if ((item['color'] as Color).value == c.value) {
          return item['name'];
        }
      }
      final hsv = HSVColor.fromColor(c);
      final hue = hsv.hue;
      final sat = hsv.saturation;
      final val = hsv.value;

      if (val < 0.20) return 'Matte Black';
      if (sat < 0.15 && val > 0.85) return 'Crystal Clear';
      if (sat < 0.15) return 'Platinum Silver';

      if (hue >= 345 || hue < 15) {
        return sat > 0.7 ? 'Ruby Red' : 'Rose Gold';
      } else if (hue >= 15 && hue < 40) {
        return sat < 0.6 ? 'Rose Gold' : 'Amber Orange';
      } else if (hue >= 40 && hue < 70) {
        return 'Amber Gold';
      } else if (hue >= 70 && hue < 165) {
        return 'Emerald Green';
      } else if (hue >= 165 && hue < 200) {
        return 'Ocean Teal';
      } else if (hue >= 200 && hue < 260) {
        return 'Sapphire Blue';
      } else if (hue >= 260 && hue < 315) {
        return 'Deep Purple';
      } else {
        return 'Hot Pink';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          void updateFromRainbowPosition(Offset localPos, double width) {
            final double clampedX = localPos.dx.clamp(0.0, width);
            final double pct = width > 0 ? (clampedX / width) : 0.0;
            final double hue = pct * 360.0;
            final newColor =
                HSVColor.fromAHSV(1.0, hue.clamp(0.0, 360.0), 0.85, 0.95)
                    .toColor();
            setSheetState(() {
              sliderPercent = pct;
              selectedColorVal = newColor;
              textCtrl.text = autoDetectColorName(newColor);
            });
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1B20) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Drag Handle Bar
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Icon(Icons.palette_rounded,
                                  color: Color(0xFFE53935), size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Full Color Spectrum Studio',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF121212),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Slide across rainbow or tap color swatches below',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF8E8E93)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey.withOpacity(0.15), height: 1),
                  const SizedBox(height: 16),

                  // Rainbow Spectrum Slider Label
                  const Text(
                    'SLIDE FULL RAINBOW SPECTRUM',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8E8E93),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Interactive Rainbow Bar with Thumb Indicator
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = constraints.maxWidth;
                      final thumbX = (sliderPercent * barWidth)
                          .clamp(14.0, barWidth - 14.0);

                      return GestureDetector(
                        onPanDown: (d) =>
                            updateFromRainbowPosition(d.localPosition, barWidth),
                        onPanUpdate: (d) =>
                            updateFromRainbowPosition(d.localPosition, barWidth),
                        child: Container(
                          height: 42,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(21),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF0000), // Red
                                Color(0xFFFF7F00), // Orange
                                Color(0xFFFFFF00), // Yellow
                                Color(0xFF00FF00), // Green
                                Color(0xFF00FFFF), // Cyan
                                Color(0xFF0000FF), // Blue
                                Color(0xFF8B00FF), // Violet
                                Color(0xFFFF007F), // Pink
                                Color(0xFFFF0000), // Red
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: thumbX - 14,
                                top: 7,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: selectedColorVal,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.35),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Preset Color Swatches Matrix
                  const Text(
                    'EYEWEAR COLOR MATRIX',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8E8E93),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: palette.map((item) {
                          final Color c = item['color'];
                          final String name = item['name'];
                          final isSel = selectedColorVal.value == c.value;

                          return GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                selectedColorVal = c;
                                textCtrl.text = name;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSel
                                      ? const Color(0xFF121212)
                                      : Colors.white,
                                  width: isSel ? 3 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.withOpacity(0.30),
                                    blurRadius: isSel ? 8 : 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isSel
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Auto Color Name & Display Tag
                  const Text(
                    'AUTO-DETECTED COLOR NAME',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8E8E93),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textCtrl,
                    decoration: InputDecoration(
                      hintText: 'Color shade name auto-detects',
                      filled: true,
                      fillColor: const Color(0xFFF5F6F8),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: selectedColorVal,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.8), width: 1),
                          ),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Add Color Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final val = textCtrl.text.trim();
                        if (val.isNotEmpty) {
                          setState(() {
                            _colorSwatches
                                .add(ColorSwatchItem(val, selectedColorVal));
                            _selectedColor = val;
                          });
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF121212),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add Color Swatch to Frame',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAddBrandDialog() {
    final textCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1B20) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Drag Handle Bar
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

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Icon(Icons.style_rounded,
                                color: isDark ? Colors.white : const Color(0xFF121212), size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Brand',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF121212),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Enter new company brand name for inventory',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close_rounded,
                          color: isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.withOpacity(0.15), height: 1),
                const SizedBox(height: 16),

                TextField(
                  controller: textCtrl,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF121212),
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Oliver Peoples or Prada',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF666666) : const Color(0xFFB0B0B0),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      final val = textCtrl.text.trim();
                      if (val.isNotEmpty) {
                        setState(() {
                          _brands.add(val);
                          _selectedBrand = val;
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : const Color(0xFF121212),
                      foregroundColor: isDark ? const Color(0xFF121212) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Add Brand',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategoryPickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF1A1B20) : Colors.white;
        final txt = isDark ? Colors.white : const Color(0xFF121212);
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
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.layers_outlined,
                          color: txt, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Select Category Style',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: txt,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close_rounded,
                        color: isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.withOpacity(0.15), height: 1),
              const SizedBox(height: 14),
              ..._categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? (isDark ? Colors.white : const Color(0xFF121212)) : optionBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? (isDark ? const Color(0xFF121212) : Colors.white)
                                : txt,
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded,
                              color: isDark ? const Color(0xFF121212) : Colors.white, size: 20),
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

  void _showBrandPickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF1A1B20) : Colors.white;
        final txt = isDark ? Colors.white : const Color(0xFF121212);
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
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.style_rounded,
                          color: txt, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Select Company Brand',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: txt,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close_rounded,
                        color: isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.withOpacity(0.15), height: 1),
              const SizedBox(height: 14),
              ..._brands.map((brand) {
                final isSelected = _selectedBrand == brand;
                return Dismissible(
                  key: ValueKey('brand_sheet_$brand'),
                  direction: DismissDirection.endToStart,
                  dismissThresholds: const {
                    DismissDirection.endToStart: 0.95,
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'SLIDE FULL TO DELETE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.delete_forever_rounded,
                            color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                  onDismissed: (direction) {
                    setState(() {
                      _brands.remove(brand);
                      if (_selectedBrand == brand) {
                        _selectedBrand = _brands.isNotEmpty ? _brands.first : '';
                      }
                    });
                    SyncToastController().showNotification(
                      title: 'Brand Removed',
                      message: 'Deleted "$brand" from company brands',
                      eventType: 'delete',
                      icon: Icons.delete_sweep_rounded,
                      accentColor: const Color(0xFFEF4444),
                    );
                  },
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedBrand = brand);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? (isDark ? Colors.white : const Color(0xFF121212)) : optionBg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            brand,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? (isDark ? const Color(0xFF121212) : Colors.white)
                                  : txt,
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: isDark ? const Color(0xFF121212) : Colors.white, size: 20),
                        ],
                      ),
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

  void _openCropEditorForUrl(String url, int slotIndex) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ImageCropRotateEditorModal(
        imageProviderUrl: url,
        onCropSaved: (finalUrl) {
          if (mounted) {
            setState(() {
              while (_photoUrls.length <= slotIndex) {
                _photoUrls.add('');
              }
              _photoUrls[slotIndex] = finalUrl;
            });
            SyncToastController().showNotification(
              title: 'Crop Applied',
              message: 'Frame photo ready to save',
              eventType: 'image',
              icon: Icons.crop_rounded,
              accentColor: const Color(0xFF10B981),
            );
          }
        },
      ),
    );
  }

  // Opens Native Device File Picker from local device / phone gallery
  Future<void> _pickRealImageFromDevice(int slotIndex) async {
    final dataUri = await AppImagePicker.pickImageAsDataUri();
    if (dataUri != null && mounted) {
      _openCropEditorForUrl(dataUri, slotIndex);
    }
  }

  void _pickPhotoForSlot(int slotIndex) {
    _pickRealImageFromDevice(slotIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final subTextColor = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);
    final dropdownBg = isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8);
    final btnBg = isDark ? Colors.white : const Color(0xFF121212);
    final btnFg = isDark ? const Color(0xFF121212) : Colors.white;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Subtitle
          Text(
            'Add New Frame',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Upload real frame photos from device & fill product details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: subTextColor,
            ),
          ),
          const SizedBox(height: 24),

          // Main Form Card
          Container(
            padding: const EdgeInsets.all(22.0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              border: isDark
                  ? Border.all(color: Colors.white.withOpacity(0.06), width: 1)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.30 : 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Frame Name
                  _buildSectionHeader('FRAME MODEL NAME', context),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: _buildInputDecoration(
                        'e.g. Classic Wayfarer Titanium', context),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter frame name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 2. Photos Upload Section (Real Device Upload)
                  _buildSectionHeader(
                      'REAL FRAME PHOTOS (TAP TO UPLOAD FROM DEVICE & CROP)', context),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPhotoBoxSlot('Front Angle', 0, context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPhotoBoxSlot('Side Angle', 1, context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPhotoBoxSlot('Detail Angle', 2, context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 3. Category Selector
                  _buildSectionHeader('CATEGORY STYLE', context),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showCategoryPickerSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: dropdownBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCategory,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              color: textColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Company Brand Selector & Custom Add
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('COMPANY BRAND', context),
                      GestureDetector(
                        onTap: _openAddBrandDialog,
                        child: const Row(
                          children: [
                            Icon(Icons.add,
                                size: 14, color: Color(0xFFE53935)),
                            SizedBox(width: 2),
                            Text(
                              'New Brand',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showBrandPickerSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: dropdownBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedBrand,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              color: textColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Price Input
                  _buildSectionHeader('PRICE (₹)', context),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _buildInputDecoration('e.g. 195.00', context),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter price';
                      }
                      if (double.tryParse(val.trim()) == null) {
                        return 'Please enter valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 6. Frame Color Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('FRAME COLOR', context),
                      GestureDetector(
                        onTap: _openAddCustomColorDialog,
                        child: const Row(
                          children: [
                            Icon(Icons.add,
                                size: 14, color: Color(0xFFE53935)),
                            SizedBox(width: 2),
                            Text(
                              'Custom Color',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _colorSwatches.map((item) {
                      return _buildColorSwatch(item.name, item.color, context);
                    }).toList(),
                  ),
                  const SizedBox(height: 30),

                  // 7. Submit Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnBg,
                        foregroundColor: btnFg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Upload & Save to Inventory',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Recently Uploaded Section
          if (widget.recentFrames.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENTLY UPLOADED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: subTextColor,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '${widget.recentFrames.length} items',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...widget.recentFrames.take(3).map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.20 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: dropdownBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AppImageWidget(
                            imagePath: item.imagePath,
                            fit: BoxFit.cover,
                            iconSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.brand} • ${item.category}',
                              style: TextStyle(
                                fontSize: 12,
                                color: subTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1B382B)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Active ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            Icon(Icons.circle,
                                size: 8, color: Color(0xFF4CAF50)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: isDark ? const Color(0xFFA0A0A5) : const Color(0xFF9E9E9E),
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isDark ? const Color(0xFF666666) : const Color(0xFFB0B0B0),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildPhotoBoxSlot(String label, int index, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = _photoUrls.length > index && _photoUrls[index].isNotEmpty;
    final imageUrl = hasImage ? _photoUrls[index] : null;

    final boxBg = isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8);
    final borderColor = hasImage
        ? (isDark ? Colors.white : const Color(0xFF121212))
        : (isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFE0E0E0));
    final iconColor = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF9E9E9E);
    final subColor = isDark ? const Color(0xFF666666) : const Color(0xFFBBBBBB);

    return GestureDetector(
      onTap: () => _pickPhotoForSlot(index),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: boxBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: hasImage ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              if (hasImage && imageUrl != null)
                Positioned.fill(
                  child: AppImageWidget(
                    imagePath: imageUrl,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded,
                          color: iconColor, size: 28),
                      const SizedBox(height: 4),
                      Text(label,
                          style: TextStyle(
                              fontSize: 10, color: iconColor)),
                      const SizedBox(height: 2),
                      Text('Tap to upload',
                          style: TextStyle(
                              fontSize: 9, color: subColor)),
                    ],
                  ),
                ),
              if (hasImage)
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_photoUrls.length > index) {
                          _photoUrls.removeAt(index);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSwatch(String name, Color color, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedColor == name;

    final bg = isSelected
        ? (isDark ? Colors.white : const Color(0xFF121212))
        : (isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8));

    final txtColor = isSelected
        ? (isDark ? const Color(0xFF121212) : Colors.white)
        : (isDark ? Colors.white : const Color(0xFF121212));

    return GestureDetector(
      onTap: () => setState(() => _selectedColor = name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 6, backgroundColor: color),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: txtColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
