import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/extra_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/extra_view.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/widgets/guest_feature_dialog.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:gelir_gider_uygulamasi/services/theme_services.dart';
import 'package:gelir_gider_uygulamasi/themes/app_theme.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    await Get.putAsync<StorgeService>(() async => await StorgeService().init());
    Get.put<ThemeServices>(ThemeServices(), permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  group('Guest Restriction Unit Tests', () {
    test('When isGuest is true, isGuest flag is correctly reflected', () {
      final controller = Get.put(ExtraController());
      controller.debugIsGuest = true;
      controller.isGuest.value = true;

      expect(controller.isGuest.value, isTrue);
    });

    test('When isGuest is false, isGuest flag is correctly reflected', () {
      final controller = Get.put(ExtraController());
      controller.debugIsGuest = false;
      controller.isGuest.value = false;

      expect(controller.isGuest.value, isFalse);
    });
  });

  group('GuestFeatureDialog Widget Tests', () {
    testWidgets(
        'GuestFeatureDialog displays concise title, description and actions',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    GuestFeatureDialog.show(
                      context,
                      title: "Grup Harcamaları",
                      featureName: "Grup Harcamaları",
                      description: "Lütfen giriş yapın veya hesap oluşturun.",
                      icon: Icons.groups_rounded,
                      accentColor: const Color(0xFF2563EB),
                    );
                  },
                  child: const Text('Aç'),
                );
              },
            ),
          ),
        ),
      );

      // Dialogu aç
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      // İçerikleri doğrula
      expect(find.text('Grup Harcamaları İçin Giriş Yapın'), findsOneWidget);
      expect(find.text('Lütfen giriş yapın veya hesap oluşturun.'), findsOneWidget);
      expect(find.text('Giriş Yap / Kayıt Ol'), findsOneWidget);
      expect(find.text('Vazgeç'), findsOneWidget);

      // "Vazgeç" butonuna basınca dialog kapanmalı
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(find.text('Grup Harcamaları İçin Giriş Yapın'), findsNothing);
    });
  });

  group('ExtraView Guest Behavior Widget Tests', () {
    testWidgets(
        'When user is guest, tap shows concise dialog without navigation',
        (tester) async {
      final controller = Get.put(ExtraController());
      controller.debugIsGuest = true;
      controller.isGuest.value = true;

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.dark,
          home: const ExtraView(),
        ),
      );
      await tester.pumpAndSettle();

      // "Giriş Gerekli" rozeti olmamalı
      expect(find.text('Giriş Gerekli'), findsNothing);

      // Grup Harcamaları kartına tıkla
      await tester.tap(find.text('Grup Harcamaları'));
      await tester.pumpAndSettle();

      // Bilgilendirme diyaloğu açılmalı
      expect(find.text('Grup Harcamaları İçin Giriş Yapın'), findsOneWidget);
      expect(find.byType(GuestFeatureDialog), findsOneWidget);

      // Kapat
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(find.byType(GuestFeatureDialog), findsNothing);

      // Ortak Hesap kartına tıkla
      await tester.tap(find.text('Ortak Hesap'));
      await tester.pumpAndSettle();

      // Ortak Hesap bilgilendirme diyaloğu açılmalı
      expect(find.text('Ortak Hesap İçin Giriş Yapın'), findsOneWidget);
      expect(find.byType(GuestFeatureDialog), findsOneWidget);
    });
  });
}
