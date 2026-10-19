import 'package:gelir_gider_uygulamasi/modules/groups/group_detail/group_detail_controller.dart';
import 'package:get/get.dart';

class GroupDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GroupDetailController>(() => GroupDetailController());
  }
}
