import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Hesaply internet bağlantı ve ağ durumunu anlık takip eden servis.
/// Cihazın WiFi, Mobil Veri veya Çevrimdışı durumlarını dinler,
/// zarif bildirimlerle kullanıcıyı bilgilendirir.
class NetworkService extends GetxService {
  static NetworkService get to => Get.find<NetworkService>();

  final Connectivity _connectivity;

  NetworkService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Cihazın internete bağlı olup olmadığını tutan reaktif durum.
  final RxBool isConnected = true.obs;

  /// Aktif bağlantı türleri (WiFi, Mobil, Ethernet vb.)
  final RxList<ConnectivityResult> connectionTypes = <ConnectivityResult>[].obs;

  /// Önceki durumun çevrimdışı olup olmadığını izler.
  bool _wasOffline = false;
  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results, isInitial: true);
    } catch (e) {
      debugPrint("[NETWORK SERVICE] İlk bağlantı kontrolü hatası: $e");
    }

    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) => _handleConnectivityChange(results, isInitial: false),
      onError: (err) {
        debugPrint("[NETWORK SERVICE] Bağlantı akış hatası: $err");
      },
    );
  }

  void _handleConnectivityChange(
    List<ConnectivityResult> results, {
    bool isInitial = false,
  }) {
    connectionTypes.assignAll(results);

    final bool online = results.isNotEmpty &&
        results.any((r) => r != ConnectivityResult.none);

    final bool previousState = isConnected.value;
    isConnected.value = online;

    if (isInitial) {
      _wasOffline = !online;
      _isInitialized = true;
      if (!online) {
        // Uygulama internetsiz açıldıysa arayüz oturduğunda zarifçe uyar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showOfflineSnackbar();
        });
      }
      return;
    }

    if (!_isInitialized) {
      _isInitialized = true;
    }

    // Çevrimiçi -> Çevrimdışı geçişi
    if (previousState && !online) {
      _wasOffline = true;
      _showOfflineSnackbar();
    }
    // Çevrimdışı -> Tekrar Çevrimiçi geçişi
    else if (!previousState && online && _wasOffline) {
      _wasOffline = false;
      _showOnlineSnackbar();
    }
  }

  /// Zarif Çevrimdışı Bildirimi
  void _showOfflineSnackbar() {
    if (Get.context == null) return;

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.rawSnackbar(
      titleText: const Text(
        "Çevrimdışı Mod",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      messageText: const Text(
        "Çevrimdışı moddasınız. İşlemleriniz kaydedilecek ve internete bağlandığınızda eşitlenecektir.",
        style: TextStyle(
          color: Color(0xFFFDE68A), // Açık amber / sarı tonu
          fontSize: 12.5,
          height: 1.35,
        ),
      ),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFD97706).withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.wifi_off_rounded,
          color: Color(0xFFFBBF24),
          size: 22,
        ),
      ),
      backgroundColor: const Color(0xFF1E293B), // Modern koyu slate zemin
      borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.5),
      borderWidth: 1.2,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      borderRadius: 16,
      duration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 350),
      isDismissible: true,
      shouldIconPulse: false,
    );
  }

  /// Yeşil Tonlarında Kısa Çevrimiçi Bildirimi (2 sn sonra otomatik kaybolur)
  void _showOnlineSnackbar() {
    if (Get.context == null) return;

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.rawSnackbar(
      titleText: const Text(
        "Tekrar Çevrimiçisiniz",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      messageText: const Text(
        "Tekrar çevrimiçisiniz. Verileriniz eşitlendi.",
        style: TextStyle(
          color: Color(0xFFA7F3D0), // Açık zümrüt yeşili
          fontSize: 12.5,
          height: 1.35,
        ),
      ),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.cloud_done_rounded,
          color: Color(0xFF34D399),
          size: 22,
        ),
      ),
      backgroundColor: const Color(0xFF064E3B), // Zümrüt koyu yeşil zemin
      borderColor: const Color(0xFF10B981).withValues(alpha: 0.6),
      borderWidth: 1.2,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      borderRadius: 16,
      duration: const Duration(seconds: 2), // 2 saniye sonra otomatik kaybolur
      animationDuration: const Duration(milliseconds: 300),
      isDismissible: true,
      shouldIconPulse: false,
    );
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}

/// Sınıf isimlendirme uyumluluğu için Controller alias
typedef NetworkController = NetworkService;
