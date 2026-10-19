import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/group/expense_group.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/group_service.dart';
import 'package:get/get.dart';

class GroupsController extends BaseController {
  GroupService get _groupService => Get.isRegistered<GroupService>()
      ? Get.find<GroupService>()
      : Get.put(GroupService());

  RxList<ExpenseGroup> get groups => _groupService.groups;

  Future<ExpenseGroup?> createNewGroup({
    required String title,
    required List<String> participantNames,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      showErrorSnackbar(message: "Lütfen bir grup adı girin");
      return null;
    }

    final names = participantNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    try {
      setLoading(true);
      final created = await _groupService.createGroup(
        title: cleanTitle,
        participantNames: names,
      );
      return created;
    } catch (e) {
      debugPrint("Grup oluşturulurken hata: $e");
      showErrorSnackbar(message: "Grup oluşturulurken hata oluştu");
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await _groupService.deleteGroup(groupId);
      showSuccessSnackbar(message: "Grup silindi");
    } catch (e) {
      showErrorSnackbar(message: "Grup silinirken hata oluştu");
    }
  }

  void openGroupDetail(ExpenseGroup group) {
    Get.toNamed(AppRoutes.groupDetail, arguments: group.id);
  }
}
