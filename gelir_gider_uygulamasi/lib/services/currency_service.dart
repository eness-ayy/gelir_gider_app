import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/app_currency.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

/// Otomatik döviz kuru çekme ve akıllı önbellek (caching) servisi.
/// Açılışta veya arka planda kurları çeker; internetsiz durumlarda
/// yerel hafızadaki son kurları kullanır.
class CurrencyService extends GetxService {
  static const String _storageKey = 'cached_exchange_rates_v1';
  static const String _lastUpdateKey = 'cached_exchange_rates_time_v1';

  /// Birincil ve ikincil güvenilir, anahtarsız (free) kur API'leri
  static const String _primaryApiUrl = 'https://open.er-api.com/v6/latest/TRY';
  static const String _fallbackApiUrl =
      'https://api.frankfurter.app/v1/latest?symbols=USD,EUR,GBP&base=TRY';

  /// İnternet hiç olmasa bile ilk açılışta 0 dönmemesi için taban kurlar
  static const Map<String, double> _fallbackBaselineRates = {
    'USD': 34.50,
    'EUR': 37.50,
    'GBP': 44.50,
  };

  StorgeService get _storage => Get.isRegistered<StorgeService>()
      ? Get.find<StorgeService>()
      : Get.put(StorgeService());

  late final Dio _dio;

  /// Güncel kurlar: {'USD': 34.50, 'EUR': 37.50, 'GBP': 44.50} (1 Döviz = X TRY)
  final rates = <String, double>{}.obs;

  final isLoading = false.obs;
  final lastUpdated = Rxn<DateTime>();

  /// Servis başlatıldığında yerel önbellekten kurları yükler ve arka planda günceller.
  Future<CurrencyService> init() async {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      ),
    );

    _loadFromCache();
    // Arka planda non-blocking olarak güncel kurları çek
    unawaited(fetchRates());
    return this;
  }

  /// Belirli bir para birimi için geçerli kuru döner (1 Birim = X TRY)
  double getRate(AppCurrency currency) {
    if (currency.isBase) return 1.0;
    final r = rates[currency.code];
    if (r != null && r > 0) return r;
    return _fallbackBaselineRates[currency.code] ?? 1.0;
  }

  /// Kur alanına yazılacak hazır metin (Örn: "34,25" veya "34.25")
  String getFormattedRate(AppCurrency currency, {bool useComma = true}) {
    final rate = getRate(currency);
    final str = rate.toStringAsFixed(2);
    return useComma ? str.replaceAll('.', ',') : str;
  }

  /// Kurları uzaktan çeker. [force] true ise önbellek tazelik kontrolünü atlar.
  Future<bool> fetchRates({bool force = false}) async {
    // Son 1 saat içinde çekilmişse ve force değilse tekrar istek atma
    if (!force && lastUpdated.value != null) {
      final diff = DateTime.now().difference(lastUpdated.value!);
      if (diff.inHours < 1 && rates.isNotEmpty) {
        return true;
      }
    }

    isLoading.value = true;
    try {
      // 1. Birincil API'yi dene (open.er-api.com)
      final success = await _fetchFromPrimary();
      if (success) {
        await _saveToCache();
        return true;
      }

      // 2. Başarısız olursa ikincil API'yi dene (Frankfurter)
      final fallbackSuccess = await _fetchFromFallback();
      if (fallbackSuccess) {
        await _saveToCache();
        return true;
      }
    } catch (e) {
      debugPrint("[CURRENCY_SERVICE] Kur çekme uyarısı: $e");
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  Future<bool> _fetchFromPrimary() async {
    try {
      final response = await _dio.get(_primaryApiUrl);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : jsonDecode(response.data.toString()) as Map<String, dynamic>;

        final rawRates = data['rates'] as Map<String, dynamic>?;
        if (rawRates != null) {
          final newRates = <String, double>{};
          for (final code in ['USD', 'EUR', 'GBP']) {
            final rateToTry = rawRates[code];
            if (rateToTry is num && rateToTry > 0) {
              // base = TRY olduğu için 1 / rate = 1 Döviz kaç TRY eder
              newRates[code] =
                  (1.0 / rateToTry.toDouble() * 100).roundToDouble() / 100;
            }
          }

          if (newRates.isNotEmpty) {
            rates.addAll(newRates);
            lastUpdated.value = DateTime.now();
            debugPrint("[CURRENCY_SERVICE] Kurlar güncellendi: $rates");
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint("[CURRENCY_SERVICE] Primary API hatası: $e");
    }
    return false;
  }

  Future<bool> _fetchFromFallback() async {
    try {
      final response = await _dio.get(_fallbackApiUrl);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : jsonDecode(response.data.toString()) as Map<String, dynamic>;

        final rawRates = data['rates'] as Map<String, dynamic>?;
        if (rawRates != null) {
          final newRates = <String, double>{};
          for (final code in ['USD', 'EUR', 'GBP']) {
            final rateToTry = rawRates[code];
            if (rateToTry is num && rateToTry > 0) {
              newRates[code] =
                  (1.0 / rateToTry.toDouble() * 100).roundToDouble() / 100;
            }
          }

          if (newRates.isNotEmpty) {
            rates.addAll(newRates);
            lastUpdated.value = DateTime.now();
            debugPrint(
              "[CURRENCY_SERVICE] Fallback API'den kurlar alındı: $rates",
            );
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint("[CURRENCY_SERVICE] Fallback API hatası: $e");
    }
    return false;
  }

  void _loadFromCache() {
    try {
      final raw = _storage.getValue<String>(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          if (value is num) {
            rates[key] = value.toDouble();
          }
        });
      }

      final lastTimeStr = _storage.getValue<String>(_lastUpdateKey);
      if (lastTimeStr != null) {
        lastUpdated.value = DateTime.tryParse(lastTimeStr);
      }
    } catch (e) {
      debugPrint("[CURRENCY_SERVICE] Cache okuma hatası: $e");
    }

    // Önbellekte hiç veri yoksa güvenli taban kurları ata
    for (final entry in _fallbackBaselineRates.entries) {
      rates.putIfAbsent(entry.key, () => entry.value);
    }
  }

  Future<void> _saveToCache() async {
    try {
      final encoded = jsonEncode(rates);
      await _storage.setValue<String>(_storageKey, encoded);
      if (lastUpdated.value != null) {
        await _storage.setValue<String>(
          _lastUpdateKey,
          lastUpdated.value!.toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint("[CURRENCY_SERVICE] Cache kaydetme hatası: $e");
    }
  }
}
