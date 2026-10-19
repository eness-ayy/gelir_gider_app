import 'package:flutter/material.dart';

enum PaymentMethod {
  cash(
    key: 'cash',
    title: 'Nakit',
    subtitle: 'Cebimdeki Nakit',
    icon: Icons.payments_outlined,
    color: Color(0xFF00897B), // Teal / Zümrüt
  ),
  bankCard(
    key: 'bank_card',
    title: 'Banka Kartı',
    subtitle: 'Bankadaki Param',
    icon: Icons.account_balance_outlined,
    color: Color(0xFF1E88E5), // Mavi
  ),
  creditCard(
    key: 'credit_card',
    title: 'Kredi Kartı',
    subtitle: 'Kredi Kartı Harcaması',
    icon: Icons.credit_card_outlined,
    color: Color(0xFF8E24AA), // Mor
  );

  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const PaymentMethod({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  static PaymentMethod fromKey(String? rawKey, {PaymentMethod defaultMethod = PaymentMethod.cash}) {
    if (rawKey == null || rawKey.trim().isEmpty) return defaultMethod;
    final normalized = rawKey.toLowerCase().trim();

    switch (normalized) {
      case 'bank_card':
      case 'banka':
      case 'banka_karti':
      case 'bank':
      case 'debit':
      case 'debit_card':
        return PaymentMethod.bankCard;
      case 'credit_card':
      case 'kredi':
      case 'kredi_karti':
      case 'credit':
        return PaymentMethod.creditCard;
      case 'cash':
      case 'nakit':
      case 'cuzdan':
      case 'pocket':
        return PaymentMethod.cash;
      default:
        return defaultMethod;
    }
  }

  /// Harcama için uygun tüm ödeme yöntemleri
  static List<PaymentMethod> get expenseMethods => [
        PaymentMethod.cash,
        PaymentMethod.bankCard,
        PaymentMethod.creditCard,
      ];

  /// Gelir için uygun ödeme / aktarım yöntemleri (Nakit & Banka)
  static List<PaymentMethod> get incomeMethods => [
        PaymentMethod.cash,
        PaymentMethod.bankCard,
      ];
}
