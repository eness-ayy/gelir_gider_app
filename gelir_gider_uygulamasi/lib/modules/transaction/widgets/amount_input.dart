import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/transaction_controller.dart';
import 'package:get/get.dart';

class AmountInput extends GetView<TransactionController> {
  const AmountInput({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller.amountController,
      decoration: const InputDecoration(
        labelText: "Miktar (₺)",
        hintText: "Örn: 250.00",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Lütfen bir miktar giriniz";
        }
        final parsed = double.tryParse(value.trim());
        if (parsed == null || parsed <= 0) {
          return "Lütfen geçerli pozitif bir miktar giriniz";
        }
        return null;
      },
    );
  }
}
