import 'package:flutter/foundation.dart';
import 'package:get/state_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StorageKeys {
  static const String userToken = "user_token";
  static const String themeMod = "theme_mod";
  static const String userData = "user_data";
  static const String groupNickname = "group_nickname";
  static const String cachedTransactions = "cached_transactions";
  static const String cachedCategories = "cached_categories";
}

class StorgeService extends GetxController {
  late final SharedPreferences _preferences;

  Future<StorgeService> init() async {
    _preferences = await SharedPreferences.getInstance();
    return this;
  }

  Future<bool> setValue<T>(String key, T value) async {
    try {
      if (value is String) {
        return await _preferences.setString(key, value);
      } else if (value is int) {
        return await _preferences.setInt(key, value);
      } else if (value is double) {
        return await _preferences.setDouble(key, value);
      } else if (value is bool) {
        return await _preferences.setBool(key, value);
      } else if (value is List<String>) {
        return await _preferences.setStringList(key, value);
      } else {
        throw ArgumentError("Desteklenmeyen veri türü");
      }
    } catch (e) {
      debugPrint("Veri eklenirken hata oluştu: $e");
      return false;
    }
  }

  T? getValue<T>(String key) {
    try {
      if (T == String) {
        return _preferences.getString(key) as T?;
      } else if (T == int) {
        return _preferences.getInt(key) as T?;
      } else if (T == double) {
        return _preferences.getDouble(key) as T?;
      } else if (T == bool) {
        return _preferences.getBool(key) as T?;
      } else if (T == List<String>) {
        return _preferences.getStringList(key) as T?;
      } else {
        throw ArgumentError("Desteklenmeyen veri türü");
      }
    } catch (e) {
      debugPrint("Veri storagedan okunurken hata oluştu: $e");
      return null;
    }
  }

  Future<bool> remove(String key) async {
    try {
      return await _preferences.remove(key);
    } catch (e) {
      debugPrint("Keyi verilen değer silinirken hata oluştu $e");
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      return await _preferences.clear();
    } catch (e) {
      debugPrint("clear fonksiyonunda hata oluştu $e");
      return false;
    }
  }

  bool hasKey(String key) {
    return _preferences.containsKey(key);
  }

  T getValueOrDefault<T>(String key, T defaultValue) {
    return getValue<T>(key) ?? defaultValue;
  }

  Map<String, dynamic> getAllValues() {
    final keys = _preferences.getKeys();
    final map = <String, dynamic>{};

    for (var key in keys) {
      map[key] = _preferences.get(key);
    }
    return map;
  }
}

// İsimlendirme uyumluluğu için
typedef StorageService = StorgeService;
