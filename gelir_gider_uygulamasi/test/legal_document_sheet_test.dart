import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/widgets/legal_document_sheet.dart';
import 'package:gelir_gider_uygulamasi/themes/app_theme.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('LegalDocumentSheet shows Terms of Service with correct articles and closes on Anladım', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => LegalDocumentSheet.showTerms(context),
                child: const Text("Open Terms"),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Open Terms"));
    await tester.pumpAndSettle();

    expect(find.byType(LegalDocumentSheet), findsOneWidget);
    expect(find.text("Kullanım Koşulları"), findsOneWidget);
    expect(find.text("Hizmetin Niteliği ve Kapsamı"), findsOneWidget);
    expect(find.text("Fikri Mülkiyet Hakları"), findsOneWidget);

    // Tap Anladım to dismiss
    await tester.tap(find.text("Anladım"));
    await tester.pumpAndSettle();

    expect(find.byType(LegalDocumentSheet), findsNothing);
  });

  testWidgets('LegalDocumentSheet shows Privacy Policy with correct articles and closes via close icon', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => LegalDocumentSheet.showPrivacy(context),
                child: const Text("Open Privacy"),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Open Privacy"));
    await tester.pumpAndSettle();

    expect(find.byType(LegalDocumentSheet), findsOneWidget);
    expect(find.text("Gizlilik Politikası"), findsOneWidget);
    expect(find.text("Toplanan Bilgiler ve Veri Türleri"), findsOneWidget);
    expect(find.text("Verilerin Kullanım Amaçları"), findsOneWidget);

    // Tap close icon
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(LegalDocumentSheet), findsNothing);
  });
}
