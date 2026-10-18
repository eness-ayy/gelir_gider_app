import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/transaction_controller.dart';
import 'package:get/get.dart';

class SaveButton extends GetView<TransactionController> {
  const SaveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ElevatedButton.icon(
        onPressed: controller.isLoading ? null : controller.saveTransaction,
        icon: controller.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                controller.isEditing.value
                    ? Icons.check_circle_outline
                    : Icons.save_alt_rounded,
              ),
        label: Text(
          controller.isLoading
              ? "Kaydediliyor..."
              : (controller.isEditing.value ? "Güncelle" : "Kaydet"),
        ),
      ),
    );
  }
}
