import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/services/network_service.dart';
import 'package:get/get.dart';

class FakeConnectivity implements Connectivity {
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();
  List<ConnectivityResult> currentStatus = [ConnectivityResult.wifi];

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => currentStatus;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _controller.stream;

  void emit(List<ConnectivityResult> results) {
    currentStatus = results;
    _controller.add(results);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeConnectivity fakeConnectivity;
  late NetworkService networkService;

  setUp(() {
    Get.reset();
    fakeConnectivity = FakeConnectivity();
  });

  tearDown(() {
    fakeConnectivity.dispose();
  });

  test('NetworkService starts with online status when WiFi is active', () async {
    fakeConnectivity.currentStatus = [ConnectivityResult.wifi];
    networkService = NetworkService(connectivity: fakeConnectivity);
    Get.put<NetworkService>(networkService);

    // Initial check completes
    await Future.delayed(const Duration(milliseconds: 50));

    expect(networkService.isConnected.value, isTrue);
    expect(networkService.connectionTypes.contains(ConnectivityResult.wifi), isTrue);
  });

  test('NetworkService updates to offline when connection is lost', () async {
    fakeConnectivity.currentStatus = [ConnectivityResult.wifi];
    networkService = NetworkService(connectivity: fakeConnectivity);
    Get.put<NetworkService>(networkService);

    await Future.delayed(const Duration(milliseconds: 50));
    expect(networkService.isConnected.value, isTrue);

    // Emit offline status
    fakeConnectivity.emit([ConnectivityResult.none]);
    await Future.delayed(const Duration(milliseconds: 50));

    expect(networkService.isConnected.value, isFalse);
    expect(networkService.connectionTypes.contains(ConnectivityResult.none), isTrue);
  });

  test('NetworkService updates to online when network is restored', () async {
    fakeConnectivity.currentStatus = [ConnectivityResult.none];
    networkService = NetworkService(connectivity: fakeConnectivity);
    Get.put<NetworkService>(networkService);

    await Future.delayed(const Duration(milliseconds: 50));
    expect(networkService.isConnected.value, isFalse);

    // Restore to mobile data
    fakeConnectivity.emit([ConnectivityResult.mobile]);
    await Future.delayed(const Duration(milliseconds: 50));

    expect(networkService.isConnected.value, isTrue);
    expect(networkService.connectionTypes.contains(ConnectivityResult.mobile), isTrue);
  });
}
