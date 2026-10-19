import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/groups_controller.dart';
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
}
