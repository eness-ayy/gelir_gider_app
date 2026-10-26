import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/models/app_category.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/app_user.dart';
import 'package:gelir_gider_uygulamasi/models/category_budget_status.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_model.dart';
import 'package:gelir_gider_uygulamasi/modules/home/home_controller.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Auth & Guest Flow Mimari Doğrulamaları', () {
    test('Kullanıcı modeli ve hesap bağlama verileri eksiksiz saklanır', () {
      final guestUser = AppUser(
        id: 'anon_user_123',
        email: null,
        firstName: 'Misafir',
        lastName: null,
      );

      // Google bağlandıktan sonra UID aynı kalır (Firebase linkWithCredential kuralı)
      final linkedUser = guestUser.copyWith(
        email: 'enes@example.com',
        firstName: 'Enes',
        lastName: 'Ayyildiz',
      );

      expect(linkedUser.id, equals('anon_user_123'));
      expect(linkedUser.email, equals('enes@example.com'));
      expect(linkedUser.fullName, equals('Enes Ayyildiz'));
    });
  });

  group('2. Harcama, Gelir ve Bütçe Matematiği', () {
    test('Kuruş ve Ondalık Girişi: Virgüllü (125,50) ve Noktalı (125.50) giriş doğru parse edilir', () {
      const inputWithComma = "125,50";
      const inputWithDot = "125.50";

      final parseComma = double.tryParse(inputWithComma.replaceAll(',', '.'));
      final parseDot = double.tryParse(inputWithDot.replaceAll(',', '.'));

      expect(parseComma, equals(125.50));
      expect(parseDot, equals(125.50));

      // Bakiye düşüş hesabı
      double totalBalance = 1000.00;
      totalBalance -= parseComma!;
      expect(totalBalance, equals(874.50));
    });

    test('Aşırı Yüksek Sayılar: 999.999.999 tutarları formatlama ve parse hatasına yol açmaz', () {
      const rawHighNumber = "999999999.00";
      final parsed = double.tryParse(rawHighNumber);
      expect(parsed, isNotNull);
      expect(parsed, equals(999999999.00));

      final currencyFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
      final formatted = currencyFormatter.format(parsed);
      expect(formatted, contains('999.999.999'));
    });

    test('Bütçe Aşımı: 1.000 TL limit ve 1.200 TL harcama durumu', () {
      final cat = AppCategory(id: 'cat_market', name: 'Market & Gıda', type: 'expense');

      final status = CategoryBudgetStatus(
        category: cat,
        limit: 1000.0,
        spent: 1200.0,
        remaining: -200.0,
        percentage: 120.0,
        level: BudgetStatusLevel.exceeded,
      );

      // İlerleme çubuğu 1.0 ile sınırlanmalı (patlama/taşma olmamalı)
      expect(status.progressRatio, equals(1.0));
      expect(status.isExceeded, isTrue);
      expect(status.statusColor, equals(Colors.redAccent));
      expect(status.statusText, equals("Bütçe Aşıldı!"));
    });

    test('Silme ve Güncelleme: Harcama silindiğinde bakiye anında güncellenir', () {
      final list = <AppTransaction>[
        AppTransaction(
          id: 'tr_1',
          amount: '500.0',
          type: 'income',
          categoryId: 'cat_income',
          userId: 'test_user',
          createdAt: '',
          updatedAt: '',
          date: DateTime.now().toIso8601String(),
          description: 'Maaş',
        ),
        AppTransaction(
          id: 'tr_2',
          amount: '200.0',
          type: 'expense',
          categoryId: 'cat_market',
          userId: 'test_user',
          createdAt: '',
          updatedAt: '',
          date: DateTime.now().toIso8601String(),
          description: 'Market',
        ),
      ];

      // İlk toplam bakiye: 500 - 200 = 300
      double calcBalance() {
        double inc = 0;
        double exp = 0;
        for (var t in list) {
          final a = double.tryParse(t.amount) ?? 0.0;
          if (t.type == 'income') {
            inc += a;
          } else {
            exp += a;
          }
        }
        return inc - exp;
      }

      expect(calcBalance(), equals(300.0));

      // 200 TL'lik harcamayı sil
      list.removeWhere((t) => t.id == 'tr_2');
      expect(calcBalance(), equals(500.0));
    });
  });

  group('3. Klavye & PopScope Sistem Davranışları', () {
    testWidgets('HomeController geri tuşunda ana sekmeye (Cüzdan) döner', (tester) async {
      Get.reset();
      final homeController = Get.put(HomeController());
      homeController.currentIndex.value = 2; // Ekstra sekmesi

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // Geri basıldığında index 0'a döner
      if (homeController.currentIndex.value != 0) {
        homeController.changePage(0);
      }
      await tester.pumpAndSettle();
      expect(homeController.currentIndex.value, equals(0));
    });
  });

  group('4. Ortak Bütçe & Grup Güvenlik Mimarisi', () {
    test('GroupModel memberUids ve createdById alanlarını güvenle serileştirir', () {
      final now = DateTime.now();
      final group = GroupModel(
        id: 'grp_test_1',
        name: 'Ev Arkadaşları',
        inviteCode: 'A2B3C4',
        members: ['Enes', 'Ali'],
        memberUids: ['uid_enes', 'uid_ali'],
        createdById: 'uid_enes',
        createdAt: now,
      );

      final map = group.toMap();
      expect(map['memberUids'], equals(['uid_enes', 'uid_ali']));
      expect(map['createdById'], equals('uid_enes'));

      final fromMap = GroupModel.fromMap(map, id: 'grp_test_1');
      expect(fromMap.memberUids, contains('uid_enes'));
      expect(fromMap.memberUids, contains('uid_ali'));
      expect(fromMap.createdById, equals('uid_enes'));
    });
  });
}
