import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Giriş yapmış kullanıcının UID bilgisini döndürür.
  /// Kullanıcı oturumu kapalıysa Exception fırlatır.
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı. Lütfen giriş yapınız.');
    }
    return user.uid;
  }

  /// Kullanıcının alt koleksiyonu olan users/{userId}/transactions referansı
  CollectionReference<Map<String, dynamic>> get _transactionsCollection {
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('transactions');
  }

  /// Yeni işlem ekleme
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _transactionsCollection.add(transaction.toMap());
    } catch (e) {
      throw Exception('İşlem kaydedilirken bir hata oluştu: $e');
    }
  }

  /// İşlemleri tarihe göre azalan (en yeni en üstte) canlı dinleme
  Stream<List<TransactionModel>> getTransactions() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error('Kullanıcı oturumu bulunamadı.');
    }

    return _transactionsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    });
  }

  /// İşlem silme
  Future<void> deleteTransaction(String id) async {
    try {
      await _transactionsCollection.doc(id).delete();
    } catch (e) {
      throw Exception('İşlem silinirken bir hata oluştu: $e');
    }
  }
}
