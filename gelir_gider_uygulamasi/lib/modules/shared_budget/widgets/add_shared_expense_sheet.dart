import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/models/group/expense_model.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
import 'package:gelir_gider_uygulamasi/modules/shared_budget/detail/shared_budget_detail_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/widgets/payment_account_selector.dart';
import 'package:gelir_gider_uygulamasi/services/credit_card_service.dart';
import 'package:get/get.dart';

/// Ortak Hesap için harcama ekleme / düzenleme modalı
class AddSharedExpenseSheet extends StatefulWidget {
  final ExpenseModel? expenseToEdit;

  const AddSharedExpenseSheet({super.key, this.expenseToEdit});

  static Future<void> show(
    BuildContext context, {
    ExpenseModel? expenseToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddSharedExpenseSheet(expenseToEdit: expenseToEdit),
    );
  }

  @override
  State<AddSharedExpenseSheet> createState() => _AddSharedExpenseSheetState();
}

class _AddSharedExpenseSheetState extends State<AddSharedExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final SharedBudgetDetailController _controller;

  String? _selectedPayer;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  String? _selectedCreditCardId;
  final Set<String> _selectedSplitMembers = {};
  bool _isSaving = false;

  String get _effectivePaymentMethodKey {
    if (_selectedPaymentMethod == PaymentMethod.creditCard) {
      String? cardId = _selectedCreditCardId;
      if ((cardId == null || cardId.isEmpty) &&
          Get.isRegistered<CreditCardService>()) {
        final cards = Get.find<CreditCardService>().cards;
        if (cards.isNotEmpty) {
          cardId = cards.first.id;
        }
      }
      return PaymentMethod.buildCreditCardKey(cardId);
    }
    return _selectedPaymentMethod.key;
  }

  @override
  void initState() {
    super.initState();
    _controller = Get.find<SharedBudgetDetailController>();
    _titleController = TextEditingController();
    _amountController = TextEditingController();

    final members = _controller.members;
    final current = _controller.currentUserName;
    final editing = widget.expenseToEdit;

    if (editing != null) {
      _titleController.text = editing.title;
      _amountController.text = editing.amount.toStringAsFixed(2);
      _selectedPayer = members.any(
              (m) => m.toLowerCase() == editing.paidBy.toLowerCase())
          ? members.firstWhere(
              (m) => m.toLowerCase() == editing.paidBy.toLowerCase())
          : (members.isNotEmpty ? members.first : editing.paidBy);
      _selectedPaymentMethod = PaymentMethod.fromKey(editing.paymentMethod);
      _selectedCreditCardId =
          PaymentMethod.extractCreditCardId(editing.paymentMethod);
      _selectedSplitMembers.addAll(editing.splitMembers);
      if (_selectedSplitMembers.isEmpty) {
        _selectedSplitMembers.addAll(members);
      }
      return;
    }

    if (members.any((m) => m.toLowerCase() == current.toLowerCase())) {
      _selectedPayer = members.firstWhere(
        (m) => m.toLowerCase() == current.toLowerCase(),
      );
    } else if (members.isNotEmpty) {
      _selectedPayer = members.first;
    }

    _selectedSplitMembers.addAll(members);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _toggleSplitMember(String member) {
    setState(() {
      if (_selectedSplitMembers.contains(member)) {
        if (_selectedSplitMembers.length > 1) {
          _selectedSplitMembers.remove(member);
        } else {
          Get.snackbar(
            "Uyarı",
            "Harcamaya dahil olan en az bir kişi seçili olmalıdır.",
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        _selectedSplitMembers.add(member);
      }
    });
  }

  void _selectAllMembers() {
    setState(() {
      _selectedSplitMembers.addAll(_controller.members);
    });
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final title = _titleController.text.trim();
    final rawAmount =
        _amountController.text.replaceAll(',', '.').trim();
    final amount = double.tryParse(rawAmount) ?? 0.0;

    if (amount <= 0) {
      Get.snackbar(
        "Geçersiz Tutar",
        "Lütfen 0'dan büyük bir harcama tutarı girin.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_selectedPayer == null || _selectedPayer!.isEmpty) {
      Get.snackbar(
        "Ödeyen Seçilmedi",
        "Lütfen harcamayı yapan kişiyi belirleyin.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_selectedSplitMembers.isEmpty) {
      Get.snackbar(
        "Ortak Seçilmedi",
        "Lütfen bu harcamayı paylaşacak en az bir kişi seçin.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final editing = widget.expenseToEdit;
      final bool success;
      if (editing != null) {
        success = await _controller.updateExpense(
          oldExpense: editing,
          title: title,
          amount: amount,
          paidBy: _selectedPayer!,
          splitMembers: _selectedSplitMembers.toList(),
          paymentMethod: _effectivePaymentMethodKey,
        );
      } else {
        success = await _controller.addExpense(
          title: title,
          amount: amount,
          paidBy: _selectedPayer!,
          splitMembers: _selectedSplitMembers.toList(),
          paymentMethod: _effectivePaymentMethodKey,
        );
      }

      if (success && mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final members = _controller.members;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 14,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tutma Çubuğu
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Başlık
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.cottage_rounded,
                      color: Color(0xFF0D9488),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.expenseToEdit != null
                            ? "Harcamayı Düzenle"
                            : "Yeni Ortak Hesap Harcaması",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.expenseToEdit != null
                            ? "Tutar, ödeyen veya paylaşan kişileri güncelleyin"
                            : "Kira, fatura, mutfak ve ortak gider ekleyin",
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 1. HARCAMA BAŞLIĞI
              TextFormField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: "Harcama Başlığı",
                  hintText: "Örn: Mutfak Alışverişi, İnternet Faturası, Temizlik",
                  prefixIcon: const Icon(Icons.shopping_cart_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Lütfen harcama başlığı girin.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 2. TUTAR
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: "Tutar (₺)",
                  hintText: "0.00",
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  suffixText: "₺",
                  suffixStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Lütfen tutar girin.";
                  }
                  final parsed =
                      double.tryParse(val.replaceAll(',', '.').trim());
                  if (parsed == null || parsed <= 0) {
                    return "Geçerli bir tutar girin.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 3. ÖDEYEN KİŞİ
              const Text(
                "Harcamayı Kim Ödedi?",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade50,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPayer,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded),
                    items: members.map((member) {
                      final isMe = member.toLowerCase() ==
                          _controller.currentUserName.toLowerCase();
                      return DropdownMenuItem<String>(
                        value: member,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_rounded,
                              size: 18,
                              color: Color(0xFF0D9488),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isMe ? "$member (Sen)" : member,
                              style: TextStyle(
                                fontWeight:
                                    isMe ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPayer = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Ödeme Yöntemi (Sadece harcamayı yapan sen isen cüzdanına yansır)
              if (_selectedPayer?.toLowerCase() ==
                  _controller.currentUserName.toLowerCase()) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Ödeme Yöntemi",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "(Cüzdandan düşer)",
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: PaymentMethod.expenseMethods.map((method) {
                      final isSelected = _selectedPaymentMethod == method;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            method.icon,
                            size: 16,
                            color: isSelected ? Colors.white : method.color,
                          ),
                          label: Text(method.title),
                          selected: isSelected,
                          selectedColor: method.color,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedPaymentMethod = method;
                                if (method == PaymentMethod.creditCard &&
                                    Get.isRegistered<CreditCardService>()) {
                                  final cards =
                                      Get.find<CreditCardService>().cards;
                                  if (cards.isNotEmpty &&
                                      _selectedCreditCardId == null) {
                                    _selectedCreditCardId = cards.first.id;
                                  }
                                }
                              });
                              if (method == PaymentMethod.creditCard &&
                                  Get.isRegistered<CreditCardService>() &&
                                  Get.find<CreditCardService>().cards.isEmpty) {
                                PaymentAccountSelector
                                    .showNoCreditCardInfoDialog(context);
                              }
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_selectedPaymentMethod == PaymentMethod.creditCard)
                  Obx(() {
                    // Obx ile yeni kart eklendiğinde de anında güncellenir
                    final _ = Get.isRegistered<CreditCardService>()
                        ? Get.find<CreditCardService>().cards.length
                        : 0;
                    return PaymentAccountSelector.buildCardPickerSection(
                      context: context,
                      isDark: isDark,
                      selectedCardId: _selectedCreditCardId,
                      onSelectCard: (cardId) =>
                          setState(() => _selectedCreditCardId = cardId),
                    );
                  }),
                const SizedBox(height: 20),
              ],

              // 4. ORTAKLAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Kiminle Bölüşülecek? (Ev Arkadaşları)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _selectAllMembers,
                    child: const Text(
                      "Herkesi Seç",
                      style: TextStyle(fontSize: 13, color: Color(0xFF0D9488)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: members.map((member) {
                  final isSelected = _selectedSplitMembers.contains(member);
                  final isMe = member.toLowerCase() ==
                      _controller.currentUserName.toLowerCase();

                  return FilterChip(
                    label: Text(isMe ? "$member (Sen)" : member),
                    selected: isSelected,
                    selectedColor:
                        const Color(0xFF0D9488).withValues(alpha: 0.18),
                    checkmarkColor: const Color(0xFF0D9488),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF0D9488)
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF0D9488)
                            : (isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                    ),
                    onSelected: (_) => _toggleSplitMember(member),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 5. KAYDET BUTONU
              ElevatedButton(
                onPressed: _isSaving ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.expenseToEdit != null
                            ? "Değişiklikleri Kaydet"
                            : "Harcamayı Kaydet",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
