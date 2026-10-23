import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:get/get.dart';

/// Kullanıcı geri bildirim veri modeli
class FeedbackModel {
  final String? id;
  final String userId;
  final String userEmail;
  final String type;
  final String subject;
  final String message;
  final dynamic createdAt;
  final String status;

  FeedbackModel({
    this.id,
    required this.userId,
    required this.userEmail,
    required this.type,
    required this.subject,
    required this.message,
    this.createdAt,
    this.status = 'yeni',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'type': type,
      'subject': subject.trim().isEmpty ? 'Konu Belirtilmedi' : subject.trim(),
      'message': message.trim(),
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'status': status,
    };
  }

  factory FeedbackModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FeedbackModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      type: data['type'] as String? ?? 'Genel İletişim',
      subject: data['subject'] as String? ?? 'Konu Belirtilmedi',
      message: data['message'] as String? ?? '',
      createdAt: data['createdAt'],
      status: data['status'] as String? ?? 'yeni',
    );
  }
}

/// Cloud Firestore 'feedbacks' koleksiyonu için servis katmanı
class FeedbackService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FeedbackService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Firestore 'feedbacks' koleksiyon referansı
  CollectionReference<Map<String, dynamic>> get _feedbacksCollection =>
      _firestore.collection('feedbacks');

  /// Geri bildirim verilerini Firestore'a kaydeder.
  Future<void> sendFeedback({
    required String type,
    String? subject,
    required String message,
  }) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw Exception('Lütfen açıklama / mesaj alanını doldurunuz.');
    }

    final trimmedSubject = subject?.trim();
    final effectiveSubject = (trimmedSubject != null && trimmedSubject.isNotEmpty)
        ? trimmedSubject
        : 'Konu Belirtilmedi';

    // 1. Kullanıcı kimlik tespiti (FirebaseAuth veya AuthService)
    String? uid = _auth.currentUser?.uid;
    String? userEmail = _auth.currentUser?.email;

    // Eğer FirebaseAuth'ta oturum yoksa, AuthService'teki AppUser'dan al
    if (uid == null || uid.isEmpty) {
      try {
        if (Get.isRegistered<AuthService>()) {
          final appUser = Get.find<AuthService>().currentUser.value;
          uid = appUser?.id;
          userEmail = appUser?.email;
        }
      } catch (_) {}
    }

    // Eğer Firebase Auth oturumu hiç yoksa ve Firestore kuralları için gerekiyorsa,
    // sessizce anonim oturum açmayı dene
    if (_auth.currentUser == null) {
      try {
        final anonCred = await _auth.signInAnonymously();
        uid ??= anonCred.user?.uid;
      } catch (e) {
        debugPrint("Anonim oturum açma uyarısı: $e");
      }
    }

    uid ??= 'anonim_${DateTime.now().millisecondsSinceEpoch}';
    userEmail = (userEmail != null && userEmail.isNotEmpty) ? userEmail : 'E-posta belirtilmedi';

    final feedbackData = <String, dynamic>{
      'userId': uid,
      'userEmail': userEmail,
      'type': type,
      'subject': effectiveSubject,
      'message': trimmedMessage,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'yeni',
    };

    try {
      await _feedbacksCollection
          .add(feedbackData)
          .timeout(const Duration(seconds: 10));
    } on FirebaseException {
      rethrow;
    } on TimeoutException {
      throw Exception('Bağlantı zaman aşımına uğradı. İnternet bağlantınızı kontrol ediniz.');
    } catch (e) {
      throw Exception('Geri bildirim gönderilirken bir hata oluştu: $e');
    }
  }
}
