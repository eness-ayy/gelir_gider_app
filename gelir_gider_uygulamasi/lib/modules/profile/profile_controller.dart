import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/app_user.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:get/get.dart';

class ProfileController extends BaseController {
  final AuthService _authService = Get.find<AuthService>();
  Rx<AppUser?> get user => _authService.currentUser;

  Future<void> cikisYap() async {
    await _authService.signOut();
    Get.offAllNamed(AppRoutes.login);
  }
}
