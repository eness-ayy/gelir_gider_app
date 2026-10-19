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
      return Icons.directions_bus;
    case 'cart':
      return Icons.shopping_cart;
    case 'cash':
      return Icons.attach_money;
    case 'game-controller':
    case 'game_controller':
    case 'games':
      return Icons.games;
    case 'medical':
      return Icons.local_hospital;
    case 'restaurant':
      return Icons.restaurant;
    case 'school':
      return Icons.school_rounded;
    case 'family':
      return Icons.family_restroom;
    case 'wallet':
      return Icons.account_balance_wallet;
    case 'trending-up':
    case 'trending_up':
      return Icons.trending_up;
    case 'shopping-bag':
    case 'shopping_bag':
    case 'bag':
      return Icons.shopping_bag_rounded;
    case 'home':
    case 'house':
      return Icons.home_rounded;
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

  if (norm.contains('alisveris') || norm.contains('giyim')) {
    return Icons.shopping_bag_rounded;
  }
  if (norm.contains('kira') || norm.contains('ev')) {
    return Icons.home_rounded;
  }
  if (norm.contains('abonelik')) {
    return Icons.autorenew_rounded;
  }
  if (norm.contains('borc') || norm.contains('kredi')) {
    return Icons.credit_card_rounded;
  }
  if (norm.contains('kisisel') ||
      norm.contains('bakim') ||
      norm.contains('kuafor') ||
      norm.contains('berber')) {
    return Icons.content_cut_rounded;
  }
  if (norm.contains('diger') || norm.contains('cesitli')) {
    return Icons.more_horiz_rounded;
  }
  if (norm.contains('burs') || norm.contains('harclik')) {
    return Icons.school_rounded;
  }
  if (norm.contains('iade') || norm.contains('alacak')) {
    return Icons.call_received_rounded;
  }
  if (norm.contains('market')) {
    return Icons.shopping_cart;
  }
  if (norm.contains('ulasim')) {
    return Icons.directions_bus;
  }
  if (norm.contains('fatura')) {
    return Icons.receipt;
  }
  if (norm.contains('eglence')) {
    return Icons.games;
  }
  if (norm.contains('saglik')) {
    return Icons.local_hospital;
  }
  if (norm.contains('yemek') || norm.contains('restoran')) {
    return Icons.restaurant;
  }
  if (norm.contains('maas')) {
    return Icons.attach_money;
  }
  if (norm.contains('yatirim') || norm.contains('ek gelir')) {
    return Icons.trending_up;
  }
  if (norm.contains('egitim')) {
    return Icons.school_rounded;
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
  if (cleanIcon.isNotEmpty && cleanIcon != 'receipt' && cleanIcon != 'category') {
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