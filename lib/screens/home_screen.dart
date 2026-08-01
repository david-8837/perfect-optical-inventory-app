import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/frame_item.dart';
import '../utils/app_translations.dart';
import '../widgets/header_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/category_arc_selector.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/empty_inventory_widget.dart';
import '../widgets/floating_bottom_nav.dart';
import '../widgets/frame_detail_drawer_widget.dart';
import 'add_frame_screen.dart';
import 'catalog_screen.dart';
import 'inventory_hub_screen.dart';
import '../widgets/shimmer_loading.dart';
import '../services/local_database_service.dart';
import '../services/supabase_sync_service.dart';

import '../widgets/sync_notification_toast.dart';

class HomeScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final String currentLanguage;
  final Function(String themeStr) onThemeChanged;
  final Function(String lang) onLanguageChanged;
  final VoidCallback? onLogout;

  const HomeScreen({
    super.key,
    this.currentThemeMode = ThemeMode.light,
    this.currentLanguage = 'English (US)',
    required this.onThemeChanged,
    required this.onLanguageChanged,
    this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedSort = 'New to Old';
  String _activeTab = 'home';
  String _searchQuery = '';

  final LocalDatabaseService _localDb = LocalDatabaseService();
  late StreamSubscription<SyncEventNotification> _notifSubscription;

  List<FrameItem> get _allFrames => _localDb.frames;
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _localDb.addListener(_onDbChanged);
    _notifSubscription = SyncToastController().eventStream.listen((_) {
      if (mounted) setState(() {});
    });
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _onDbChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _localDb.removeListener(_onDbChanged);
    _notifSubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _addNewFrame(FrameItem newFrame) {
    _localDb.saveFrame(newFrame);
  }

  List<FrameItem> get _filteredFrames {
    final list = List<FrameItem>.from(_allFrames).where((frame) {
      final matchesCategory = _selectedCategory == 'All' ||
          frame.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          frame.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          frame.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          frame.color.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    if (_selectedSort == 'Low to High') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedSort == 'High to Low') {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else if (_selectedSort == 'New to Old') {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_selectedSort == 'Old to New') {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return list;
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    await SupabaseSyncService().syncWithCloud();
    if (mounted) {
      setState(() => _isLoading = false);
      SyncToastController().showNotification(
        title: 'Inventory Synchronized',
        message: 'Successfully pulled latest store data from Supabase Cloud',
        eventType: 'sync',
        icon: Icons.sync_rounded,
        accentColor: const Color(0xFF00BFA5),
      );
    }
  }

  void _switchTab(String tab) {
    HapticFeedback.lightImpact();
    setState(() {
      _activeTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayedFrames = _filteredFrames;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F0F12) : const Color(0xFFF7F8FA);
    final headerTextColor = isDark ? Colors.white : const Color(0xFF8E8E93);
    final lang = widget.currentLanguage;

    Widget activeContent;
    if (_activeTab == 'add') {
      activeContent = AddFrameScreen(
        onAddFrame: _addNewFrame,
        recentFrames: _allFrames,
      );
    } else if (_activeTab == 'catalog') {
      activeContent = CatalogScreen(
        allFrames: _allFrames,
        currentLanguage: lang,
        onSelectFrame: _showFrameDetailsModal,
      );
    } else if (_activeTab == 'store') {
      activeContent = InventoryHubScreen(
        frames: _allFrames,
        currentThemeMode: widget.currentThemeMode,
        currentLanguage: widget.currentLanguage,
        onThemeChanged: widget.onThemeChanged,
        onLanguageChanged: widget.onLanguageChanged,
        onDeleteFrame: (frameId) {
          final existing = _localDb.getFrameById(frameId);
          if (existing != null) {
            SupabaseSyncService().broadcastAction(action: 'delete', frame: existing);
          }
        },
      );
    } else {
      activeContent = RefreshIndicator(
        onRefresh: _handleRefresh,
        color: isDark ? Colors.white : const Color(0xFF121212),
        backgroundColor: isDark ? const Color(0xFF1A1B20) : Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Top Header & Search Bar Section
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeaderWidget(
                    currentLanguage: lang,
                    hasUnread: SyncToastController().hasUnread,
                    onNotificationTap: _openNotificationDrawer,
                  ),
                  SearchBarWidget(
                    controller: _searchController,
                    currentLanguage: lang,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    onFilterTap: _openFilterDrawer,
                  ),
                ],
              ),
            ),

            // Single Shared Morphing Category Header
            SliverPersistentHeader(
              pinned: true,
              delegate: MorphingCategoryHeaderDelegate(
                selectedCategory: _selectedCategory,
                currentLanguage: lang,
                onSelectCategory: (cat) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
              ),
            ),

            // Featured Eyewear Title Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Text(
                  '${AppTranslations.tr(lang, 'featured_eyewear')} (${displayedFrames.length})',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: headerTextColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),

            // Product Grid or Empty State
            if (displayedFrames.isEmpty)
              SliverToBoxAdapter(
                child: EmptyInventoryWidget(
                  searchQuery: _searchQuery,
                  onClearSearchTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  onSuggestionTap: (term) {
                    _searchController.text = term;
                    setState(() {
                      _searchQuery = term;
                    });
                  },
                  onAddFrameTap: () {
                    setState(() {
                      _activeTab = 'add';
                    });
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final frame = displayedFrames[index];
                      return ProductCardWidget(
                        frame: frame,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showFrameDetailsModal(frame);
                        },
                      );
                    },
                    childCount: displayedFrames.length,
                  ),
                ),
              ),

            // Bottom Spacing for Floating Nav Bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 110),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Body Content with Shimmer Skeleton CrossFade Switcher & Smooth Page Transitions
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 350),
              crossFadeState: (_activeTab == 'home' && _isLoading)
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: const HomeScreenSkeleton(),
              secondChild: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<String>(_activeTab),
                  child: activeContent,
                ),
              ),
            ),

            // Floating Dark Glassmorphic Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingBottomNav(
                activeTab: _activeTab,
                currentLanguage: widget.currentLanguage,
                onTabChanged: _switchTab,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Slide Up Bottom Sheet for Frame Details
  void _showFrameDetailsModal(FrameItem frame) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (context) => FrameDetailDrawerWidget(
        frame: frame,
        onEdit: (updated) {
          _localDb.saveFrame(updated, markPending: true);
          SyncToastController().showNotification(
            title: 'Frame Updated',
            message: 'Updated "${updated.name}" details',
            eventType: 'edit',
            icon: Icons.edit_note_rounded,
            accentColor: const Color(0xFF10B981),
          );
        },
        onDelete: () {
          _localDb.deleteFrame(frame.id, markPending: true);
          SyncToastController().showNotification(
            title: 'Frame Deleted',
            message: 'Deleted "${frame.name}" from inventory',
            eventType: 'delete',
            icon: Icons.delete_forever_rounded,
            accentColor: const Color(0xFFEF4444),
          );
        },
      ),
    );
  }

  // Slide Up Bottom Sheet for Filter & Sort
  void _openFilterDrawer() {
    String tempCategory = _selectedCategory;
    String tempSort = _selectedSort;
    final lang = widget.currentLanguage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? const Color(0xFF1A1B20) : Colors.white;
            final txt = isDark ? Colors.white : const Color(0xFF121212);
            final subTxt = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);
            final chipBg = isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8);

            final filteredCount = _allFrames.where((f) {
              final catMatch = tempCategory == 'All' ||
                  f.category.toLowerCase() == tempCategory.toLowerCase();
              return catMatch;
            }).length;

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
                  // Drag handle bar
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
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: txt,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.tr(lang, 'filter_sort'),
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: txt,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$filteredCount items match active criteria',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subTxt,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setModalState(() {
                            tempCategory = 'All';
                            tempSort = 'New to Old';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            AppTranslations.tr(lang, 'reset_all'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: txt,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Category Filter Title
                  Text(
                    AppTranslations.tr(lang, 'frame_category'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: subTxt,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Category Choice Chips Grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'All',
                      'Plastic Frame',
                      'Metal Frame',
                      'Half Frame',
                      'Sunglass',
                    ].map((cat) {
                      final isSelected = tempCategory == cat;
                      final catLabel = AppTranslations.trCategory(lang, cat);
                      return ChoiceChip(
                        label: Text(catLabel),
                        selected: isSelected,
                        selectedColor: isDark ? Colors.white : const Color(0xFF121212),
                        backgroundColor: chipBg,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? const Color(0xFF121212) : Colors.white)
                              : txt,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide.none,
                        ),
                        showCheckmark: false,
                        onSelected: (selected) {
                          if (selected) {
                            HapticFeedback.selectionClick();
                            setModalState(() {
                              tempCategory = cat;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Sort Option Title
                  Text(
                    AppTranslations.tr(lang, 'sort_order'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: subTxt,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Sort Choice Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      {'key': 'New to Old', 'trKey': 'new_to_old'},
                      {'key': 'Old to New', 'trKey': 'old_to_new'},
                      {'key': 'Low to High', 'trKey': 'low_to_high'},
                      {'key': 'High to Low', 'trKey': 'high_to_low'},
                    ].map((sortItem) {
                      final sortKey = sortItem['key']!;
                      final isSelected = tempSort == sortKey;
                      final label = AppTranslations.tr(lang, sortItem['trKey']!);
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: isDark ? Colors.white : const Color(0xFF121212),
                        backgroundColor: chipBg,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? const Color(0xFF121212) : Colors.white)
                              : txt,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide.none,
                        ),
                        showCheckmark: false,
                        onSelected: (selected) {
                          if (selected) {
                            HapticFeedback.selectionClick();
                            setModalState(() {
                              tempSort = sortKey;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Apply Filter Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _selectedCategory = tempCategory;
                          _selectedSort = tempSort;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : const Color(0xFF121212),
                        foregroundColor: isDark ? const Color(0xFF121212) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '${AppTranslations.tr(lang, 'apply_filters')} ($filteredCount)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Slide Up Bottom Sheet for Activity Notifications
  void _openNotificationDrawer() {
    final lang = widget.currentLanguage;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDrawerState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? const Color(0xFF1A1B20) : Colors.white;
            final txt = isDark ? Colors.white : const Color(0xFF121212);
            final subTxt = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);
            final realHistory = SyncToastController().history;
            final unreadCount = SyncToastController().unreadCount;

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
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.notifications_active_rounded,
                                size: 18,
                                color: txt,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.tr(lang, 'activity_notifications'),
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: txt,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$unreadCount ${AppTranslations.tr(lang, 'unread_updates')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subTxt,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (unreadCount > 0)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            SyncToastController().markAllRead();
                            setDrawerState(() {});
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              AppTranslations.tr(lang, 'mark_read'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: txt,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.withOpacity(0.15), height: 1),
                  const SizedBox(height: 12),

                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: realHistory.isEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: 42,
                                    color: subTxt.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No Activity Notifications',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: txt,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Real-time inventory changes, additions, stock edits, and cloud database sync updates will appear here live.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subTxt,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: realHistory.map((item) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: item.isUnread
                                        ? (isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8))
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: item.accentColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Icon(item.icon, color: item.accentColor, size: 20),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.title,
                                                    style: TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight: FontWeight.w800,
                                                      color: txt,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  item.timeAgo,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: subTxt,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.message,
                                              style: TextStyle(
                                                fontSize: 12,
                                                height: 1.4,
                                                color: subTxt,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ),

                  if (realHistory.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          SyncToastController().markAllRead();
                          setDrawerState(() {});
                          setState(() {});
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: Text(
                          AppTranslations.tr(lang, 'mark_read'),
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : const Color(0xFF121212),
                          foregroundColor: isDark ? const Color(0xFF121212) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
