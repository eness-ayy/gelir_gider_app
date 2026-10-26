import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/utils/turkish_string_helper.dart';

final List<String> icons = [
  'wallet',
  'cash',
  'trending-up',
  'cart',
  'receipt',
  'bus',
  'medical',
  'school',
  'game-controller',
  'restaurant',
  'family',
  'shopping-bag',
  'home',
  'autorenew',
  'credit-card',
  'content-cut',
  'more',
  'savings',
  'call-received',
];

String getCategoryIconLabel(String iconName) {
  switch (iconName) {
    case 'wallet':
      return 'Cüzdan';
    case 'cash':
      return 'Nakit / Maaş';
    case 'trending-up':
      return 'Gelir / Yatırım';
    case 'cart':
      return 'Market / Sepet';
    case 'receipt':
      return 'Fatura / Makbuz';
    case 'bus':
      return 'Ulaşım / Otobüs';
    case 'medical':
      return 'Sağlık / Medikal';
    case 'school':
      return 'Eğitim / Burs';
    case 'game-controller':
      return 'Eğlence / Oyun';
    case 'restaurant':
      return 'Yemek / Restoran';
    case 'family':
      return 'Aile';
    case 'shopping-bag':
      return 'Alışveriş / Giyim';
    case 'home':
      return 'Kira & Ev';
    case 'autorenew':
      return 'Abonelikler';
    case 'credit-card':
      return 'Borç / Kredi';
    case 'content-cut':
      return 'Kişisel Bakım';
    case 'more':
      return 'Diğer / Çeşitli';
    case 'savings':
      return 'Birikim / Harçlık';
    case 'call-received':
      return 'İade / Alacak';
    default:
      return iconName;
  }
}

IconData? _matchIconByName(String cleanIcon) {
  switch (cleanIcon) {
    case 'bus':
    case 'directions_bus':
    case 'directions-bus':
      return Icons.directions_bus;
    case 'directions_car':
    case 'directions-car':
    case 'car':
      return Icons.directions_car_rounded;
    case 'cart':
    case 'shopping_cart':
    case 'shopping-cart':
      return Icons.shopping_cart_rounded;
    case 'cash':
    case 'attach_money':
    case 'attach-money':
      return Icons.attach_money;
    case 'game-controller':
    case 'game_controller':
    case 'games':
    case 'sports_esports':
    case 'sports-esports':
      return Icons.sports_esports_rounded;
    case 'medical':
    case 'local_hospital':
    case 'local-hospital':
      return Icons.local_hospital;
    case 'restaurant':
      return Icons.restaurant;
    case 'school':
      return Icons.school_rounded;
    case 'family':
      return Icons.family_restroom;
    case 'wallet':
    case 'account_balance_wallet':
    case 'account-balance-wallet':
      return Icons.account_balance_wallet;
    case 'trending-up':
    case 'trending_up':
      return Icons.trending_up;
    case 'show_chart':
    case 'show-chart':
      return Icons.show_chart;
    case 'shopping-bag':
    case 'shopping_bag':
    case 'bag':
      return Icons.shopping_bag_rounded;
    case 'checkroom':
      return Icons.checkroom_rounded;
    case 'home':
    case 'house':
      return Icons.home_rounded;
    case 'receipt':
    case 'receipt_long':
    case 'receipt-long':
      return Icons.receipt_long_rounded;
    case 'autorenew':
    case 'subscriptions':
      return Icons.autorenew_rounded;
    case 'credit-card':
    case 'credit_card':
    case 'card':
    case 'payments':
      return Icons.credit_card_rounded;
    case 'content-cut':
    case 'content_cut':
    case 'spa':
    case 'personal-care':
      return Icons.content_cut_rounded;
    case 'more':
    case 'more_horiz':
    case 'more-horiz':
      return Icons.more_horiz_rounded;
    case 'savings':
      return Icons.savings_rounded;
    case 'call-received':
    case 'call_received':
      return Icons.call_received_rounded;
    default:
      return null;
  }
}

IconData? _matchIconByKeyword(String text) {
  final norm = TurkishStringHelper.normalizeForSearch(text);

  if (norm.contains('alisveris') && norm.contains('giyim')) {
    return Icons.shopping_bag_rounded;
  }
  if (norm.contains('market') || norm.contains('gida')) {
    return Icons.shopping_cart_rounded;
  }
  if (norm.contains('yeme') ||
      norm.contains('icme') ||
      norm.contains('restoran') ||
      norm.contains('yemek')) {
    return Icons.restaurant;
  }
  if (norm.contains('fatura')) {
    return Icons.receipt_long_rounded;
  }
  if (norm.contains('abonelik')) {
    return Icons.autorenew_rounded;
  }
  if (norm.contains('ulasim') ||
      norm.contains('yakit') ||
      norm.contains('araba')) {
    return Icons.directions_car_rounded;
  }
  if (norm.contains('ev') || norm.contains('yasam') || norm.contains('kira')) {
    return Icons.home_rounded;
  }
  if (norm.contains('giyim') || norm.contains('aksesuar')) {
    return Icons.checkroom_rounded;
  }
  if (norm.contains('alisveris')) {
    return Icons.shopping_bag_rounded;
  }
  if (norm.contains('saglik')) {
    return Icons.local_hospital;
  }
  if (norm.contains('eglence') ||
      norm.contains('hobi') ||
      norm.contains('oyun')) {
    return Icons.sports_esports_rounded;
  }
  if (norm.contains('egitim') ||
      norm.contains('gelisim') ||
      norm.contains('okul')) {
    return Icons.school_rounded;
  }
  if (norm.contains('diger') ||
      norm.contains('harcama') ||
      norm.contains('cesitli')) {
    return Icons.more_horiz_rounded;
  }
  if (norm.contains('borc') || norm.contains('kredi')) {
    return Icons.credit_card_rounded;
  }
  if (norm.contains('kisisel') ||
      norm.contains('kuafor') ||
      norm.contains('berber') ||
      norm.contains('bakim')) {
    return Icons.content_cut_rounded;
  }
  if (norm.contains('burs') || norm.contains('harclik')) {
    return Icons.school_rounded;
  }
  if (norm.contains('iade') || norm.contains('alacak')) {
    return Icons.call_received_rounded;
  }
  if (norm.contains('maas')) {
    return Icons.attach_money;
  }
  if (norm.contains('yatirim') || norm.contains('ek gelir')) {
    return Icons.trending_up;
  }
  if (norm.contains('aile')) {
    return Icons.family_restroom;
  }
  if (norm.contains('tasarruf') || norm.contains('birikim')) {
    return Icons.savings_rounded;
  }
  return null;
}

IconData getCategoryIcon({
  required String iconName,
  required bool isSystem,
  required String type,
  String? categoryName,
}) {
  final cleanIcon = iconName.trim().toLowerCase();

  // 1. Eğer özel bir ikon adı varsa (receipt/category gibi genel varsayılanlar hariç)
  if (cleanIcon.isNotEmpty &&
      cleanIcon != 'receipt' &&
      cleanIcon != 'category') {
    final directIcon = _matchIconByName(cleanIcon);
    if (directIcon != null) return directIcon;
  }

  // 2. Kategori adı üzerinden akıllı eşleştirme (özellikle varsayılan iconlu kategoriler için)
  if (categoryName != null && categoryName.trim().isNotEmpty) {
    final nameIcon = _matchIconByKeyword(categoryName);
    if (nameIcon != null) return nameIcon;
  }

  // 3. İkon adı 'receipt' ise ve kategori adı başka bir şeye uymadıysa receipt döndür
  if (cleanIcon == 'receipt') {
    return Icons.receipt;
  }

  // 4. İkon adının kendisi bir anahtar kelime içeriyorsa
  final fallbackIcon = _matchIconByKeyword(cleanIcon);
  if (fallbackIcon != null) return fallbackIcon;

  // 5. Varsayılan
  final cleanType = type.trim().toLowerCase();
  if (cleanType == 'income' || cleanType == 'gelir') {
    return Icons.trending_up;
  }
  return Icons.category_rounded;
}
