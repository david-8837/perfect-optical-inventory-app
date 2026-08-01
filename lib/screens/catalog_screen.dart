import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/frame_item.dart';
import '../widgets/product_card_widget.dart';
import '../utils/app_translations.dart';

class CategoryModel {
  final String title;
  final String description;
  final IconData icon;

  const CategoryModel({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class BrandModel {
  final String name;
  final String description;

  const BrandModel({
    required this.name,
    required this.description,
  });
}

class CatalogScreen extends StatefulWidget {
  final List<FrameItem> allFrames;
  final Function(FrameItem frame)? onSelectFrame;
  final String currentLanguage;

  const CatalogScreen({
    super.key,
    required this.allFrames,
    this.onSelectFrame,
    this.currentLanguage = 'English (US)',
  });

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String? _selectedCategory;
  String? _selectedBrand;

  static const List<CategoryModel> _categories = [
    CategoryModel(
      title: 'Rimless',
      description: 'Ultra-light frameless titanium spectacles',
      icon: Icons.light_mode_outlined,
    ),
    CategoryModel(
      title: 'Cat Eye',
      description: 'Fashion-forward elevated wing profiles',
      icon: Icons.auto_awesome_outlined,
    ),
    CategoryModel(
      title: 'Plastic Frame',
      description: 'Durable hand-polished Italian acetate',
      icon: Icons.layers_outlined,
    ),
    CategoryModel(
      title: 'Metal Frame',
      description: 'Precision thin-wire & gold titanium',
      icon: Icons.shield_outlined,
    ),
    CategoryModel(
      title: 'Half Frame',
      description: 'Minimalist top-rim optical frames',
      icon: Icons.remove_red_eye_outlined,
    ),
    CategoryModel(
      title: 'Sunglass',
      description: 'UV400 polarized designer sunwear',
      icon: Icons.workspace_premium_outlined,
    ),
  ];

  List<BrandModel> get _brands {
    final Set<String> brandNames = {};
    for (final f in widget.allFrames) {
      if (f.brand.trim().isNotEmpty &&
          (_selectedCategory == null || f.category.toLowerCase() == _selectedCategory!.toLowerCase())) {
        brandNames.add(f.brand.trim());
      }
    }
    if (brandNames.isEmpty) {
      for (final f in widget.allFrames) {
        if (f.brand.trim().isNotEmpty) brandNames.add(f.brand.trim());
      }
    }
    return brandNames
        .map((name) => BrandModel(name: name, description: 'Store eyewear collection'))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCategory == null) {
      return _buildCategoriesView();
    } else if (_selectedBrand == null) {
      return _buildBrandsView();
    } else {
      return _buildFramesView();
    }
  }

  // Level 0: Categories View
  Widget _buildCategoriesView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final subTextColor = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);

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
          Text(
            AppTranslations.tr(widget.currentLanguage, 'category'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppTranslations.tr(widget.currentLanguage, 'catalog_subtitle'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: subTextColor,
            ),
          ),
          const SizedBox(height: 24),
          ..._categories.map((cat) => _CategoryCard(
                category: cat,
                currentLanguage: widget.currentLanguage,
                onTap: () {
                  setState(() {
                    _selectedCategory = cat.title;
                    _selectedBrand = null;
                  });
                },
              )),
        ],
      ),
    );
  }

  // Level 1: Brands View
  Widget _buildBrandsView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final subTextColor = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        // Sleek Back Button
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1B20) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_rounded, size: 14, color: textColor),
                  const SizedBox(width: 6),
                  Text(
                    AppTranslations.tr(widget.currentLanguage, 'category'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        Text(
          AppTranslations.trCategory(widget.currentLanguage, _selectedCategory!),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose a brand for ${_selectedCategory!} eyewear',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: subTextColor,
          ),
        ),
        const SizedBox(height: 24),

        if (_brands.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.style_outlined, size: 48, color: subTextColor),
                const SizedBox(height: 12),
                Text(
                  'No Brands Added Yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add frames to your inventory to automatically populate your brand catalog.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: subTextColor),
                ),
              ],
            ),
          )
        else
          ..._brands.map((brand) {
            final count = widget.allFrames.where((f) {
              final catMatch =
                  f.category.toLowerCase() == _selectedCategory!.toLowerCase();
              final brandMatch =
                  f.brand.toLowerCase() == brand.name.toLowerCase();
              return catMatch && brandMatch;
            }).length;

            return _BrandCard(
              brand: brand,
              count: count,
              onTap: () {
                setState(() {
                  _selectedBrand = brand.name;
                });
              },
            );
          }),
      ],
    );
  }

  // Level 2: Product Grid View
  Widget _buildFramesView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final subTextColor = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);

    final matchingFrames = widget.allFrames.where((f) {
      final catMatch =
          f.category.toLowerCase() == _selectedCategory!.toLowerCase();
      final brandMatch =
          f.brand.toLowerCase() == _selectedBrand!.toLowerCase();
      return catMatch && brandMatch;
    }).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedBrand = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A1B20) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios_rounded, size: 14, color: textColor),
                            const SizedBox(width: 6),
                            Text(
                              _selectedCategory!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '${_selectedBrand!} - ${_selectedCategory!}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${matchingFrames.length} items available in inventory',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (matchingFrames.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: subTextColor),
                  const SizedBox(height: 16),
                  Text(
                    AppTranslations.tr(widget.currentLanguage, 'no_frames_found'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final frame = matchingFrames[index];
                  return ProductCardWidget(
                    frame: frame,
                    onTap: () {
                      if (widget.onSelectFrame != null) {
                        widget.onSelectFrame!(frame);
                      }
                    },
                  );
                },
                childCount: matchingFrames.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;
  final String currentLanguage;

  const _CategoryCard({
    required this.category,
    required this.onTap,
    this.currentLanguage = 'English (US)',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final subTextColor = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(
              category.icon,
              color: textColor,
              size: 24,
            ),
          ),
        ),
        title: Text(
          AppTranslations.trCategory(currentLanguage, category.title),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        subtitle: Text(
          category.description,
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

class _BrandCard extends StatelessWidget {
  final BrandModel brand;
  final int count;
  final VoidCallback onTap;

  const _BrandCard({
    required this.brand,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final subTextColor = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        title: Text(
          brand.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        subtitle: Text(
          brand.description,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: subTextColor,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '$count frames',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
