import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/core/base_controller.dart';
import 'package:gelir_gider_uygulamasi/models/account_balances.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/payment_method.dart';
import 'package:gelir_gider_uygulamasi/models/transaction_params.dart';
import 'package:gelir_gider_uygulamasi/repositories/category_repository.dart';
import 'package:gelir_gider_uygulamasi/repositories/transaction_repostory.dart';
import 'package:gelir_gider_uygulamasi/services/account_service.dart';
import 'package:gelir_gider_uygulamasi/services/category_service.dart';
import 'package:gelir_gider_uygulamasi/services/group_service.dart';
import 'package:gelir_gider_uygulamasi/utils/turkish_string_helper.dart';
import 'package:get/get.dart';

class DashboardController extends BaseController {
  late final TransactionRepostory _transactionRepostory;
  late final CategoryRepository _categoryRepository;
  AccountService get accountService => Get.isRegistered<AccountService>()
      ? Get.find<AccountService>()
      : Get.put(AccountService());

  final myTransaction = <AppTransaction>[].obs;
  final categories = <AppCategory>[].obs;

  // Search & Filter state
  TextEditingController? _searchController;
  bool _searchControllerDisposed = false;

  TextEditingController get searchController {
    if (_searchController == null || _searchControllerDisposed) {
      _searchController = TextEditingController(text: searchQuery.value);
      _searchControllerDisposed = false;
      _searchController!.addListener(() {
        if (!_searchControllerDisposed && _searchController != null) {
          searchQuery.value = _searchController!.text;
        }
      });
    }
    return _searchController!;
  }

  final searchQuery = ''.obs;
  final selectedType = 'all'.obs; // 'all', 'income', 'expense'
  final selectedAccountFilter =
      'all'.obs; // 'all', 'cash', 'bank_card', 'credit_card'
  final selectedDateRange = 'this_month'
      .obs; // 'this_month', 'this_week', 'last_month', 'all', 'custom'
  final customStartDate = Rxn<DateTime>();
  final customEndDate = Rxn<DateTime>();
  final selectedCategoryId = Rxn<String>();
  final selectedSort =
      'date_desc'.obs; // 'date_desc', 'date_asc', 'amount_desc', 'amount_asc'

  // Summary amounts (aylık özet & filtrelenmiş özet)
  final aylikGelir = 0.0.obs;
  final aylikGider = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _transactionRepostory = Get.find<TransactionRepostory>();
    _categoryRepository = Get.find<CategoryRepository>();

    // 1. Önce yerel hafızadaki (cache) verileri 0 ms bekleme ile anında göster
    final cached = _transactionRepostory.getCachedTransactions();
    if (cached.isNotEmpty) {
      myTransaction.value = cached;
      aylikOzet();
    }

    // 2. Ardından sunucudan taze verileri çek
    getTransactions(isBackground: cached.isNotEmpty);
    loadCategories();

    // 3. Kullanıcının varsayılan kategorilerini sessizce denetle / başlat
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      unawaited(
        CategoryService()
            .initializeDefaultCategories(fbUser.uid)
            .then((_) {
              loadCategories();
            })
            .catchError((_) {}),
      );
    }
  }

  @override
  void onClose() {
    _searchControllerDisposed = true;
    _searchController?.dispose();
    _searchController = null;
    super.onClose();
  }

  Future<void> loadCategories() async {
    try {
      final list = await _categoryRepository.getCategories();
      categories.value = list;
      _enrichTransactionsWithCategories();
    } catch (e) {
      debugPrint('Kategoriler alınırken hata: $e');
    }
  }

  void _enrichTransactionsWithCategories() {
    bool hasChanged = false;
    final groupService = Get.isRegistered<GroupService>()
        ? Get.find<GroupService>()
        : null;

    for (int i = 0; i < myTransaction.length; i++) {
      final tr = myTransaction[i];
      final currentCatName = tr.category?.name.trim() ?? '';
      final desc = tr.description.trim();

      // Mevcut (eski) grup harcamalarını "Sadece Kendi Payım + Toplam Bilgi" formatına normalize et
      if (groupService != null && desc.startsWith('[')) {
        final match = RegExp(r'^\[(.*?)\]\s*(.*)$').firstMatch(desc);
        if (match != null) {
          final rawHeader = match.group(1)?.trim() ?? '';
          final expTitle = match.group(2)?.trim() ?? '';
          if (!rawHeader.contains('|')) {
            for (final grp in groupService.groups) {
              for (final exp in grp.expenses) {
                final isMatched =
                    (exp.linkedTransactionId == tr.id) ||
                    (grp.title.trim().toLowerCase() ==
                            rawHeader.toLowerCase() &&
                        exp.title.trim().toLowerCase() ==
                            expTitle.toLowerCase());
                if (isMatched && exp.splitParticipantIds.length > 1) {
                  final share = double.parse(
                    exp.perPersonAmount.toStringAsFixed(2),
                  );
                  if ((tr.baseAmount - exp.amount).abs() < 0.05 ||
                      !tr.description.contains('|')) {
                    tr.amount = share.toStringAsFixed(2);
                    tr.description =
                        "[${grp.title}|${exp.amount.toStringAsFixed(2)}] ${exp.title}";
                    hasChanged = true;
                    _transactionRepostory.updateTransaction(
                      tr.id,
                      Transaction(
                        id: tr.id,
                        amount: share,
                        description: tr.description,
                        type: tr.type,
                        date: tr.date,
                        categoryId: tr.categoryId,
                        userId: tr.userId,
                        paymentMethod: tr.paymentMethod,
                      ),
                    );
                  }
                  break;
                }
              }
            }
          }
        }
      }
      final isMistakenDesc =
          desc.isNotEmpty &&
          currentCatName == desc &&
          desc != 'Gelir İşlemi' &&
          desc != 'Gider İşlemi';

      if (tr.category == null ||
          currentCatName.isEmpty ||
          isMistakenDesc ||
          currentCatName == 'İsimsiz Kategori') {
        // 1. Yüklenen kullanıcı kategorilerinden ara
        final found = categories.firstWhereOrNull(
          (c) =>
              c.id == tr.categoryId ||
              (c.name != null &&
                  c.name!.toLowerCase() == tr.categoryId.toLowerCase()),
        );
        if (found != null && found.name != null && found.name!.isNotEmpty) {
          tr.category = Category(
            name: found.name!,
            icon: found.icon ?? 'category',
            type: found.type ?? tr.type,
          );
          hasChanged = true;
        } else {
          // 2. Standart CategoryService varsayılanlarından ara
          final def = CategoryService.defaultCategories.firstWhereOrNull(
            (c) =>
                c.id == tr.categoryId ||
                c.name.toLowerCase() == tr.categoryId.toLowerCase(),
          );
          if (def != null) {
            tr.category = Category(
              name: def.name,
              icon: def.icon,
              type: def.type,
            );
            hasChanged = true;
          } else {
            // 3. CategoryRepository varsayılanlarından ara
            final defRepo = CategoryRepository.defaultCategories
                .firstWhereOrNull(
                  (c) =>
                      c.id == tr.categoryId ||
                      (c.name != null &&
                          c.name!.toLowerCase() == tr.categoryId.toLowerCase()),
                );
            if (defRepo != null && defRepo.name != null) {
              tr.category = Category(
                name: defRepo.name!,
                icon: defRepo.icon ?? 'category',
                type: defRepo.type ?? tr.type,
              );
              hasChanged = true;
            } else if (tr.categoryId.isNotEmpty &&
                !tr.categoryId.startsWith('def_') &&
                !tr.categoryId.startsWith('cat_') &&
                tr.categoryId != desc) {
              tr.category = Category(
                name: tr.categoryId,
                icon: 'category',
                type: tr.type,
              );
              hasChanged = true;
            } else {
              final isInc = tr.type == 'income' || tr.type == 'gelir';
              tr.category = Category(
                name: isInc ? 'Diğer Gelir' : 'Diğer Gider',
                icon: 'category',
                type: tr.type,
              );
              hasChanged = true;
            }
          }
        }
      }
    }
    if (hasChanged) {
      myTransaction.refresh();
    }
  }

  Future<void> refreshDashboard() async {
    final cached = _transactionRepostory.getCachedTransactions();
    myTransaction.value = cached;
    _enrichTransactionsWithCategories();
    aylikOzet();

    await Future.wait([
      getTransactions(isBackground: cached.isNotEmpty),
      loadCategories(),
    ]);
  }

  // Geriye dönük uyumluluk için
  Future<void> refreshDeshboard() async {
    await refreshDashboard();
  }

  Future<void> getTransactions({bool isBackground = false}) async {
    try {
      if (!isBackground && myTransaction.isEmpty) {
        setLoading(true);
      }
      final transactions = await _transactionRepostory.getTransactions();
      myTransaction.value = transactions;
      _enrichTransactionsWithCategories();
      aylikOzet();
    } catch (e) {
      debugPrint("İşlemler yüklenirken hata: $e");
      // Sadece ekranda gösterilecek hiçbir veri yoksa hata uyarısı ver
      if (myTransaction.isEmpty) {
        showErrorSnackbar(
          message:
              "Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.",
        );
      }
    } finally {
      setLoading(false);
    }
  }

  Future<bool> deleteTransactions(String id) async {
    try {
      final transactionsResult = await _transactionRepostory.deleteTransaction(
        id,
      );
      if (transactionsResult) {
        myTransaction.removeWhere((element) => element.id == id);
        await accountService.removePaymentMethod(id);
        aylikOzet();
        showSuccessSnackbar(message: "İşlem başarıyla silindi");
        return true;
      } else {
        showErrorSnackbar(message: "İşlem silinemedi");
        return false;
      }
    } catch (e) {
      showErrorSnackbar(message: "İşlem silinirken hata oluştu");
      return false;
    }
  }

  void aylikOzet() {
    aylikGelir.value = 0;
    aylikGider.value = 0;
    final now = DateTime.now();

    if (myTransaction.isNotEmpty) {
      final currentMonthTransactions = myTransaction.where((transaction) {
        final parsedDate = DateTime.tryParse(transaction.date);
        if (parsedDate == null) return false;
        return parsedDate.year == now.year && parsedDate.month == now.month;
      }).toList();

      for (var tr in currentMonthTransactions) {
        final amount = tr.baseAmount;
        if (tr.type == 'income') {
          aylikGelir.value += amount;
        } else {
          aylikGider.value += amount;
        }
      }
    }
  }

  // MARK: - Account Balances (Cebimdeki Nakit, Bankadaki Para, Kredi Kartı)

  AccountBalances get overallAccountBalances =>
      accountService.calculateBalances(myTransaction);

  AccountBalances get filteredAccountBalances =>
      accountService.calculateBalances(filteredTransactions);

  double get cashBalance => overallAccountBalances.cashBalance;
  double get bankBalance => overallAccountBalances.bankBalance;
  double get creditCardExpense => overallAccountBalances.creditCardExpense;
  double get totalLiquidAssets => overallAccountBalances.totalLiquidAssets;

  // MARK: - Filtering & Search Getters

  bool get hasActiveFilters {
    return searchQuery.value.trim().isNotEmpty ||
        selectedType.value != 'all' ||
        selectedAccountFilter.value != 'all' ||
        selectedDateRange.value != 'this_month' ||
        selectedCategoryId.value != null ||
        selectedSort.value != 'date_desc';
  }

  int get activeFilterCount {
    int count = 0;
    if (selectedType.value != 'all') count++;
    if (selectedAccountFilter.value != 'all') count++;
    if (selectedDateRange.value != 'this_month') count++;
    if (selectedCategoryId.value != null) count++;
    if (selectedSort.value != 'date_desc') count++;
    if (searchQuery.value.trim().isNotEmpty) count++;
    return count;
  }

  List<AppTransaction> get filteredTransactions {
    final now = DateTime.now();
    var list = myTransaction.where((tr) {
      // 1. İşlem Türü Filtresi
      if (selectedType.value != 'all' && tr.type != selectedType.value) {
        return false;
      }

      // 2. Kategori Filtresi
      if (selectedCategoryId.value != null &&
          selectedCategoryId.value!.isNotEmpty) {
        if (tr.categoryId != selectedCategoryId.value) {
          return false;
        }
      }

      // 2.5 Hesap / Ödeme Türü Filtresi (Nakit, Banka Kartı, Kredi Kartı)
      if (selectedAccountFilter.value != 'all') {
        PaymentMethod method;
        if (tr.paymentMethod != null && tr.paymentMethod!.isNotEmpty) {
          method = PaymentMethod.fromKey(tr.paymentMethod);
        } else {
          method = accountService.getPaymentMethod(tr.id);
        }
        if (method.key != selectedAccountFilter.value) {
          return false;
        }
      }

      // 3. Tarih Aralığı Filtresi
      if (!_matchesDateRange(tr, now)) {
        return false;
      }

      // 4. Arama Sorgusu (Türkçe karakter ve toleranslı arama destekli)
      final query = searchQuery.value.trim();
      if (query.isNotEmpty) {
        final groupMatch = RegExp(
          r'^\[(.*?)\]\s*(.*)$',
        ).firstMatch(tr.description.trim());
        final groupTitle = groupMatch?.group(1)?.split('|').first.trim();
        final expenseDesc = groupMatch?.group(2);
        final groupTitleMatch =
            groupTitle != null &&
            TurkishStringHelper.containsSearch(groupTitle, query);
        final expenseDescMatch =
            expenseDesc != null &&
            TurkishStringHelper.containsSearch(expenseDesc, query);
        final descMatch = TurkishStringHelper.containsSearch(
          tr.description,
          query,
        );
        final catMatch = TurkishStringHelper.containsSearch(
          tr.category?.name,
          query,
        );
        final amountMatch = tr.amount.contains(query);
        if (!descMatch &&
            !catMatch &&
            !amountMatch &&
            !groupTitleMatch &&
            !expenseDescMatch) {
          return false;
        }
      }

      return true;
    }).toList();

    // 5. Sıralama
    switch (selectedSort.value) {
      case 'date_asc':
        list.sort((a, b) {
          final aDate = DateTime.tryParse(a.date) ?? DateTime(1970);
          final bDate = DateTime.tryParse(b.date) ?? DateTime(1970);
          return aDate.compareTo(bDate);
        });
        break;
      case 'amount_desc':
        list.sort((a, b) => b.baseAmount.compareTo(a.baseAmount));
        break;
      case 'amount_asc':
        list.sort((a, b) => a.baseAmount.compareTo(b.baseAmount));
        break;
      case 'date_desc':
      default:
        list.sort((a, b) {
          final aDate = DateTime.tryParse(a.date) ?? DateTime(1970);
          final bDate = DateTime.tryParse(b.date) ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
        break;
    }

    return list;
  }

  bool _matchesDateRange(AppTransaction tr, DateTime now) {
    final parsedDate = DateTime.tryParse(tr.date);
    if (parsedDate == null) return false;

    switch (selectedDateRange.value) {
      case 'this_month':
        return parsedDate.year == now.year && parsedDate.month == now.month;
      case 'last_month':
        final targetYear = now.month == 1 ? now.year - 1 : now.year;
        final targetMonth = now.month == 1 ? 12 : now.month - 1;
        return parsedDate.year == targetYear && parsedDate.month == targetMonth;
      case 'this_week':
        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return !parsedDate.isBefore(startOfWeek) &&
            parsedDate.isBefore(endOfWeek);
      case 'custom':
        if (customStartDate.value != null && customEndDate.value != null) {
          final start = DateTime(
            customStartDate.value!.year,
            customStartDate.value!.month,
            customStartDate.value!.day,
          );
          final end = DateTime(
            customEndDate.value!.year,
            customEndDate.value!.month,
            customEndDate.value!.day,
            23,
            59,
            59,
          );
          return !parsedDate.isBefore(start) && !parsedDate.isAfter(end);
        }
        return true;
      case 'all':
      default:
        return true;
    }
  }

  // Üst Özet Kartları için Dönemsel Toplamlar (Hesap veya arama filtresinden etkilenmez, her zaman gerçek dönemsel özeti gösterir)
  double get summaryGelir {
    final now = DateTime.now();
    double total = 0.0;
    for (var tr in myTransaction) {
      if (tr.type == 'income' && _matchesDateRange(tr, now)) {
        total += tr.baseAmount;
      }
    }
    return total;
  }

  double get summaryGider {
    final now = DateTime.now();
    double total = 0.0;
    for (var tr in myTransaction) {
      if (tr.type == 'expense' && _matchesDateRange(tr, now)) {
        total += tr.baseAmount;
      }
    }
    return total;
  }

  double get summaryBakiye => summaryGelir - summaryGider;

  // Dinamik Özet Değerleri (Filtrelenmiş İşlemlere Göre)
  double get filteredGelir {
    double total = 0.0;
    for (var tr in filteredTransactions) {
      if (tr.type == 'income') {
        total += tr.baseAmount;
      }
    }
    return total;
  }

  double get filteredGider {
    double total = 0.0;
    for (var tr in filteredTransactions) {
      if (tr.type == 'expense') {
        total += tr.baseAmount;
      }
    }
    return total;
  }

  double get filteredBakiye => filteredGelir - filteredGider;

  String get periodTitle {
    switch (selectedDateRange.value) {
      case 'this_week':
        return 'Haftalık';
      case 'last_month':
        return 'Geçen Ay';
      case 'custom':
        return 'Dönem';
      case 'all':
        return 'Toplam';
      case 'this_month':
      default:
        return 'Aylık';
    }
  }

  // MARK: - Filter Actions

  void setTypeFilter(String type) {
    selectedType.value = type;
  }

  void setDateRangeFilter(String range) {
    selectedDateRange.value = range;
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    customStartDate.value = start;
    customEndDate.value = end;
    selectedDateRange.value = 'custom';
  }

  void setCategoryFilter(String? categoryId) {
    selectedCategoryId.value = categoryId;
  }

  void setSort(String sort) {
    selectedSort.value = sort;
  }

  void setAccountFilter(String accountKey) {
    if (selectedAccountFilter.value == accountKey) {
      selectedAccountFilter.value = 'all';
    } else {
      selectedAccountFilter.value = accountKey;
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  void clearFilters() {
    clearSearch();
    selectedType.value = 'all';
    selectedAccountFilter.value = 'all';
    selectedDateRange.value = 'this_month';
    customStartDate.value = null;
    customEndDate.value = null;
    selectedCategoryId.value = null;
    selectedSort.value = 'date_desc';
  }
}
