class AvatarHelper {
  static const String avatarDirectory = 'assets/avatars/';

  /// Mevcut hazır avatar listesi
  static const List<String> availableAvatars = [
    'assets/avatars/avatar_1.png',
    'assets/avatars/avatar_2.png',
    'assets/avatars/avatar_3.png',
    'assets/avatars/avatar_4.png',
    'assets/avatars/avatar_5.png',
    'assets/avatars/avatar_6.png',
    'assets/avatars/avatar_7.png',
    'assets/avatars/avatar_8.png',
  ];

  /// Avatar yolunun yerel bir asset olup olmadığını kontrol eder
  static bool isAsset(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('assets/');
  }

  /// Avatar yolunun geçerli bir avatar seçimi olup olmadığını kontrol eder
  static bool hasAvatar(String? path) {
    return path != null && path.trim().isNotEmpty;
  }
}
