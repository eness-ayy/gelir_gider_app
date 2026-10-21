import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/core/app_bindings.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/credit_card_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/credit_card_detail_view.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/widgets/add_credit_card_sheet.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/widgets/credit_card_item.dart';
import 'package:gelir_gider_uygulamasi/routes/app_pages.dart';
import 'package:gelir_gider_uygulamasi/services/credit_card_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    final storage = StorgeService();
    await storage.init();
    Get.put<StorgeService>(storage, permanent: true);

    final cardService = CreditCardService();
    await cardService.init();
    Get.put<CreditCardService>(cardService, permanent: true);

    Get.put<CreditCardController>(CreditCardController(), permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('CreditCardView opens CreditCardDetailView without errors', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.creditCards,
        getPages: AppPages.pages,
        initialBinding: AppBindings(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify cards are present
    expect(find.byType(CreditCardItem), findsNWidgets(2));

    // Tap first card
    await tester.tap(find.byType(CreditCardItem).first);
    await tester.pumpAndSettle();

    // Advance 5 seconds
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.byType(CreditCardDetailView), findsOneWidget);

    // Scroll down in detail view
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    // Scroll up
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 300));
    await tester.pumpAndSettle();

    // Tap "Taksit Öde (+1)" if available
    final payBtn = find.text("Taksit Öde (+1)");
    if (payBtn.evaluate().isNotEmpty) {
      await tester.tap(payBtn.first);
      await tester.pumpAndSettle();
    }

    // Tap back button
    final backBtn = find.byType(BackButton);
    if (backBtn.evaluate().isNotEmpty) {
      await tester.tap(backBtn);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('AddCreditCardSheet renders live preview and allows day selection', (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: Center(
            child: AddCreditCardSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Live Preview initial placeholders
    expect(find.text("BANKA ADI"), findsOneWidget);
    expect(find.text("KART ADI"), findsOneWidget);
    expect(find.text("••••  ••••  ••••  0000"), findsOneWidget);

    // Enter card name
    await tester.enterText(
      find.widgetWithText(TextField, "Kart Adı (Örn: Bonus Platinum)"),
      "Test Platinum",
    );
    await tester.pump();
    expect(find.text("Test Platinum"), findsWidgets);

    // Enter limit
    await tester.enterText(
      find.widgetWithText(TextField, "Kart Limiti (₺)"),
      "45000",
    );
    await tester.pump();
    expect(find.textContaining("45.000"), findsWidgets);

    // Enter last 4 digits
    await tester.enterText(
      find.widgetWithText(TextField, "Son 4 Hane"),
      "1234",
    );
    await tester.pump();
    expect(find.text("••••  ••••  ••••  1234"), findsOneWidget);

    // Scroll and Tap Day Picker for Cutoff Day
    final cutoffButton = find.textContaining("Hesap Kesim");
    expect(cutoffButton, findsWidgets);
    await tester.ensureVisible(cutoffButton.first);
    await tester.pumpAndSettle();
    await tester.tap(cutoffButton.first);
    await tester.pumpAndSettle();

    // Select button in picker
    expect(find.text("Seç"), findsOneWidget);
    await tester.tap(find.text("Seç"));
    await tester.pumpAndSettle();

    // Scroll and submit form
    final saveBtn = find.text("Kartı Kaydet");
    await tester.ensureVisible(saveBtn);
    await tester.pumpAndSettle();
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Verify card was added to controller
    final controller = Get.find<CreditCardController>();
    expect(controller.cards.any((c) => c.cardName == "Test Platinum"), isTrue);
  });
}
