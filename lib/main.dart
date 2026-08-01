import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sync_loading_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/supabase_sync_service.dart';
import 'services/local_database_service.dart';
import 'widgets/sync_notification_toast.dart';

class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    await LocalDatabaseService().initDatabase();
    await SupabaseSyncService().initSyncEngine();
  } catch (e) {
    debugPrint('App initialization error: $e');
  }
  runApp(const PerfectOpticalApp());
}

enum AppFlowStep {
  splash,
  login,
  syncLoading,
  mainApp,
}

class PerfectOpticalApp extends StatefulWidget {
  const PerfectOpticalApp({super.key});

  @override
  State<PerfectOpticalApp> createState() => _PerfectOpticalAppState();
}

class _PerfectOpticalAppState extends State<PerfectOpticalApp> {
  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'English (US)';
  AppFlowStep _currentStep = AppFlowStep.splash;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('app_theme_mode');
      final savedLang = prefs.getString('app_language');
      if (mounted) {
        setState(() {
          if (savedTheme == 'Dark Mode') {
            _themeMode = ThemeMode.dark;
          } else if (savedTheme == 'Light Mode') {
            _themeMode = ThemeMode.light;
          } else {
            _themeMode = ThemeMode.system;
          }
          if (savedLang != null && savedLang.isNotEmpty) {
            _language = savedLang;
          }
        });
      }
    } catch (_) {}
  }

  void _setThemeMode(String themeStr) async {
    setState(() {
      if (themeStr == 'Dark Mode') {
        _themeMode = ThemeMode.dark;
      } else if (themeStr == 'Light Mode') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme_mode', themeStr);
    } catch (_) {}
  }

  void _setLanguage(String lang) async {
    setState(() {
      _language = lang;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', lang);
    } catch (_) {}
  }

  Future<void> _handleSplashComplete() async {
    final isLoggedIn = await _authService.checkSession();
    if (mounted) {
      setState(() {
        _currentStep = isLoggedIn ? AppFlowStep.syncLoading : AppFlowStep.login;
      });
    }
  }

  void _handleLoginSuccess() {
    setState(() {
      _currentStep = AppFlowStep.syncLoading;
    });
  }

  void _handleSyncComplete() {
    setState(() {
      _currentStep = AppFlowStep.mainApp;
    });
  }

  void _handleLogout() {
    setState(() {
      _currentStep = AppFlowStep.login;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget activeScreen;

    switch (_currentStep) {
      case AppFlowStep.splash:
        activeScreen = SplashScreen(
          key: const ValueKey('splash'),
          onSplashComplete: _handleSplashComplete,
        );
        break;
      case AppFlowStep.login:
        activeScreen = LoginScreen(
          key: const ValueKey('login'),
          onLoginSuccess: _handleLoginSuccess,
        );
        break;
      case AppFlowStep.syncLoading:
        activeScreen = SyncLoadingScreen(
          key: const ValueKey('syncLoading'),
          onSyncComplete: _handleSyncComplete,
        );
        break;
      case AppFlowStep.mainApp:
        activeScreen = HomeScreen(
          key: const ValueKey('mainApp'),
          currentThemeMode: _themeMode,
          currentLanguage: _language,
          onThemeChanged: _setThemeMode,
          onLanguageChanged: _setLanguage,
          onLogout: _handleLogout,
        );
        break;
    }

    return MaterialApp(
      title: 'Perfect Optical',
      debugShowCheckedModeBanner: false,
      scrollBehavior: CustomScrollBehavior(),
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF121212),
          brightness: Brightness.light,
          primary: const Color(0xFF121212),
          secondary: const Color(0xFFDC2626),
        ),
        textTheme: const TextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE5E5E5),
          brightness: Brightness.dark,
          primary: const Color(0xFFE5E5E5),
          secondary: const Color(0xFFEF4444),
          surface: const Color(0xFF1A1B20),
        ),
        textTheme: const TextTheme(),
      ),
      home: SyncNotificationOverlay(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: activeScreen,
        ),
      ),
    );
  }
}

