import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/group_detail/group_detail_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/group_detail/group_detail_page.dart';
import 'package:gelir_gider_uygulamasi/services/group_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:gelir_gider_uygulamasi/themes/app_theme.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    final storage = StorgeService();
    await storage.init();
    Get.put<StorgeService>(storage, permanent: true);
    final groupService = GroupService();
    Get.put<GroupService>(groupService, permanent: true);

    // Create group with participant 'faruk'
    final created = await groupService.createGroup(
      title: 'Tatil Masrafı',
      participantNames: ['faruk'],
    );

    // 'Sen' pays 500 TL for 'Sen' and 'faruk' -> faruk owes 250 TL
    await groupService.addExpense(
      groupId: created.id,
      title: 'Akşam Yemeği',
      amount: 500.0,
      paidById: created.currentUser!.id,
      splitParticipantIds: created.participants.map((p) => p.id).toList(),
    );
  });

  testWidgets('Settlement tab displays redesigned crystal clear transfer card', (tester) async {
    final groupService = Get.find<GroupService>();
    final group = groupService.groups.first;

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Get.to(
                  () => const GroupDetailPage(),
                  arguments: group.id,
                  binding: BindingsBuilder(() {
                    Get.lazyPut(() => GroupDetailController());
                  }),
                );
              },
              child: const Text("Go to Detail"),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to GroupDetailPage
    await tester.tap(find.text("Go to Detail"));
    await tester.pumpAndSettle();

    // Tap on 'Hesaplaşma' tab
    await tester.tap(find.text("Hesaplaşma"));
    await tester.pumpAndSettle();

    // Verify Faruk and Sen are present in the flow
    expect(find.text("faruk"), findsOneWidget);
    expect(find.text("Sen"), findsOneWidget);

    // Verify Amount (+₺250.00)
    expect(find.textContaining("250"), findsWidgets);

    // Bottom banner was removed per user request for sleekness
    expect(find.text("Alacağın Var"), findsNothing);

    // Verify 'Ödendi' checkbox is rendered and initially unchecked
    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsOneWidget);
    expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);

    // Tap checkbox to mark as paid
    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);
    expect(find.text("✓ Ödendi"), findsOneWidget);
    expect(find.textContaining("Ödeşildi"), findsOneWidget);
  });

  testWidgets('4-person group settlement tracks who paid via Ödendi checkboxes', (tester) async {
    final groupService = Get.find<GroupService>();

    final group4 = await groupService.createGroup(
      title: 'Kamp Grubu',
      participantNames: ['Ali', 'Veli', 'Ayşe'],
    );

    // 'Sen' pays 400 TL for 4 people (Sen, Ali, Veli, Ayşe) -> each owes 100 TL
    await groupService.addExpense(
      groupId: group4.id,
      title: 'Market Alışverişi',
      amount: 400.0,
      paidById: group4.currentUser!.id,
      splitParticipantIds: group4.participants.map((p) => p.id).toList(),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Get.to(
                  () => const GroupDetailPage(),
                  arguments: group4.id,
                  binding: BindingsBuilder(() {
                    Get.lazyPut(() => GroupDetailController());
                  }),
                );
              },
              child: const Text("Go to 4-Person Group"),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Go to 4-Person Group"));
    await tester.pumpAndSettle();

    // Open 'Hesaplaşma' tab
    await tester.tap(find.text("Hesaplaşma"));
    await tester.pumpAndSettle();

    // 3 settlement cards -> 3 checkboxes, progress "0 / 3"
    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsNWidgets(3));
    expect(find.text("0 / 3"), findsOneWidget);

    // Mark first participant as paid
    await tester.tap(checkboxes.first);
    await tester.pumpAndSettle();

    expect(find.text("1 / 3"), findsOneWidget);
    expect(find.text("✓ Ödendi"), findsOneWidget);

    // Remaining receivable should now be 200 TL instead of 300 TL
    final updatedGroup = groupService.groups.firstWhere((g) => g.id == group4.id);
    expect(updatedGroup.userNetBalance, closeTo(200.0, 0.01));
  });
}
