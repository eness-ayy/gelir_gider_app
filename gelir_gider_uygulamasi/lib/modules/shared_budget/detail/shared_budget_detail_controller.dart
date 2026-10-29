import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gelir_gider_uygulamasi/controllers/user_session_controller.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/group/expense_model.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_model.dart';
import 'package:gelir_gider_uygulamasi/models/group/need_model.dart';
import 'package:gelir_gider_uygulamasi/models/transaction_params.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/dashboard_controller.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:gelir_gider_uygulamasi/services/account_service.dart';
import 'package:gelir_gider_uygulamasi/services/firestore_group_service.dart';
import 'package:gelir_gider_uygulamasi/services/invite_link_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';

/// Ortak Ev & Yurt Bütçesi Detay Controller'ı
class SharedBudgetDetailController extends BaseController {
  final FirestoreGroupService _firestoreService =
      Get.isRegistered<FirestoreGroupService>()
      ? Get.find<FirestoreGroupService>()
      : Get.put(FirestoreGroupService());

  final UserSessionController _userSession =
      Get.isRegistered<UserSessionController>()
      ? Get.find<UserSessionController>()
      : Get.put(UserSessionController());

  TransactionRepostory get _transactionRepository =>
      Get.isRegistered<TransactionRepostory>()
      ? Get.find<TransactionRepostory>()
      : Get.put(TransactionRepostory());

  CategoryRepository get _categoryRepository =>
      Get.isRegistered<CategoryRepository>()
      ? Get.find<CategoryRepository>()
      : Get.put(CategoryRepository());

  AccountService get _accountService => Get.isRegistered<AccountService>()
      ? Get.find<AccountService>()
      : Get.put(AccountService());

  late final String groupId;

  final Rx<GroupModel?> group = Rx<GroupModel?>(null);
  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  final RxList<NeedModel> needs = <NeedModel>[].obs;
  final RxBool isInitialLoading = true.obs;

  final TextEditingController quickNeedController = TextEditingController();
  final RxBool isAddingNeed = false.obs;
  final RxInt selectedTabIndex = 0.obs; // 0: Harcamalar, 1: İhtiyaçlar
  final RxSet<String> paidSettlementMembers = <String>{}.obs;

  StorgeService get _storageService => Get.isRegistered<StorgeService>()
      ? Get.find<StorgeService>()
      : Get.put(StorgeService());

  String get _paidSettlementStorageKey =>
      'shared_budget_paid_settlements_$groupId';

  StreamSubscription<GroupModel?>? _groupSubscription;
  StreamSubscription<List<ExpenseModel>>? _expensesSubscription;
  StreamSubscription<List<NeedModel>>? _needsSubscription;

  String get currentUserName => _userSession.currentUserName.value;
  List<String> get members => group.value?.members ?? [];

  int get pendingNeedsCount => needs.where((n) => !n.isCompleted).length;
  int get completedNeedsCount => needs.where((n) => n.isCompleted).length;

  double get totalExpense =>
      expenses.fold<double>(0.0, (sum, item) => sum + item.amount);

  double get userPaidTotal {
    final name = currentUserName.toLowerCase();
    if (name.isEmpty) return 0.0;
    return expenses
        .where((e) => e.paidBy.toLowerCase() == name)
        .fold<double>(0.0, (sum, item) => sum + item.amount);
  }

  double get userShareTotal {
    final name = currentUserName.toLowerCase();
    if (name.isEmpty) return 0.0;
    return expenses
        .where((e) => e.splitMembers.any((m) => m.toLowerCase() == name))
        .fold<double>(0.0, (sum, item) => sum + item.perPersonAmount);
  }

  double get userNetBalance => userPaidTotal - userShareTotal;

  @override
  void onInit() {
    super.onInit();
    _extractGroupId();
    _loadPaidSettlements();
    _subscribeToFirestore();
  }

  void _loadPaidSettlements() {
    if (groupId.isEmpty) return;
    try {
      final raw = _storageService.getValue<String>(_paidSettlementStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = (jsonDecode(raw) as List).map((e) => e.toString());
        paidSettlementMembers.assignAll(decoded);
      }
    } catch (_) {}
  }

  Future<void> toggleSettlementPaid(String memberKey) async {
    final normalized = memberKey.trim().toLowerCase();
    if (normalized.isEmpty) return;
    if (paidSettlementKeysContains(normalized)) {
      paidSettlementMembers.remove(normalized);
    } else {
      paidSettlementMembers.add(normalized);
    }
    try {
      await _storageService.setValue<String>(
        _paidSettlementStorageKey,
        jsonEncode(paidSettlementMembers.toList()),
      );
    } catch (_) {}
  }

  bool paidSettlementKeysContains(String memberKey) =>
      paidSettlementMembers.contains(memberKey.trim().toLowerCase());

  @override
  void onClose() {
    _groupSubscription?.cancel();
    _expensesSubscription?.cancel();
    _needsSubscription?.cancel();
    quickNeedController.dispose();
    super.onClose();
  }

  void _extractGroupId() {
    final args = Get.arguments;
    if (args is String && args.isNotEmpty) {
      groupId = args;
    } else if (args is GroupModel) {
      groupId = args.id;
      group.value = args;
    } else if (args is Map && args['id'] != null) {
      groupId = args['id'].toString();
    } else if (_userSession.activeGroup.value != null) {
      groupId = _userSession.activeGroup.value!.id;
      group.value = _userSession.activeGroup.value;
    } else {
      groupId = '';
    }
  }

  void _subscribeToFirestore() {
    if (groupId.isEmpty) {
      isInitialLoading.value = false;
      return;
    }

    _groupSubscription = _firestoreService.getGroupStream(groupId).listen((
      updatedGroup,
    ) {
      if (updatedGroup != null) {
        group.value = updatedGroup;
        _userSession.selectActiveGroup(updatedGroup);
      }
    }, onError: (e) => debugPrint("Grup dinlenirken hata: $e"));

    _expensesSubscription = _firestoreService
        .getExpensesStream(groupId, descending: true)
        .listen(
          (updatedExpenses) {
            expenses.assignAll(updatedExpenses);
            isInitialLoading.value = false;
          },
          onError: (e) {
            debugPrint("Harcamalar dinlenirken hata: $e");
            isInitialLoading.value = false;
          },
        );

    _needsSubscription = _firestoreService
        .getNeedsStream(groupId)
        .listen(
          (updatedNeeds) {
            needs.assignAll(updatedNeeds);
          },
          onError: (e) {
            debugPrint("İhtiyaçlar dinlenirken hata: $e");
          },
        );
  }

  /// Harcama kullanıcının kendisi tarafından ödendiyse ana cüzdana işlem kaydı açar (Kullanıcının kendi payı tutarında)
  Future<String?> _createWalletTransactionForExpense({
    required String groupTitle,
    required String expenseTitle,
    required double userShareAmount,
    required double totalAmount,
    required String paymentMethod,
    required DateTime date,
  }) async {
    String categoryId = '';
    try {
      final categories = await _categoryRepository.getCategories();
      final expenseCategories = categories.where((c) => c.type == 'expense');
      if (expenseCategories.isNotEmpty) {
        // Varsa 'Diğer' veya ilk kategori
        final match = expenseCategories.firstWhere(
          (c) => (c.name?.toLowerCase().contains('diğer') ?? false),
          orElse: () => expenseCategories.first,
        );
        categoryId = match.id ?? '';
      }
    } catch (_) {}

    final formattedDesc = (totalAmount - userShareAmount).abs() > 0.01
        ? "[$groupTitle|${totalAmount.toStringAsFixed(2)}] $expenseTitle"
        : "[$groupTitle] $expenseTitle";

    final transaction = Transaction(
      id: '',
      amount: userShareAmount,
      description: formattedDesc,
      type: 'expense',
      date: date.toIso8601String(),
      categoryId: categoryId,
      userId: '',
      paymentMethod: paymentMethod,
    );

    final created = await _transactionRepository.createTransaction(transaction);
    if (created.id.isNotEmpty) {
      await _accountService.setPaymentMethod(created.id, paymentMethod);
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }
      return created.id;
    }
    return null;
  }

  Future<bool> addExpense({
    required String title,
    required double amount,
    required String paidBy,
    required List<String> splitMembers,
    String paymentMethod = 'cash',
    DateTime? date,
  }) async {
    if (isLoading) return false;
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      showErrorSnackbar(message: "Lütfen bir harcama başlığı girin.");
      return false;
    }

    if (amount <= 0) {
      showErrorSnackbar(message: "Harcama tutarı 0'dan büyük olmalıdır.");
      return false;
    }

    final cleanPaidBy = paidBy.trim();
    if (cleanPaidBy.isEmpty) {
      showErrorSnackbar(message: "Lütfen harcamayı yapan kişiyi seçin.");
      return false;
    }

    if (splitMembers.isEmpty) {
      showErrorSnackbar(message: "En az bir ortak seçilmelidir.");
      return false;
    }

    try {
      setLoading(true);

      final isPayerCurrentUser =
          cleanPaidBy.toLowerCase() == currentUserName.trim().toLowerCase();

      String? linkedTxId;
      final expenseDate = date ?? DateTime.now();
      final groupTitle = group.value?.name ?? 'Ev/Yurt Bütçesi';

      // Eğer harcamayı aktif kullanıcı ödediyse cüzdana sadece kendi payı kadar işlem kaydı aç
      if (isPayerCurrentUser) {
        try {
          final splitCount = splitMembers.isEmpty ? 1 : splitMembers.length;
          final userShareAmount = double.parse(
            (amount / splitCount).toStringAsFixed(2),
          );
          linkedTxId = await _createWalletTransactionForExpense(
            groupTitle: groupTitle,
            expenseTitle: cleanTitle,
            userShareAmount: userShareAmount,
            totalAmount: amount,
            paymentMethod: paymentMethod,
            date: expenseDate,
          );
        } catch (e) {
          debugPrint("Cüzdana işlem eklenirken hata: $e");
        }
      }

      await _firestoreService.addExpense(
        groupId: groupId,
        title: cleanTitle,
        amount: amount,
        paidBy: cleanPaidBy,
        splitMembers: splitMembers,
        date: expenseDate,
        paymentMethod: paymentMethod,
        linkedTransactionId: linkedTxId,
      );

      showSuccessSnackbar(
        title: "Harcama Eklendi",
        message: "'$cleanTitle' başarıyla ortak kasaya işlendi.",
      );
      return true;
    } catch (e) {
      debugPrint("Harcama ekleme hatası: $e");
      showErrorSnackbar(message: "Harcama kaydedilirken hata oluştu: $e");
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> updateExpense({
    required ExpenseModel oldExpense,
    required String title,
    required double amount,
    required String paidBy,
    required List<String> splitMembers,
    String paymentMethod = 'cash',
  }) async {
    if (isLoading) return false;
    final cleanTitle = title.trim();
    final cleanPaidBy = paidBy.trim();
    if (cleanTitle.isEmpty ||
        amount <= 0 ||
        cleanPaidBy.isEmpty ||
        splitMembers.isEmpty) {
      return false;
    }

    try {
      setLoading(true);

      if (oldExpense.linkedTransactionId != null &&
          oldExpense.linkedTransactionId!.isNotEmpty) {
        try {
          await _transactionRepository.deleteTransaction(
            oldExpense.linkedTransactionId!,
          );
          await _accountService.removePaymentMethod(
            oldExpense.linkedTransactionId!,
          );
        } catch (_) {}
      }

      final isPayerCurrentUser =
          cleanPaidBy.toLowerCase() == currentUserName.trim().toLowerCase();
      String? newLinkedTxId;
      final groupTitle = group.value?.name ?? 'Ortak Hesap';

      if (isPayerCurrentUser) {
        try {
          final splitCount = splitMembers.isEmpty ? 1 : splitMembers.length;
          final userShareAmount =
              double.parse((amount / splitCount).toStringAsFixed(2));
          newLinkedTxId = await _createWalletTransactionForExpense(
            groupTitle: groupTitle,
            expenseTitle: cleanTitle,
            userShareAmount: userShareAmount,
            totalAmount: amount,
            paymentMethod: paymentMethod,
            date: oldExpense.date,
          );
        } catch (_) {}
      } else if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().refreshDashboard();
      }

      await _firestoreService.updateExpense(
        groupId: groupId,
        expenseId: oldExpense.id,
        title: cleanTitle,
        amount: amount,
        paidBy: cleanPaidBy,
        splitMembers: splitMembers,
        date: oldExpense.date,
        paymentMethod: paymentMethod,
        linkedTransactionId: newLinkedTxId,
      );

      showSuccessSnackbar(message: "Ortak gider güncellendi.");
      return true;
    } catch (e) {
      showErrorSnackbar(message: "Harcama güncellenirken hata oluştu: $e");
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> confirmDeleteExpense(ExpenseModel expense) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Harcamayı Sil"),
          ],
        ),
        content: Text(
          "'${expense.title}' başlıklı harcama kalıcı olarak silinecek. Emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await deleteExpense(expense);
    }
  }

  Future<void> deleteExpense(ExpenseModel expense) async {
    try {
      setLoading(true);

      // Cüzdandaki bağlı işlemi sil
      if (expense.linkedTransactionId != null &&
          expense.linkedTransactionId!.isNotEmpty) {
        try {
          await _transactionRepository.deleteTransaction(
            expense.linkedTransactionId!,
          );
          await _accountService.removePaymentMethod(
            expense.linkedTransactionId!,
          );
          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().refreshDashboard();
          }
        } catch (e) {
          debugPrint("Bağlı cüzdan işlemi silinirken hata: $e");
        }
      }

      await _firestoreService.deleteExpense(
        groupId: groupId,
        expenseId: expense.id,
      );
      showSuccessSnackbar(message: "Harcama ortak kasadan silindi.");
    } catch (e) {
      debugPrint("Harcama silme hatası: $e");
      showErrorSnackbar(message: "Harcama silinirken hata oluştu.");
    } finally {
      setLoading(false);
    }
  }

  void copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    showSuccessSnackbar(
      title: "Kopyalandı 📋",
      message: "Ev/Oda davet kodu ($code) panoya kopyalandı.",
      duration: const Duration(seconds: 2),
    );
  }

  void shareInviteLink() {
    final currentGroup = group.value;
    if (currentGroup != null && Get.isRegistered<InviteLinkService>()) {
      Get.find<InviteLinkService>().shareGroup(currentGroup);
    }
  }

  // ===========================================================================
  // İHTİYAÇLAR (ODAYA LAZIM) YÖNETİMİ
  // ===========================================================================

  /// Yeni bir ihtiyaç ekler (hızlı çubuktan veya diyalogdan)
  Future<bool> addNeed([String? customTitle]) async {
    if (isAddingNeed.value) return false;
    final title = (customTitle ?? quickNeedController.text).trim();
    if (title.isEmpty) {
      showErrorSnackbar(message: "Lütfen neyin eksik olduğunu yazın.");
      return false;
    }

    try {
      isAddingNeed.value = true;
      final addedBy = currentUserName.isNotEmpty
          ? currentUserName
          : "Ev Arkadaşı";

      await _firestoreService.addNeed(
        groupId: groupId,
        title: title,
        addedBy: addedBy,
      );

      quickNeedController.clear();
      showSuccessSnackbar(
        title: "Eksik Eklendi ✅",
        message: "'$title' ihtiyaç listesine eklendi.",
        duration: const Duration(seconds: 2),
      );
      return true;
    } catch (e) {
      debugPrint("İhtiyaç ekleme hatası: $e");
      showErrorSnackbar(message: "İhtiyaç eklenirken hata oluştu.");
      return false;
    } finally {
      isAddingNeed.value = false;
    }
  }

  /// İhtiyacın durumunu (alındı / alınmadı) değiştirir
  Future<void> toggleNeed(NeedModel need) async {
    try {
      final newStatus = !need.isCompleted;
      await _firestoreService.toggleNeedStatus(
        groupId: groupId,
        needId: need.id,
        isCompleted: newStatus,
        completedBy: newStatus
            ? (currentUserName.isNotEmpty ? currentUserName : "Biri")
            : null,
      );
    } catch (e) {
      debugPrint("İhtiyaç güncellenirken hata: $e");
      showErrorSnackbar(message: "Durum güncellenemedi.");
    }
  }

  /// İhtiyacı kalıcı olarak siler
  Future<void> deleteNeed(String needId) async {
    try {
      await _firestoreService.deleteNeed(groupId: groupId, needId: needId);
      showSuccessSnackbar(
        message: "İhtiyaç listeden silindi.",
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint("İhtiyaç silinirken hata: $e");
      showErrorSnackbar(message: "İhtiyaç silinemedi.");
    }
  }

  /// Modal ile ihtiyaç ekleme penceresi
  Future<void> showAddNeedDialog(BuildContext context) async {
    final textController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 14,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF0D9488,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.checklist_rounded,
                          color: Color(0xFF0D9488),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Odaya Ne Lazım?",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Eksik bir ihtiyaç veya alınacak ürün yazın",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Örn: Deterjan, Yumurta, Ekmek, Tuvalet Kağıdı",
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.add_shopping_cart_rounded),
                    ),
                    onSubmitted: (val) async {
                      if (val.trim().isNotEmpty) {
                        Navigator.of(ctx).pop();
                        await addNeed(val);
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final text = textController.text.trim();
                      if (text.isNotEmpty) {
                        Navigator.of(ctx).pop();
                        await addNeed(text);
                      }
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text(
                      "Listeye Ekle",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        textController.dispose();
      });
    });
  }
}
