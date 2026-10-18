import 'package:flutter/material.dart';

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
];

IconData getCategoryIcon({
  required String iconName,
  required bool isSystem,
  required String type,
}) {
  // Sistem kategorileri için özel ikonlar

  switch (iconName) {
    case 'bus':
      return Icons.directions_bus;
    case 'cart':
      return Icons.shopping_cart;
    case 'cash':
      return Icons.attach_money;
    case 'game-controller':
      return Icons.games;
    case 'medical':
      return Icons.local_hospital;
    case 'receipt':
      return Icons.receipt;
    case 'restaurant':
      return Icons.restaurant;
    case 'school':
      return Icons.school;
    case 'family':
      return Icons.family_restroom;
    case 'wallet':
      return Icons.account_balance_wallet;
    case 'trending-up':
      return Icons.trending_up;
    default:
      // Bilinmeyen sistem ikonu için varsayılan
      return Icons.category;
  }
}