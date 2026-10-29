import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/firebase_options.dart';
import 'package:gelir_gider_uygulamasi/models/app_transaction.dart';
import 'package:gelir_gider_uygulamasi/models/group/expense_group.dart';
import 'package:gelir_gider_uygulamasi/models/group/expense_model.dart';
import 'package:gelir_gider_uygulamasi/models/group/group_expense.dart';
import 'package:gelir_gider_uygulamasi/models/group/participant.dart';
import 'package:gelir_gider_uygulamasi/models/installment_purchase_model.dart';
import 'package:gelir_gider_uygulamasi/models/savings_goal.dart';
import 'package:gelir_gider_uygulamasi/modules/auth/widgets/forgot_password_sheet.dart';
import 'package:gelir_gider_uygulamasi/modules/auth/auth_controller.dart';
import 'package:gelir_gider_uygulamasi/services/account_service.dart';
import 'package:gelir_gider_uygulamasi/services/invite_link_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_theme.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// sahte AuthController (Firebase bağımlılığı olmadan UI ve performans testi için)
class TestableAuthController extends GetxController implements AuthController {
  @override
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  @override
  final GlobalKey<FormState> registerFormKey = GlobalKey<FormState>();
  @override
  final GlobalKey<FormState> resetFormKey = GlobalKey<FormState>();

  @override
  final TextEditingController loginEmailController = TextEditingController();
  @override
  final TextEditingController loginPasswordController = TextEditingController();
  @override
  final TextEditingController registerNameController = TextEditingController();
  @override
  final TextEditingController registerEmailController = TextEditingController();
  @override
  final TextEditingController registerPasswordController =
      TextEditingController();
  @override
  final TextEditingController registerConfirmPasswordController =
      TextEditingController();
  @override
  final TextEditingController resetEmailController = TextEditingController();

  @override
  final RxBool isResetLoading = false.obs;
  @override
  final RxnString resetEmailError = RxnString();
  @override
  final RxnString emailError = RxnString();
  @override
  final RxnString passwordError = RxnString();
  @override
  final RxnString confirmPasswordError = RxnString();

  int resetCallCount = 0;

  @override
  void clearResetEmailError() {
    if (resetEmailError.value != null) resetEmailError.value = null;
  }

  @override
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Lütfen e-posta adresinizi giriniz.";
    }
    if (!GetUtils.isEmail(value.trim())) {
      return "Lütfen geçerli bir e-posta adresi giriniz.";
    }
    return null;
  }

  @override
  Future<void> sendPasswordReset() async {
    if (isResetLoading.value) return;
    clearResetEmailError();
    if (!(resetFormKey.currentState?.validate() ?? false)) return;

    resetCallCount++;
    isResetLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 50));
    isResetLoading.value = false;
  }

  @override
  void onClose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    registerNameController.dispose();
    registerEmailController.dispose();
    registerPasswordController.dispose();
    registerConfirmPasswordController.dispose();
    resetEmailController.dispose();
    super.onClose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    final storage = StorgeService();
    await storage.init();
    Get.put<StorgeService>(storage, permanent: true);
  });

  // ===========================================================================
  // 1. FİNANSAL MANTIK & SINIR DURUM (EDGE CASE) TESTLERİ
  // ===========================================================================
  group('1. Finansal Mantık & Sınır Durum (Edge Case) Testleri', () {
    test('Ortak harcamada 0 kişiye bölünme, negatif ve NaN/Infinity koruması çalışır', () {
      final emptySplitExpense = ExpenseModel(
        id: 'exp_1',
        title: 'Elektrik Faturası',
        amount: 300.0,
        paidBy: 'Enes',
        splitMembers: const [],
        date: DateTime(2026, 10, 28),
      );
      expect(emptySplitExpense.perPersonAmount, equals(0.0));
      expect(emptySplitExpense.perPersonAmount.isNaN, isFalse);
      expect(emptySplitExpense.perPersonAmount.isInfinite, isFalse);

      // Bozuk / negatif veya sonsuz veri içeren Map parse koruması
      final corruptedNegative = ExpenseModel.fromMap({
        'title': 'Bozuk Veri',
        'amount': -500,
        'paidBy': 'Enes',
        'splitMembers': ['Enes', 'Ali'],
      });
      expect(corruptedNegative.amount, equals(0.0));
      expect(corruptedNegative.perPersonAmount, equals(0.0));

      final corruptedNaN = ExpenseModel.fromMap({
        'title': 'NaN Veri',
        'amount': double.nan,
        'paidBy': 'Enes',
        'splitMembers': ['Enes'],
      });
      expect(corruptedNaN.amount, equals(0.0));
    });

    test('100 TL tutarın 3 kişiye bölünmesinde kuruş sapması (Debt Simplification) hatasız çözülür', () {
      final participants = [
        const Participant(id: 'u1', name: 'Enes', isCurrentUser: true),
        const Participant(id: 'u2', name: 'Ahmet'),
        const Participant(id: 'u3', name: 'Mehmet'),
      ];

      final group = ExpenseGroup(
        id: 'grp_100',
        title: 'Ev Grubu',
        participants: participants,
        expenses: [
          GroupExpense(
            id: 'e1',
            title: 'İnternet',
            amount: 100.0,
            paidById: 'u1',
            date: DateTime(2026, 10, 28),
            splitParticipantIds: const ['u1', 'u2', 'u3'],
          ),
        ],
        createdAt: DateTime(2026, 10, 28),
      );

      final settlements = group.calculateSettlements();
      expect(settlements.length, equals(2));
      for (final s in settlements) {
        expect(s.toParticipantId, equals('u1'));
        expect(s.amount, equals(33.33));
      }
    });

    test('Taksit (Installment) ve Kumbara (SavingsGoal) 0 bölme ve taşma sınırlarını korur', () {
      final zeroInstallment = InstallmentPurchaseModel(
        id: 'i1',
        cardId: 'c1',
        title: 'Test',
        totalAmount: 5000.0,
        totalInstallments: 0,
        paidInstallments: 0,
        startDate: DateTime(2026, 10, 1),
      );
      expect(zeroInstallment.monthlyAmount, equals(0.0));
      expect(zeroInstallment.progress, equals(1.0));

      final zeroGoal = SavingsGoal(
        id: 'g1',
        title: 'Hedefsiz Kumbara',
        targetAmount: 0.0,
        savedAmount: 500.0,
      );
      expect(zeroGoal.progress, equals(0.0));
      expect(zeroGoal.remainingAmount, equals(0.0));

      final overGoal = SavingsGoal(
        id: 'g2',
        title: 'Tatil',
        targetAmount: 1000.0,
        savedAmount: 1500.0,
      );
      expect(overGoal.progress, equals(1.0)); // 1.0 üstüne taşmaz
      expect(overGoal.remainingAmount, equals(0.0));
    });

    test('AccountService.calculateBalances negatif, 0 ve NaN işlemleri filtreler', () {
      final accountService = Get.put(AccountService());
      final transactions = [
        AppTransaction(
          id: 't1',
          amount: '1000.0',
          type: 'income',
          categoryId: 'c1',
          userId: 'u1',
          createdAt: '',
          updatedAt: '',
          date: '2026-10-28',
          description: 'Maaş',
          paymentMethod: 'bank_card',
        ),
        AppTransaction(
          id: 't2',
          amount: '-250.0', // Geçersiz negatif tutar yoksayılmalı
          type: 'expense',
          categoryId: 'c2',
          userId: 'u1',
          createdAt: '',
          updatedAt: '',
          date: '2026-10-28',
          description: 'Hatalı',
          paymentMethod: 'cash',
        ),
        AppTransaction(
          id: 't3',
          amount: '300.0',
          type: 'expense',
          categoryId: 'c2',
          userId: 'u1',
          createdAt: '',
          updatedAt: '',
          date: '2026-10-28',
          description: 'Market',
          paymentMethod: 'bank_card',
        ),
      ];

      final balances = accountService.calculateBalances(transactions);
      expect(balances.bankIncome, equals(1000.0));
      expect(balances.bankExpense, equals(300.0));
      expect(balances.bankBalance, equals(700.0));
      expect(balances.cashExpense, equals(0.0));
    });
  });

  // ===========================================================================
  // 2. AĞ KESİNTİSİ & MÜKERRER İŞLEM (IDEMPOTENCY) TESTLERİ
  // ===========================================================================
  group('2. Ağ Kesintisi & Mükerrer İşlem (Idempotency) Testleri', () {
    testWidgets('Arka arkaya hızlı tıklamada (Double Tap) işlem sadece 1 kez tetiklenir', (tester) async {
      final authController = Get.put<AuthController>(TestableAuthController());
      final testable = authController as TestableAuthController;
      testable.resetEmailController.text = 'enes@hesaply.app';

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => const ForgotPasswordSheet(),
            ),
          ),
        ),
      );

      // Aynı anda 3 kez arka arkaya tetikle
      final f1 = testable.sendPasswordReset();
      final f2 = testable.sendPasswordReset();
      final f3 = testable.sendPasswordReset();
      await tester.pump(const Duration(milliseconds: 100));
      await Future.wait([f1, f2, f3]);
      await tester.pumpAndSettle();

      // Idempotency koruması sayesinde yalnızca 1 kez çalışmalı
      expect(testable.resetCallCount, equals(1));
    });
  });

  // ===========================================================================
  // 3. KLAVYE & EKRAN ÇEŞİTLİLİĞİ (UI / RESPONSIVE) TESTLERİ
  // ===========================================================================
  group('3. Klavye & Ekran Çeşitliliği (UI / Responsive) Testleri', () {
    testWidgets('ForgotPasswordSheet küçük ekranda, klavye açıkken ve %135 büyük fontta taşma (overflow) yapmaz', (tester) async {
      final authController = Get.put<AuthController>(TestableAuthController());

      // Küçük ekran (320x480) + Açık Klavye (bottom: 260) + Büyük Font (1.35x)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 480),
            viewInsets: EdgeInsets.only(bottom: 260),
            textScaler: TextScaler.linear(1.35),
          ),
          child: GetMaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(
              resizeToAvoidBottomInset: true,
              body: Align(
                alignment: Alignment.bottomCenter,
                child: ForgotPasswordSheet(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Hiçbir RenderFlex overflow hatası olmamalı
      expect(tester.takeException(), isNull);
      expect(find.text('Şifre Sıfırlama'), findsOneWidget);
      expect(find.text('Sıfırlama Bağlantısı Gönder'), findsOneWidget);

      // E-posta alanına metin girildiğinde her karakterde hata veya taşma olmamalı
      await tester.enterText(find.byType(TextFormField), 'test@hesaply.app');
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(authController.resetEmailController.text, equals('test@hesaply.app'));
    });

    testWidgets('ForgotPasswordSheet hem Açık (Light) hem Koyu (Dark) temada sorunsuz render edilir', (tester) async {
      Get.put<AuthController>(TestableAuthController());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ForgotPasswordSheet()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Şifre Sıfırlama'), findsOneWidget);
    });
  });

  // ===========================================================================
  // 4. OTURUM, GÜVENLİK VE MAĞAZA KURALLARI (STORE COMPLIANCE & DEEP LINK)
  // ===========================================================================
  group('4. Oturum, Güvenlik ve Mağaza Kuralları (Store Compliance)', () {
    test('InviteLinkService com.hesaply.app paket adıyla doğru Web ve Custom Scheme linki üretir', () {
      final service = InviteLinkService();

      expect(InviteLinkService.applicationId, equals('com.hesaply.app'));
      expect(
        InviteLinkService.playStoreUrl,
        equals('https://play.google.com/store/apps/details?id=com.hesaply.app'),
      );

      final webLink = service.buildWebInviteLink('decxxz', 'Serhat Ev');
      expect(webLink, contains('code=DECXXZ'));
      expect(webLink, contains('name=Serhat+Ev'));

      final customLink = service.buildCustomSchemeLink('decxxz');
      expect(customLink, equals('hesaply://join?code=DECXXZ'));

      final shareMsg = service.buildShareMessage(
        groupName: 'Serhat Ev',
        inviteCode: 'DECXXZ',
        inviterName: 'Enes',
      );
      expect(shareMsg, contains('Enes seni Hesaply uygulamasında "Serhat Ev"'));
      expect(shareMsg, contains('DECXXZ'));
      expect(shareMsg, contains(webLink));
    });

    test('Oturum kapalıyken gelen davet kodu pendingInviteCode olarak saklanır', () {
      final service = InviteLinkService();
      service.handleInviteCodeFromLink('ab23cd');
      expect(service.pendingInviteCode, equals('AB23CD'));
    });
  });

  // ===========================================================================
  // 5. PERFORMANS & BELLEK SIZINTISI (MEMORY LEAK) TESTİ
  // ===========================================================================
  group('5. Performans & Bellek Sızıntısı (Memory Leak) Testi', () {
    testWidgets('ForgotPasswordSheet yazma esnasında yalnızca izole alanları günceller, tüm ağacı yeniden çizmez', (tester) async {
      final controller = Get.put<AuthController>(TestableAuthController());
      int parentBuildCount = 0;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                parentBuildCount++;
                return const ForgotPasswordSheet();
              },
            ),
          ),
        ),
      );

      expect(parentBuildCount, equals(1));

      // Kullanıcı 15 karakterlik e-posta yazarken üst ağaç yeniden çizilmemeli
      final field = find.byType(TextFormField);
      await tester.enterText(field, 'enes@hesaply.ap');
      await tester.pump();
      await tester.enterText(field, 'enes@hesaply.app');
      await tester.pump();

      expect(parentBuildCount, equals(1));
      expect(controller.resetEmailController.text, equals('enes@hesaply.app'));
    });
  });

  // ===========================================================================
  // 6. RELEASE BUILD & YAPILANDIRMA TUTARLILIĞI TESTİ
  // ===========================================================================
  group('6. Release Build & Yapılandırma Tutarlılığı Testi', () {
    test('Firebase Android yapılandırması ve uygulama kimliği tutarlıdır', () {
      final androidOptions = DefaultFirebaseOptions.android;
      expect(androidOptions.projectId, equals('gelir-gider-app-9ae8f'));
      expect(
        androidOptions.appId,
        equals('1:991558928854:android:abfd2c9250751b42f07c77'),
      );
      expect(InviteLinkService.applicationId, equals('com.hesaply.app'));
    });
  });
}
