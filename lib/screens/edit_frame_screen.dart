import 'package:flutter/material.dart';
import '../models/frame_item.dart';
import '../services/supabase_sync_service.dart';
import '../services/local_database_service.dart';
import '../widgets/app_image_widget.dart';
import '../widgets/upload_progress_modal.dart';
import '../widgets/sync_notification_toast.dart';

class EditFrameScreen extends StatefulWidget {
  final FrameItem frame;
  final Function(FrameItem updatedFrame) onSave;

  const EditFrameScreen({
    super.key,
    required this.frame,
    required this.onSave,
  });

  @override
  State<EditFrameScreen> createState() => _EditFrameScreenState();
}

class _EditFrameScreenState extends State<EditFrameScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _boxCtrl;
  late TextEditingController _vendorCtrl;
  late String _selectedBrand;
  late String _selectedCategory;
  late String _selectedColor;
  late int _stockCount;

  final List<String> _categories = [
    'Plastic Frame',
    'Metal Frame',
    'Half Frame',
    'Sunglass',
    'Cat Eye',
  ];

  final List<String> _brands = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.frame.name);
    _priceCtrl = TextEditingController(text: widget.frame.price.toString());
    _boxCtrl = TextEditingController(text: widget.frame.boxNumber);
    _vendorCtrl = TextEditingController(text: widget.frame.vendor);
    _selectedBrand = widget.frame.brand;
    _selectedCategory = widget.frame.category;
    _selectedColor = widget.frame.color;
    _stockCount = widget.frame.stockCount;

    final existing = LocalDatabaseService().frames.map((f) => f.brand.trim()).where((b) => b.isNotEmpty).toSet();
    if (widget.frame.brand.isNotEmpty) existing.add(widget.frame.brand);
    _brands.addAll(existing);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _boxCtrl.dispose();
    _vendorCtrl.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final double price = double.tryParse(_priceCtrl.text.trim()) ?? widget.frame.price;

    final updated = widget.frame.copyWith(
      name: _nameCtrl.text.trim(),
      brand: _selectedBrand,
      category: _selectedCategory,
      price: price,
      color: _selectedColor,
      stockCount: _stockCount,
      boxNumber: _boxCtrl.text.trim(),
      vendor: _vendorCtrl.text.trim(),
      isPendingSync: true,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UploadProgressModal(
        frameName: updated.name,
        brand: updated.brand,
        price: updated.price,
        imagePath: updated.imagePath,
        isEditMode: true,
        uploadTask: () async {
          LocalDatabaseService().saveFrame(updated, markPending: true);
          widget.onSave(updated);
          await SupabaseSyncService().broadcastAction(action: 'edit', frame: updated);
          return updated;
        },
        onSuccess: (savedFrame) {
          SyncToastController().showNotification(
            title: 'Eyewear Updated',
            message: 'Successfully updated "${savedFrame.name}" details',
            eventType: 'edit',
            icon: Icons.edit_note_rounded,
            accentColor: const Color(0xFF10B981),
          );
          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F12) : const Color(0xFFFFFFFF);
    final cardBg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF121212);
    final subTxt = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);
    final inputBg = isDark ? const Color(0xFF282A32) : const Color(0xFFF5F6F8);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: txt, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Eyewear Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: txt),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Preview Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(16)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AppImageWidget(
                        imagePath: widget.frame.imagePath,
                        fit: BoxFit.cover,
                        iconSize: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_nameCtrl.text.isEmpty ? 'Frame Name' : _nameCtrl.text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: txt)),
                        const SizedBox(height: 2),
                        Text('$_selectedBrand • $_selectedCategory', style: TextStyle(fontSize: 12, color: subTxt)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form Fields Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Model Name
                  _buildLabel('FRAME MODEL NAME', subTxt),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    style: TextStyle(color: txt, fontWeight: FontWeight.w600),
                    decoration: _buildInputDeco('Enter model name', inputBg, subTxt),
                  ),
                  const SizedBox(height: 16),

                  // 2. Price & Stock
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('PRICE (₹)', subTxt),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _priceCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: txt, fontWeight: FontWeight.w600),
                              decoration: _buildInputDeco('195.00', inputBg, subTxt),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('STOCK COUNT', subTxt),
                            const SizedBox(height: 6),
                            Container(
                              height: 52,
                              decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(16)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove_rounded, color: txt, size: 18),
                                    onPressed: () {
                                      if (_stockCount > 0) setState(() => _stockCount--);
                                    },
                                  ),
                                  Text('$_stockCount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: txt)),
                                  IconButton(
                                    icon: Icon(Icons.add_rounded, color: txt, size: 18),
                                    onPressed: () => setState(() => _stockCount++),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Box Number & Vendor
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('BOX NUMBER', subTxt),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _boxCtrl,
                              style: TextStyle(color: txt, fontWeight: FontWeight.w600),
                              decoration: _buildInputDeco('BOX-01', inputBg, subTxt),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('VENDOR', subTxt),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _vendorCtrl,
                              style: TextStyle(color: txt, fontWeight: FontWeight.w600),
                              decoration: _buildInputDeco('Vendor name', inputBg, subTxt),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. Category Selector
                  _buildLabel('CATEGORY', subTxt),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSel = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: isDark ? Colors.white : const Color(0xFF121212),
                        backgroundColor: inputBg,
                        labelStyle: TextStyle(
                          color: isSel ? (isDark ? const Color(0xFF121212) : Colors.white) : txt,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (sel) {
                          if (sel) setState(() => _selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 5. Brand Selector
                  _buildLabel('BRAND', subTxt),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _brands.map((b) {
                      final isSel = _selectedBrand == b;
                      return ChoiceChip(
                        label: Text(b),
                        selected: isSel,
                        selectedColor: isDark ? Colors.white : const Color(0xFF121212),
                        backgroundColor: inputBg,
                        labelStyle: TextStyle(
                          color: isSel ? (isDark ? const Color(0xFF121212) : Colors.white) : txt,
                          fontWeight: FontWeight.w700,
                        ),
                        onSelected: (sel) {
                          if (sel) setState(() => _selectedBrand = b);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : const Color(0xFF121212),
                  foregroundColor: isDark ? const Color(0xFF121212) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: const Text('Update Eyewear in Inventory', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.8));
  }

  InputDecoration _buildInputDeco(String hint, Color bg, Color hintColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13.5, color: hintColor),
      filled: true,
      fillColor: bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }
}
