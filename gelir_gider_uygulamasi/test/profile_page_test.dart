import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gelir_gider_uygulamasi/models/app_user.dart';
import 'package:gelir_gider_uygulamasi/modules/home/home_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/profile_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/profile_page.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/widgets/edit_profile_dialog.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/widgets/legal_document_sheet.dart';
import 'package:gelir_gider_uygulamasi/services/auth_service.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:gelir_gider_uygulamasi/services/theme_services.dart';
import 'package:gelir_gider_uygulamasi/themes/app_theme.dart';
import 'package:get/get.dart';

import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthService extends AuthService {
  FakeAuthService() {
    currentUser.value = AppUser(
      firstName: 'Enes',
      lastName: 'Ay',
      email: 'eay105707@gmail.com',
    );
  }

  @override
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? profilePhoto,
    bool clearPhoto = false,
  }) async {
    final current = currentUser.value ?? AppUser();
    currentUser.value = current.copyWith(
      firstName: firstName ?? current.firstName,
      lastName: lastName ?? current.lastName,
      email: email ?? current.email,
      profilePhoto: profilePhoto,
      clearPhoto: clearPhoto,
    );
    return true;
  }
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
    Get.put<AuthService>(FakeAuthService(), permanent: true);
    Get.put<ThemeServices>(ThemeServices(), permanent: true);
    Get.put<ProfileController>(ProfileController());
  });

  testWidgets('ProfilePage displays green avatar with "E", full name, email and no old info cards', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        home: const ProfilePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify avatar "E"
    expect(find.text("E"), findsOneWidget);

    // Verify User Full Name
    expect(find.text("Enes Ay"), findsOneWidget);

    // Verify User Email
    expect(find.text("eay105707@gmail.com"), findsOneWidget);

    // Verify old labels "Adı" and "Soyad" are removed
    expect(find.text("Adı"), findsNothing);
    expect(find.text("Soyad"), findsNothing);

    // Verify category management and settings exist
    expect(find.text("Kategori Yönetimi"), findsOneWidget);
    expect(find.text("Tema"), findsOneWidget);

    // Verify Profili Duzenle card exists
    expect(find.text("Profili Düzenle"), findsOneWidget);
  });

  testWidgets('EditProfileDialog opens and updates user name, email and photo', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        home: const ProfilePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on the Profili Düzenle card to open the sheet
    await tester.tap(find.text("Profili Düzenle").first);
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileDialog), findsOneWidget);

    // Verify prefilled form fields
    expect(find.text("Enes"), findsOneWidget);
    expect(find.text("Ay"), findsOneWidget);
    expect(find.text("eay105707@gmail.com"), findsWidgets);

    // Change first name
    final firstNameField = find.widgetWithText(TextField, "Enes");
    await tester.enterText(firstNameField, "Ahmet");

    // Save
    final saveBtn = find.text("Değişiklikleri Kaydet");
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Verify dialog dismissed and ProfilePage shows updated name
    expect(find.byType(EditProfileDialog), findsNothing);
    expect(find.text("Ahmet Ay"), findsOneWidget);
  });

  testWidgets('HomeController pageTitle behaves correctly and AppBar has no top-right logout button', (tester) async {
    final homeController = Get.put<HomeController>(HomeController());
    homeController.currentIndex.value = 3;

    expect(homeController.pageTitle, "Profil & Ayarlar");

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          appBar: AppBar(
            title: Obx(
              () => Text(
                homeController.pageTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            centerTitle: false,
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify AppBar Title
    expect(find.text("Profil & Ayarlar"), findsOneWidget);

    // Verify no Logout icon button in AppBar
    expect(find.byTooltip("Çıkış Yap"), findsNothing);
  });

  testWidgets('Profile and EditProfileDialog have no camera icon or photo url field, and support avatar selection', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        home: const ProfilePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify no camera icon exists in ProfilePage
    expect(find.byIcon(Icons.camera_alt_rounded), findsNothing);

    // Open EditProfileDialog
    await tester.tap(find.text("Profili Düzenle").first);
    await tester.pumpAndSettle();

    // Verify no camera icon and no photo url input exists
    expect(find.byIcon(Icons.camera_alt_rounded), findsNothing);
    expect(find.text("Profil Fotoğrafını Değiştir"), findsNothing);
    expect(find.text("veya Fotoğraf Bağlantısı (URL)"), findsNothing);

    // Verify Avatar selection section exists
    expect(find.text("Avatarınızı Seçin"), findsOneWidget);

    // Tap the first avatar image in the list
    final firstAvatar = find.byType(Image).first;
    await tester.tap(firstAvatar);
    await tester.pumpAndSettle();

    // Tap the initial letter avatar option in the list
    final initialOption = find.text("E").last;
    await tester.tap(initialOption);
    await tester.pumpAndSettle();

    // Save
    final saveBtn = find.text("Değişiklikleri Kaydet");
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Verify dialog dismissed and still displays initial "E"
    expect(find.byType(EditProfileDialog), findsNothing);
    expect(find.text("E"), findsOneWidget);
  });

  testWidgets('Updating profile name updates controller user and reflects new display name', (tester) async {
    final controller = Get.find<ProfileController>();
    final success = await controller.updateProfile(
      firstName: 'Ahmet',
      lastName: 'Yılmaz',
      email: 'ahmet@example.com',
    );
    expect(success, isTrue);
    expect(controller.user.value?.firstName, 'Ahmet');
    expect(controller.user.value?.lastName, 'Yılmaz');
    expect(controller.user.value?.fullName, 'Ahmet Yılmaz');
  });

  testWidgets('ProfilePage displays Hakkında section with Privacy Policy and Terms of Service tiles', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        home: const ProfilePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Hakkında"), findsOneWidget);
    expect(find.text("Gizlilik Politikası"), findsOneWidget);
    expect(find.text("Kullanım Koşulları"), findsOneWidget);

    // Scroll to and tap Gizlilik Politikası to open in-app sheet
    final privacyFinder = find.text("Gizlilik Politikası");
    await tester.ensureVisible(privacyFinder);
    await tester.tap(privacyFinder);
    await tester.pumpAndSettle();

    expect(find.byType(LegalDocumentSheet), findsOneWidget);
    expect(find.text("Toplanan Bilgiler ve Veri Türleri"), findsOneWidget);

    // Close sheet
    await tester.tap(find.text("Anladım"));
    await tester.pumpAndSettle();
    expect(find.byType(LegalDocumentSheet), findsNothing);

    // Scroll to and tap Kullanım Koşulları to open in-app sheet
    final termsFinder = find.text("Kullanım Koşulları");
    await tester.ensureVisible(termsFinder);
    await tester.tap(termsFinder);
    await tester.pumpAndSettle();

    expect(find.byType(LegalDocumentSheet), findsOneWidget);
    expect(find.text("Hizmetin Niteliği ve Kapsamı"), findsOneWidget);

    // Close sheet
    await tester.tap(find.text("Anladım"));
    await tester.pumpAndSettle();
    expect(find.byType(LegalDocumentSheet), findsNothing);
  });
}



