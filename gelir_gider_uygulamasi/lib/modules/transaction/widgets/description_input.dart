import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/transaction_controller.dart';
import 'package:get/get.dart';

class DescriptionInput extends GetView<TransactionController> {
  const DescriptionInput({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller.descriptionController,
      decoration: const InputDecoration(
        labelText: "Açıklama",
        hintText: "Örn: Market alışverişi",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description_outlined),
      ),
      maxLines: 2,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Lütfen bir açıklama giriniz";
        }
        return null;
      },
    );
  }
}
