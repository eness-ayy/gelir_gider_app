import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

class ThemeServices extends GetxService {
  late final StorgeService _storgeService;
  final _isDarkMode = false.obs;
  bool get isDarkMode => _isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    _storgeService = Get.find<StorgeService>();
    loadThemeMode();
  }

  void loadThemeMode() {
    final savedTheme = _storgeService.getValue<String>(StorageKeys.themeMod);
    if (savedTheme != null) {
      _isDarkMode.value = savedTheme == 'dark';
      Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    } else {
      final brightness = Get.theme.brightness;
      _isDarkMode.value = brightness == Brightness.dark;
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    await _storgeService.setValue<String>(
      StorageKeys.themeMod,
      _isDarkMode.value ? 'dark' : 'light',
    );
  }
}

 