import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/groups_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/groups_page.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/widgets/create_group_dialog.dart';
import 'package:gelir_gider_uygulamasi/services/group_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gelir_gider_uygulamasi/themes/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    final storage = StorgeService();
    await storage.init();
    Get.put<StorgeService>(storage, permanent: true);
    Get.put<GroupService>(GroupService(), permanent: true);
    Get.put<GroupsController>(GroupsController());
  });

  testWidgets('CreateGroupDialog opens, adds participant, removes, submits without crash or freeze', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CreateGroupDialog.show(context),
              child: const Text("Open Dialog"),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Open Dialog
    await tester.tap(find.text("Open Dialog"));
    await tester.pumpAndSettle();

    expect(find.byType(CreateGroupDialog), findsOneWidget);

    // 2. Add extra participant field
    await tester.tap(find.text("Kişi Ekle"));
    await tester.pumpAndSettle();

    // 3. Remove a participant field
    final removeButtons = find.byIcon(Icons.remove_circle_outline);
    expect(removeButtons, findsWidgets);
    await tester.tap(removeButtons.first);
    await tester.pumpAndSettle();

    // 4. Enter group name
    final nameField = find.widgetWithText(TextField, "Örn: Ev Arkadaşları, Antalya Tatili");
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, "Kapadokya Gezisi");
    await tester.pumpAndSettle();

    // 5. Submit form
    final submitButton = find.text("Grup Oluştur");
    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // 6. Verify Dialog closed and group was saved
    expect(find.byType(CreateGroupDialog), findsNothing);

    final groupService = Get.find<GroupService>();
    final created = groupService.groups.firstWhere((g) => g.title == "Kapadokya Gezisi");
    expect(created, isNotNull);
    expect(created.participants.length, greaterThanOrEqualTo(1));
  });

  testWidgets('CreateGroupDialog works in dark theme without rendering/layout exception', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CreateGroupDialog.show(context),
              child: const Text("Open Dialog"),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Open Dialog"));
    await tester.pumpAndSettle();
    expect(find.byType(CreateGroupDialog), findsOneWidget);

    final nameField = find.widgetWithText(TextField, "Örn: Ev Arkadaşları, Antalya Tatili");
    await tester.enterText(nameField, "Olimpos Kampı");
    await tester.pumpAndSettle();

    final submitButton = find.text("Grup Oluştur");
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.byType(CreateGroupDialog), findsNothing);
  });

  testWidgets('GroupsPage shows Empty State when list is empty, then transitions to card list when group is created', (tester) async {
    final groupService = Get.find<GroupService>();
    groupService.groups.clear();

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: GroupsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Empty State elements
    expect(find.text("Gruplarım (0)"), findsOneWidget);
    expect(find.text("+ Yeni Ekle"), findsNothing); // Sağ üstteki buton gizli olmalı
    expect(find.text("İlk Grup Harcamanı Ekle"), findsOneWidget);
    expect(find.text("Arkadaşlarınla yaptığın etkinlikleri, tatil veya ev masraflarını bölüşmek için hemen başla."), findsOneWidget);
    expect(find.text("Grup Harcaması Oluştur"), findsOneWidget);

    // 2. Click "Grup Harcaması Oluştur" to open dialog
    await tester.tap(find.text("Grup Harcaması Oluştur"));
    await tester.pumpAndSettle();

    expect(find.byType(CreateGroupDialog), findsOneWidget);

    // 3. Enter group name and submit
    final nameField = find.widgetWithText(TextField, "Örn: Ev Arkadaşları, Antalya Tatili");
    await tester.enterText(nameField, "Bolu Yedigöller Gezisi");
    await tester.pumpAndSettle();

    final submitBtn = find.text("Grup Oluştur");
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // 4. Verify Empty State is removed and Filled State is visible
    expect(find.text("İlk Grup Harcamanı Ekle"), findsNothing);
    expect(find.text("Grup Harcaması Oluştur"), findsNothing);

    // 5. Verify Secondary Header updated
    expect(find.text("Gruplarım (1)"), findsOneWidget);
    expect(find.text("+ Yeni Ekle"), findsOneWidget); // Artık görünür

    // 6. Verify Card details
    expect(find.text("Bolu Yedigöller Gezisi"), findsOneWidget);
    expect(find.textContaining("Katılımcı"), findsOneWidget);
    expect(find.text("Toplam Harcama"), findsOneWidget);
    expect(find.text("✓ Ödeşildi"), findsOneWidget);
  });
}
