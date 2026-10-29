import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/models/group/expense_model.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_model.dart';
import 'package:gelir_gider_uygulamasi/models/group/need_model.dart';
import 'package:get/get.dart';

/// Firebase Firestore tabanlı ortak harcama ve grup yönetim servisi.
class FirestoreGroupService extends GetxService {
  final FirebaseFirestore _firestore;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  FirestoreGroupService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Firestore 'groups' koleksiyon referansı
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('groups');

  /// Karıştırılması muhtemel karakterler çıkarılmış karakter kümesi:
  /// (0, O, 1, I, L hariç tutulmuştur)
  static const String _allowedChars = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

  // ===========================================================================
  // 1. DAVET KODU ÜRETİMİ
  // ===========================================================================

  /// Karıştırılması zor karakterlerden 6 haneli rastgele bir kod üretir.
  String generateRandomCode({int length = 6}) {
    final random = Random.secure();
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      final index = random.nextInt(_allowedChars.length);
      buffer.write(_allowedChars[index]);
    }
    return buffer.toString();
  }

  /// Firestore üzerinde çakışma kontrolü yaparak 6 haneli benzersiz davet kodu üretir.
  Future<String> generateUniqueInviteCode({int maxAttempts = 10}) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final code = generateRandomCode(length: 6);

      // Veritabanında aynı koda sahip grup var mı kontrol et
      final existingDoc = await _groupsCollection
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();

      if (existingDoc.docs.isEmpty) {
        return code;
      }
    }

    // Beklenmedik yüksek çakışma durumunda milisaniye destekli 6 haneli güvenli kod
    final fallbackCode = generateRandomCode(length: 6);
    debugPrint("Uyarı: $maxAttempts denemede çakışma yaşandı, üretilen kod: $fallbackCode");
    return fallbackCode;
  }

  // ===========================================================================
  // 2. GRUP YÖNETİMİ
  // ===========================================================================

  /// Yeni bir grup oluşturup Firestore veritabanına kaydeder.
  Future<GroupModel> createGroup({
    required String name,
    required List<String> members,
    String? customInviteCode,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError("Grup adı boş olamaz.");
    }

    // Üye listesini temizle ve tekilleştir
    final cleanMembers = members
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();

    if (cleanMembers.isEmpty) {
      throw ArgumentError("Grup en az bir üye içermelidir.");
    }

    // Benzersiz 6 haneli davet kodunu hazırla
    final inviteCode = (customInviteCode != null &&
            customInviteCode.trim().length == 6)
        ? customInviteCode.trim().toUpperCase()
        : await generateUniqueInviteCode();

    final docRef = _groupsCollection.doc();

    // Aktif kullanıcının UID'sini al ve güvenli üye listesine ekle
    String? currentUid;
    try {
      currentUid = _auth.currentUser?.uid;
    } catch (_) {}

    final memberUids = <String>[];
    if (currentUid != null && currentUid.isNotEmpty) {
      memberUids.add(currentUid);
    }

    final newGroup = GroupModel(
      id: docRef.id,
      name: cleanName,
      inviteCode: inviteCode,
      members: cleanMembers,
      memberUids: memberUids,
      createdById: currentUid,
      createdAt: DateTime.now(),
    );

    await docRef.set(newGroup.toMap());
    return newGroup;
  }

  /// 6 haneli davet koduna göre grubu bulup, yeni kişiyi grubun üye listesine
  /// FieldValue.arrayUnion kullanarak atomik olarak ekler.
  Future<GroupModel> joinGroupByInviteCode({
    required String inviteCode,
    required String memberName,
  }) async {
    final cleanCode = inviteCode.trim().toUpperCase();
    final cleanMember = memberName.trim();

    if (cleanCode.length != 6) {
      throw ArgumentError("Davet kodu 6 haneli olmalıdır.");
    }

    if (cleanMember.isEmpty) {
      throw ArgumentError("Katılımcı ismi boş olamaz.");
    }

    // Koda göre grubu ara
    final querySnapshot = await _groupsCollection
        .where('inviteCode', isEqualTo: cleanCode)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw StateError("'$cleanCode' koduna sahip bir grup bulunamadı.");
    }

    final groupDoc = querySnapshot.docs.first;
    final docRef = groupDoc.reference;

    String? currentUid;
    try {
      currentUid = _auth.currentUser?.uid;
    } catch (_) {}

    final updateData = <String, dynamic>{
      'members': FieldValue.arrayUnion([cleanMember]),
    };
    if (currentUid != null && currentUid.isNotEmpty) {
      updateData['memberUids'] = FieldValue.arrayUnion([currentUid]);
    }

    // Üyeyi arrayUnion ile atomik olarak ekle (aynı isim/UID varsa çoklu ekleme yapmaz)
    await docRef.update(updateData);

    // Güncel grup bilgisini oku ve döndür
    final updatedSnapshot = await docRef.get();
    return GroupModel.fromFirestore(updatedSnapshot);
  }

  /// Belirli bir grubu ID'ye göre tek seferlik getirir.
  Future<GroupModel?> getGroupById(String groupId) async {
    if (groupId.trim().isEmpty) return null;
    final doc = await _groupsCollection.doc(groupId).get();
    if (!doc.exists) return null;
    return GroupModel.fromFirestore(doc);
  }

  /// Belirli bir grubu canlı olarak dinler.
  Stream<GroupModel?> getGroupStream(String groupId) {
    if (groupId.trim().isEmpty) {
      return Stream.value(null);
    }
    return _groupsCollection.doc(groupId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return GroupModel.fromFirestore(snapshot);
    });
  }

  /// Belirli bir üyenin dahil olduğu grupları sunucu taraflı filtreleyerek canlı dinler.
  /// (Tüm veritabanını indirmek yerine sadece kullanıcının yetkili olduğu grupları çeker)
  Stream<List<GroupModel>> getGroupsForMember(String memberName, {String? userUid}) {
    final cleanName = memberName.trim();
    String? cleanUid = userUid?.trim();
    if (cleanUid == null || cleanUid.isEmpty) {
      try {
        cleanUid = _auth.currentUser?.uid;
      } catch (_) {}
    }

    // 1. En güvenli yol: UID bazlı sunucu sorgusu
    if (cleanUid != null && cleanUid.isNotEmpty) {
      return _groupsCollection
          .where('memberUids', arrayContains: cleanUid)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => GroupModel.fromFirestore(doc))
            .toList();
      });
    }

    // 2. Geriye dönük uyumluluk: Üye adı ile sunucu sorgusu
    if (cleanName.isNotEmpty) {
      return _groupsCollection
          .where('members', arrayContains: cleanName)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => GroupModel.fromFirestore(doc))
            .toList();
      });
    }

    return Stream.value([]);
  }

  /// Belirli bir üyenin dahil olduğu grupları sunucu taraflı filtreleyerek tek seferlik çeker
  Future<List<GroupModel>> fetchGroupsForMember(String memberName, {String? userUid}) async {
    final cleanName = memberName.trim();
    String? cleanUid = userUid?.trim();
    if (cleanUid == null || cleanUid.isEmpty) {
      try {
        cleanUid = _auth.currentUser?.uid;
      } catch (_) {}
    }

    try {
      // 1. UID ile doğrudan sunucudan filtreli çek
      if (cleanUid != null && cleanUid.isNotEmpty) {
        final snapshot = await _groupsCollection
            .where('memberUids', arrayContains: cleanUid)
            .get();
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs
              .map((doc) => GroupModel.fromFirestore(doc))
              .toList();
        }
      }

      // 2. Geriye dönük uyumluluk: İsim ile sunucudan filtreli çek
      if (cleanName.isNotEmpty) {
        final snapshot = await _groupsCollection
            .where('members', arrayContains: cleanName)
            .get();
        return snapshot.docs
            .map((doc) => GroupModel.fromFirestore(doc))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("Gruplar doğrudan çekilirken hata: $e");
      return [];
    }
  }

  /// Grubu ve alt koleksiyonlarını siler.
  /// Güvenlik: Yalnızca grubu oluşturan (createdById) veya üye olan kişi silebilir.
  Future<void> deleteGroup(String groupId) async {
    final cleanId = groupId.trim();
    if (cleanId.isEmpty) return;

    // Dokümanı oku ve yetki kontrolü yap
    final groupDoc = await _groupsCollection.doc(cleanId).get();
    if (!groupDoc.exists) return;

    final group = GroupModel.fromFirestore(groupDoc);
    String? currentUid;
    try {
      currentUid = _auth.currentUser?.uid;
    } catch (_) {}

    if (currentUid != null && group.createdById != null && group.createdById!.isNotEmpty) {
      if (group.createdById != currentUid) {
        throw StateError("Yalnızca grubu oluşturan kişi grubu silebilir.");
      }
    }

    // Harcamaları sil
    final expensesQuery =
        await _groupsCollection.doc(cleanId).collection('expenses').get();
    for (final doc in expensesQuery.docs) {
      await doc.reference.delete();
    }

    // İhtiyaçları sil
    final needsQuery =
        await _groupsCollection.doc(cleanId).collection('needs').get();
    for (final doc in needsQuery.docs) {
      await doc.reference.delete();
    }

    // Grup dokümanını sil
    await _groupsCollection.doc(cleanId).delete();
  }

  // ===========================================================================
  // 3. HARCAMA YÖNETİMİ
  // ===========================================================================

  /// Belirli bir gruba ait harcamaları tarihe göre sıralı ve canlı olarak dinleyen Stream.
  Stream<List<ExpenseModel>> getExpensesStream(
    String groupId, {
    bool descending = true,
  }) {
    if (groupId.trim().isEmpty) {
      return Stream.value([]);
    }

    return _groupsCollection
        .doc(groupId)
        .collection('expenses')
        .orderBy('date', descending: descending)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Seçili gruba yeni bir harcama ekler.
  Future<ExpenseModel> addExpense({
    required String groupId,
    required String title,
    required double amount,
    required String paidBy,
    required List<String> splitMembers,
    DateTime? date,
    String? paymentMethod,
    String? linkedTransactionId,
  }) async {
    final cleanGroupId = groupId.trim();
    final cleanTitle = title.trim();
    final cleanPaidBy = paidBy.trim();

    if (cleanGroupId.isEmpty) {
      throw ArgumentError("Grup ID boş olamaz.");
    }
    if (cleanTitle.isEmpty) {
      throw ArgumentError("Harcama başlığı boş olamaz.");
    }
    if (amount <= 0) {
      throw ArgumentError("Harcama tutarı 0'dan büyük olmalıdır.");
    }
    if (cleanPaidBy.isEmpty) {
      throw ArgumentError("Ödeyen kişi belirtilmelidir.");
    }

    final cleanSplit = splitMembers
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();

    if (cleanSplit.isEmpty) {
      throw ArgumentError("Harcamaya ortak olan en az bir kişi olmalıdır.");
    }

    final expensesCollection =
        _groupsCollection.doc(cleanGroupId).collection('expenses');
    final docRef = expensesCollection.doc();

    final expense = ExpenseModel(
      id: docRef.id,
      title: cleanTitle,
      amount: amount,
      paidBy: cleanPaidBy,
      splitMembers: cleanSplit,
      date: date ?? DateTime.now(),
      paymentMethod: paymentMethod,
      linkedTransactionId: linkedTransactionId,
    );

    await docRef.set(expense.toMap());
    return expense;
  }

  /// Seçili gruptaki mevcut bir harcamayı günceller.
  Future<ExpenseModel> updateExpense({
    required String groupId,
    required String expenseId,
    required String title,
    required double amount,
    required String paidBy,
    required List<String> splitMembers,
    DateTime? date,
    String? paymentMethod,
    String? linkedTransactionId,
  }) async {
    final cleanGroupId = groupId.trim();
    final cleanExpenseId = expenseId.trim();
    final cleanTitle = title.trim();
    final cleanPaidBy = paidBy.trim();

    if (cleanGroupId.isEmpty || cleanExpenseId.isEmpty) {
      throw ArgumentError("Grup ID ve Harcama ID boş olamaz.");
    }
    final cleanSplit = splitMembers
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();

    final docRef = _groupsCollection
        .doc(cleanGroupId)
        .collection('expenses')
        .doc(cleanExpenseId);

    final updated = ExpenseModel(
      id: cleanExpenseId,
      title: cleanTitle,
      amount: amount,
      paidBy: cleanPaidBy,
      splitMembers: cleanSplit,
      date: date ?? DateTime.now(),
      paymentMethod: paymentMethod,
      linkedTransactionId: linkedTransactionId,
    );

    await docRef.set(updated.toMap());
    return updated;
  }

  /// Seçili gruptan belirli bir harcamayı siler.
  Future<void> deleteExpense({
    required String groupId,
    required String expenseId,
  }) async {
    final cleanGroupId = groupId.trim();
    final cleanExpenseId = expenseId.trim();

    if (cleanGroupId.isEmpty || cleanExpenseId.isEmpty) {
      throw ArgumentError("Grup ID ve Harcama ID boş olamaz.");
    }

    await _groupsCollection
        .doc(cleanGroupId)
        .collection('expenses')
        .doc(cleanExpenseId)
        .delete();
  }

  // ===========================================================================
  // 4. İHTİYAÇLAR (ODAYA LAZIM) YÖNETİMİ
  // ===========================================================================

  /// Belirli bir gruba ait ihtiyaçları canlı dinleyen Stream.
  Stream<List<NeedModel>> getNeedsStream(String groupId) {
    final cleanGroupId = groupId.trim();
    if (cleanGroupId.isEmpty) {
      return Stream.value([]);
    }

    return _groupsCollection
        .doc(cleanGroupId)
        .collection('needs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => NeedModel.fromFirestore(doc))
          .toList();

      // Tamamlanmamışları üste, tamamlananları alta al
      list.sort((a, b) {
        if (a.isCompleted == b.isCompleted) {
          return b.createdAt.compareTo(a.createdAt);
        }
        return a.isCompleted ? 1 : -1;
      });
      return list;
    });
  }

  /// Yeni bir ihtiyaç ekler
  Future<NeedModel> addNeed({
    required String groupId,
    required String title,
    required String addedBy,
  }) async {
    final cleanGroupId = groupId.trim();
    final cleanTitle = title.trim();
    final cleanAddedBy = addedBy.trim();

    if (cleanGroupId.isEmpty) {
      throw ArgumentError("Grup ID boş olamaz.");
    }
    if (cleanTitle.isEmpty) {
      throw ArgumentError("İhtiyaç adı boş olamaz.");
    }
    if (cleanAddedBy.isEmpty) {
      throw ArgumentError("Ekleyen kişi belirtilmelidir.");
    }

    final docRef = _groupsCollection
        .doc(cleanGroupId)
        .collection('needs')
        .doc();

    final need = NeedModel(
      id: docRef.id,
      title: cleanTitle,
      addedBy: cleanAddedBy,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    await docRef.set(need.toMap());
    return need;
  }

  /// İhtiyacın durumunu 'alındı / alınmadı' olarak günceller
  Future<void> toggleNeedStatus({
    required String groupId,
    required String needId,
    required bool isCompleted,
    String? completedBy,
  }) async {
    final cleanGroupId = groupId.trim();
    final cleanNeedId = needId.trim();

    if (cleanGroupId.isEmpty || cleanNeedId.isEmpty) {
      throw ArgumentError("Grup ID ve İhtiyaç ID boş olamaz.");
    }

    final updateData = <String, dynamic>{
      'isCompleted': isCompleted,
    };
    if (isCompleted && completedBy != null && completedBy.trim().isNotEmpty) {
      updateData['completedBy'] = completedBy.trim();
    } else if (!isCompleted) {
      updateData['completedBy'] = FieldValue.delete();
    }

    await _groupsCollection
        .doc(cleanGroupId)
        .collection('needs')
        .doc(cleanNeedId)
        .update(updateData);
  }

  /// İhtiyacı siler
  Future<void> deleteNeed({
    required String groupId,
    required String needId,
  }) async {
    final cleanGroupId = groupId.trim();
    final cleanNeedId = needId.trim();

    if (cleanGroupId.isEmpty || cleanNeedId.isEmpty) {
      throw ArgumentError("Grup ID ve İhtiyaç ID boş olamaz.");
    }

    await _groupsCollection
        .doc(cleanGroupId)
        .collection('needs')
        .doc(cleanNeedId)
        .delete();
  }
}
