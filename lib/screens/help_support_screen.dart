import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F12) : const Color(0xFFFFFFFF);
    final cardBg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF121212);
    final subTxt = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);

    final faqs = [
      {
        'q': 'How does offline mode work?',
        'a': 'All frames, prices, stock counts, and images are stored locally in your device. You can browse, edit, add, or delete frames even without internet. Changes will show "Pending Sync" and auto-upload when internet reconnects.'
      },
      {
        'q': 'How do other staff members see my updates?',
        'a': 'When online, Supabase Cloud real-time sync pushes your additions and stock edits automatically to all connected staff devices in real-time without manual refresh.'
      },
      {
        'q': 'How to change staff password?',
        'a': 'Default staff password is set to "perfect123". Contact your system administrator to update store security credentials.'
      },
      {
        'q': 'What happens if a sync conflict occurs?',
        'a': 'The system prioritizes the most recent edit timestamp and automatically merges quantity counts to prevent stock discrepancy.'
      },
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: txt, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Help & Support Center', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: txt)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(28)),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: const Color(0xFF03A9F4).withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                  child: const Center(child: Icon(Icons.help_center_rounded, color: Color(0xFF03A9F4), size: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Staff Operations Guide', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: txt)),
                      const SizedBox(height: 2),
                      Text('Troubleshooting & System FAQs', style: TextStyle(fontSize: 12, color: subTxt)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // FAQs
          Text('FREQUENTLY ASKED QUESTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: subTxt, letterSpacing: 0.8)),
          const SizedBox(height: 12),

          ...faqs.map((faq) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(22)),
                child: ExpansionTile(
                  title: Text(faq['q']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: txt)),
                  iconColor: txt,
                  collapsedIconColor: subTxt,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(faq['a']!, style: TextStyle(fontSize: 13, height: 1.5, color: subTxt)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
