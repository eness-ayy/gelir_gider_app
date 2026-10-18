import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/controllers/transaction_controller.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DateInput extends GetView<TransactionController> {
  const DateInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => InkWell(
        onTap: () async {
          final DateTime? secilenTarih = await showDatePicker(
            context: context,
            initialDate: controller.date.value,
            firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          );
          if (secilenTarih != null) {
            controller.date.value = secilenTarih;
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: "İşlem Tarihi",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
          child: Text(
            DateFormat('dd.MM.yyyy').format(controller.date.value),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
