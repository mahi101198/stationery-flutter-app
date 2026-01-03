import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rps_stationery/utils/theme/app_theme.dart';

/// ThemeController manages the app's theme state and switching between light/dark modes
/// Follows system settings by default and allows manual override
class ThemeController extends GetxController {
  static ThemeController get instance => Get.find();
  
  final GetStorage _storage = GetStorage();
  static const String _themeKey = 'theme_mode';
  static const String _followSystemKey = 'follow_system';
  
  // Reactive variables
  final _themeMode = ThemeMode.system.obs;
  final _followSystem = true.obs;
  final _isDarkMode = false.obs;
  
  // Getters
  ThemeMode get themeMode => _themeMode.value;
  bool get followSystem => _followSystem.value;
  bool get isDarkMode => _isDarkMode.value;
  ThemeData get currentTheme => isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
  
  @override
  void onInit() {
    super.onInit();
    _loadThemeFromStorage();
    _updateSystemUIOverlay();
    // Apply the loaded theme immediately with a slight delay to ensure app is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.changeThemeMode(_themeMode.value);
    });
  }
  
  /// Load theme preferences from storage
  void _loadThemeFromStorage() {
    final savedThemeIndex = _storage.read<int>(_themeKey);
    final savedFollowSystem = _storage.read<bool>(_followSystemKey);
    
    // If no saved preference exists, default to system theme
    if (savedFollowSystem == null && savedThemeIndex == null) {
      _followSystem.value = true;
      _themeMode.value = ThemeMode.system;
    } else if (savedFollowSystem == false && savedThemeIndex != null) {
      // User has manually set a theme
      _followSystem.value = false;
      _themeMode.value = ThemeMode.values[savedThemeIndex];
    } else {
      // Follow system theme
      _followSystem.value = true;
      _themeMode.value = ThemeMode.system;
    }
    
    _updateCurrentThemeMode();
  }
  
  /// Update the current theme mode based on system/manual settings
  void _updateCurrentThemeMode() {
    if (_themeMode.value == ThemeMode.system) {
      // Use system brightness - check if context is available
      if (Get.context != null) {
        final brightness = Get.mediaQuery.platformBrightness;
        _isDarkMode.value = brightness == Brightness.dark;
      } else {
        // Fallback to light mode if no context available
        _isDarkMode.value = false;
      }
    } else {
      _isDarkMode.value = _themeMode.value == ThemeMode.dark;
    }
    
    _updateSystemUIOverlay();
  }
  
  /// Toggle between light and dark theme
  void toggleTheme() {
    if (_themeMode.value == ThemeMode.light) {
      setDarkMode();
    } else {
      setLightMode();
    }
  }
  
  /// Set light theme
  void setLightMode() {
    _themeMode.value = ThemeMode.light;
    _followSystem.value = false;
    _isDarkMode.value = false;
    _saveThemeToStorage();
    Get.changeThemeMode(ThemeMode.light);
    _updateSystemUIOverlay();
  }
  
  /// Set dark theme
  void setDarkMode() {
    _themeMode.value = ThemeMode.dark;
    _followSystem.value = false;
    _isDarkMode.value = true;
    _saveThemeToStorage();
    Get.changeThemeMode(ThemeMode.dark);
    _updateSystemUIOverlay();
  }
  
  /// Follow system theme
  void setSystemMode() {
    _themeMode.value = ThemeMode.system;
    _followSystem.value = true;
    _updateCurrentThemeMode();
    _saveThemeToStorage();
    Get.changeThemeMode(ThemeMode.system);
  }
  
  /// Save theme preferences to storage
  void _saveThemeToStorage() {
    _storage.write(_themeKey, _themeMode.value.index);
    _storage.write(_followSystemKey, _followSystem.value);
  }
  
  /// Update system UI overlay style based on current theme
  void _updateSystemUIOverlay() {
    final brightness = isDarkMode ? Brightness.dark : Brightness.light;
    AppTheme.setSystemUiOverlayStyle(brightness);
  }
  
  /// Get theme mode display name
  String get themeModeDisplayName {
    switch (_themeMode.value) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
  
  /// Get theme icon
  IconData get themeIcon {
    if (_followSystem.value) {
      return Icons.brightness_auto;
    }
    return isDarkMode ? Icons.dark_mode : Icons.light_mode;
  }
  
  /// Handle system theme changes when following system
  void handleSystemThemeChange() {
    if (_followSystem.value) {
      _updateCurrentThemeMode();
    }
  }
}
