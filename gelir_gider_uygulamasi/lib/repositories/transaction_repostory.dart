import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/transaction_params.dart';
import 'package:gelir_gider_uygulamasi/services/api_services.dart';
import 'package:get/get.dart';

class TransactionRepostory extends GetxService {
  late final ApiServices _apiServices;

  @override
  void onInit() {
    super.onInit();
    _apiServices = Get.find<ApiServices>();
  }

  Future<List<AppTransaction>> getTransactions() async {
    final response = await _apiServices.get(ApiConstants.transactions);
    if (response.statusCode == 200) {
      var gelenList = response.data['transactions'] as List;
      return gelenList
          .map((transaction) => AppTransaction.fromJson(transaction))
          .toList();
    }
    throw Exception("İşlemler getirilirken hata oluştu");
  }

  Future<AppTransaction> createTransaction(Transaction transaction) async {
    final response = await _apiServices.post(
      ApiConstants.transactions,
      data: transaction.toJson(),
    );
    if (response.statusCode == 201) {
      if (response.data is Map<String, dynamic> && response.data['transaction'] != null) {
        return AppTransaction.fromJson(response.data['transaction']);
      }
      return AppTransaction.fromJson(response.data);
    }
    throw Exception("İşlem oluşturulurken hata oluştu");
  }

  Future<AppTransaction> updateTransaction(String id, Transaction transaction) async {
    final response = await _apiServices.put(
      '${ApiConstants.transactions}/$id',
      data: transaction.toJson(),
    );
    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic> && response.data['transaction'] != null) {
        return AppTransaction.fromJson(response.data['transaction']);
      }
      return AppTransaction.fromJson(response.data);
    }
    throw Exception("İşlem güncellenirken hata oluştu");
  }

  Future<bool> deleteTransaction(String id) async {
    final response = await _apiServices.delete(
      '${ApiConstants.transactions}/$id',
    );
    if (response.statusCode == 200) {
      return true;
    }
    throw Exception("İşlem silinirken hata oluştu");
  }
}

// İsimlendirme uyumluluğu için
typedef TransactionRepository = TransactionRepostory;
