import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _sessionKey = 'perfect_optical_staff_session';
  bool _isLoggedIn = false;
  final String _staffName = 'Optical Shop Staff';
  final String _staffRole = 'Senior Inventory Manager';
  final String _staffPin = 'perfect123'; // Private shop password

  bool get isLoggedIn => _isLoggedIn;
  String get staffName => _staffName;
  String get staffRole => _staffRole;

  Future<bool> checkSession() async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSession = prefs.getString(_sessionKey);
      if (savedSession == 'active_staff_session') {
        _isLoggedIn = true;
        return true;
      }
    } catch (_) {
      // Fallback if local storage unavailable
    }
    return _isLoggedIn;
  }

  Future<bool> login(String password) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (password.trim() == _staffPin) {
      _isLoggedIn = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sessionKey, 'active_staff_session');
      } catch (_) {}
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _isLoggedIn = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (_) {}
  }
}
