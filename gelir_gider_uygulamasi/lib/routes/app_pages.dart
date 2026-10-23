import 'package:gelir_gider_uygulamasi/models/credit_card_model.dart';
import 'package:gelir_gider_uygulamasi/modules/auth/auth_binding.dart';
import 'package:gelir_gider_uygulamasi/modules/auth/auth_page.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/credit_card_detail_view.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/credit_cards/credit_card_view.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/debts/debts_page.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/extra_binding.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/extra_view.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/recurring/recurring_transactions_page.dart';
import 'package:gelir_gider_uygulamasi/modules/extra/savings/savings_goals_page.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/group_detail/group_detail_binding.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/group_detail/group_detail_page.dart';
import 'package:gelir_gider_uygulamasi/modules/groups/groups_page.dart';
import 'package:gelir_gider_uygulamasi/modules/home/home_binding.dart';
import 'package:gelir_gider_uygulamasi/modules/home/home_page.dart';

import 'package:gelir_gider_uygulamasi/modules/profile/profile_binding.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/profile_page.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/reports_binding.dart';
import 'package:gelir_gider_uygulamasi/modules/reports/reports_page.dart';
import 'package:gelir_gider_uygulamasi/modules/shared_budget/detail/shared_budget_detail_binding.dart';
import 'package:gelir_gider_uygulamasi/modules/shared_budget/detail/shared_budget_detail_page.dart';
import 'package:gelir_gider_uygulamasi/modules/shared_budget/shared_budget_binding.dart';
import 'package:gelir_gider_uygulamasi/modules/shared_budget/shared_budget_page.dart';
import 'package:gelir_gider_uygulamasi/modules/splash/splash_binding.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/transaction_bindings.dart';
import 'package:gelir_gider_uygulamasi/modules/transaction/transaction_page.dart';
import 'package:gelir_gider_uygulamasi/views/splash/splash_view.dart';
import 'package:get/get.dart';

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
  static const extra = '/extra';
  static const savingsGoals = '/savings-goals';
  static const debts = '/debts';
  static const recurringTransactions = '/recurring-transactions';
  static const creditCards = '/credit-cards';
  static const creditCardDetail = '/credit-card-detail';
  static const sharedBudget = '/shared-budget';
  static const sharedBudgetDetail = '/shared-budget-detail';
  static const auth = '/auth';

  // Geriye dönük uyumluluk
  // ignore: constant_identifier_names
  static const INITIAL = initial;
  // ignore: constant_identifier_names
  static const SPLASH = splash;
  // ignore: constant_identifier_names
  static const LOGIN = login;
  // ignore: constant_identifier_names
  static const AUTH = auth;
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
  // ignore: constant_identifier_names
  static const EXTRA = extra;
  // ignore: constant_identifier_names
  static const SAVINGS_GOALS = savingsGoals;
  // ignore: constant_identifier_names
  static const DEBTS = debts;
  // ignore: constant_identifier_names
  static const RECURRING_TRANSACTIONS = recurringTransactions;
}

class AppPages {
  /// AppPages.routes ve AppPages.pages ikili desteği
  static List<GetPage> get routes => pages;

  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const AuthPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthPage(),
      binding: AuthBinding(),
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
    GetPage(
      name: AppRoutes.extra,
      page: () => const ExtraView(),
      binding: ExtraBinding(),
    ),
    GetPage(
      name: AppRoutes.savingsGoals,
      page: () => const SavingsGoalsPage(),
    ),
    GetPage(
      name: AppRoutes.debts,
      page: () => const DebtsPage(),
    ),
    GetPage(
      name: AppRoutes.recurringTransactions,
      page: () => const RecurringTransactionsPage(),
    ),
    GetPage(
      name: AppRoutes.creditCards,
      page: () => const CreditCardView(),
    ),
    GetPage(
      name: AppRoutes.creditCardDetail,
      page: () {
        final card = Get.arguments as CreditCardModel;
        return CreditCardDetailView(card: card);
      },
    ),
    GetPage(
      name: AppRoutes.sharedBudget,
      page: () => const SharedBudgetPage(),
      binding: SharedBudgetBinding(),
    ),
    GetPage(
      name: AppRoutes.sharedBudgetDetail,
      page: () => const SharedBudgetDetailPage(),
      binding: SharedBudgetDetailBinding(),
    ),
  ];
}
