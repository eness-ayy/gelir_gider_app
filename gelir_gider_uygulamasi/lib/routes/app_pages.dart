import 'package:gelir_gider_uygulamasi/modules/groups/group_detail/group_detail_binding.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/group_detail/group_detail_page.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/groups_page.dart';
import 'package:gelir_gider_uygulamasi/modules/home/home_binding.dart';
import 'package:gelir_gider_uygulamasi/modules/home/home_page.dart';
import 'package:gelir_gider_uygulamasi/modules/login/login_binding.dart';
import 'package:gelir_gider_uygulamasi/modules/login/login_page.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/profile_binding.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/profile_page.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/reports_binding.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/reports_page.dart';
import 'package:gelir_gider_uygulamasi/modules/splash/splash_binding.dart';
import 'package:gelir_gider_uygulamasi/modules/splash/splash_page.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/transaction_bindings.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/transaction_page.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

abstract class AppRoutes {
  static const initial = splash;
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const profile = '/profile';
  static const transaction = '/transactions';
  static const reports = '/reports';
  static const groups = '/groups';
  static const groupDetail = '/group-detail';

  // Geriye dönük uyumluluk
  // ignore: constant_identifier_names
  static const INITIAL = initial;
  // ignore: constant_identifier_names
  static const SPLASH = splash;
  // ignore: constant_identifier_names
  static const LOGIN = login;
  // ignore: constant_identifier_names
  static const HOME = home;
  // ignore: constant_identifier_names
  static const PROFILE = profile;
  // ignore: constant_identifier_names
  static const TRANSACTION = transaction;
  // ignore: constant_identifier_names
  static const REPORTS = reports;
  // ignore: constant_identifier_names
  static const GROUPS = groups;
  // ignore: constant_identifier_names
  static const GROUP_DETAIL = groupDetail;
}

class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.transaction,
      page: () => const TransactionPage(),
      binding: TransactionBindings(),
    ),
    GetPage(
      name: AppRoutes.reports,
      page: () => const ReportsPage(),
      binding: ReportsBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.groups,
      page: () => const GroupsPage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.groupDetail,
      page: () => const GroupDetailPage(),
      binding: GroupDetailBinding(),
    ),
  ];
}
