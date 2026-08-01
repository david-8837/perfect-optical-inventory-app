import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F12) : const Color(0xFFFFFFFF);
    final cardBg = isDark ? const Color(0xFF1A1B20) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF121212);
    final subTxt = isDark ? const Color(0xFFA0A0A5) : const Color(0xFF8E8E93);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: txt, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Staff Profile & Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: txt)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(28)),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: isDark ? Colors.white : const Color(0xFF121212),
                  child: Icon(Icons.person_rounded, size: 36, color: isDark ? const Color(0xFF121212) : Colors.white),
                ),
                const SizedBox(height: 12),
                Text(auth.staffName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: txt)),
                const SizedBox(height: 2),
                Text(auth.staffRole, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: subTxt)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: const Text('Authorized Staff • Perfect Optical', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF4CAF50))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Session Details
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SESSION & PERMISSIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: subTxt, letterSpacing: 0.8)),
                const SizedBox(height: 14),
                _buildInfoTile('Shop ID', 'STORE-8802', txt, subTxt),
                _buildInfoTile('Auth Protocol', 'Password Pin Protected', txt, subTxt),
                _buildInfoTile('Offline Database', 'Active & Persisted', txt, subTxt),
                _buildInfoTile('Cloud Backend', 'Supabase Real-Time Sync', txt, subTxt),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _showLogoutConfirmDialog(context);
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Logout Staff Session', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String val, Color txt, Color subTxt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: subTxt)),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: txt)),
        ],
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Logout Confirmation', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to end your current staff session? You will need the store password to log back in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              AuthService().logout();
              onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
