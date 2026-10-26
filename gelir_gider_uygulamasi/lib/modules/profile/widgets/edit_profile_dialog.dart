import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/profile_controller.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:gelir_gider_uygulamasi/utils/avatar_helper.dart';
import 'package:get/get.dart';

class EditProfileDialog extends StatefulWidget {
  final String? customTitle;
  final String? customSubtitle;
  final IconData? customIcon;

  const EditProfileDialog({
    super.key,
    this.customTitle,
    this.customSubtitle,
    this.customIcon,
  });

  static Future<void> show(
    BuildContext context, {
    String? title,
    String? subtitle,
    IconData? icon,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileDialog(
        customTitle: title,
        customSubtitle: subtitle,
        customIcon: icon,
      ),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final ProfileController _controller = Get.find<ProfileController>();

  // Kullanıcı Durumu (Anonim / Misafir kontrolü)
  late bool _isGuest;
  bool _isEmailLinkMode = false;
  bool _isLinkPasswordHidden = true;
  bool _isLinkConfirmPasswordHidden = true;

  // Standart Profil Formu Denetleyicileri
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;

  // E-posta ile Hesap Bağlama Denetleyicileri
  late final TextEditingController _linkNameController;
  late final TextEditingController _linkEmailController;
  late final TextEditingController _linkPasswordController;
  late final TextEditingController _linkConfirmPasswordController;

  String? _linkEmailError;
  String? _linkPasswordError;
  String? _linkConfirmPasswordError;

  String? _selectedAvatar;
  bool _clearPhoto = false;

  @override
  void initState() {
    super.initState();

    // 1. Kullanıcı Durumu Kontrolü:
    // final bool isGuest = FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
    try {
      _isGuest = FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
    } catch (_) {
      _isGuest = false;
    }

    // Standart form denetleyicileri
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _populateFieldsFromCurrentUser();

    // E-posta bağlama denetleyicileri
    _linkNameController = TextEditingController();
    _linkEmailController = TextEditingController();
    _linkPasswordController = TextEditingController();
    _linkConfirmPasswordController = TextEditingController();
  }

  void _populateFieldsFromCurrentUser() {
    final user = _controller.user.value;
    User? fbUser;
    try {
      fbUser = FirebaseAuth.instance.currentUser;
    } catch (_) {
      fbUser = null;
    }

    final parts = (fbUser?.displayName?.trim() ?? '').split(' ');
    final fbFirst = parts.first;
    final fbLast = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final initialFirst = (user?.first_name != null && user!.first_name!.isNotEmpty)
        ? user.first_name!
        : (fbFirst.isNotEmpty ? fbFirst : (fbUser?.email?.split('@').first ?? ''));

    final initialLast = (user?.last_name != null && user!.last_name!.isNotEmpty)
        ? user.last_name!
        : fbLast;

    final initialEmail = (user?.email != null && user!.email!.isNotEmpty)
        ? user.email!
        : (fbUser?.email ?? '');

    _firstNameController.text = initialFirst;
    _lastNameController.text = initialLast;
    _emailController.text = initialEmail;
    _selectedAvatar = user?.profile_photo;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _linkNameController.dispose();
    _linkEmailController.dispose();
    _linkPasswordController.dispose();
    _linkConfirmPasswordController.dispose();
    super.dispose();
  }

  String get _avatarInitial {
    final first = _firstNameController.text.trim();
    if (first.isNotEmpty) return first[0].toUpperCase();
    final userFirst = _controller.user.value?.first_name?.trim();
    if (userFirst != null && userFirst.isNotEmpty) {
      return userFirst[0].toUpperCase();
    }
    String? fbName;
    try {
      fbName = FirebaseAuth.instance.currentUser?.displayName?.trim();
    } catch (_) {
      fbName = null;
    }
    if (fbName != null && fbName.isNotEmpty) {
      return fbName[0].toUpperCase();
    }
    final email = _emailController.text.trim();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return 'K';
  }

  /// Google ile Hesap Bağlama Aksiyonu
  Future<void> _handleLinkWithGoogle() async {
    final success = await _controller.linkWithGoogle();
    if (success && mounted) {
      _populateFieldsFromCurrentUser();
      setState(() {
        _isGuest = false;
        _isEmailLinkMode = false;
      });
    }
  }

  /// E-posta & Şifre ile Hesap Bağlama Aksiyonu
  Future<void> _handleLinkWithEmail() async {
    setState(() {
      _linkEmailError = null;
      _linkPasswordError = null;
      _linkConfirmPasswordError = null;
    });

    final email = _linkEmailController.text.trim();
    final password = _linkPasswordController.text;
    final confirmPassword = _linkConfirmPasswordController.text;
    final name = _linkNameController.text.trim();

    if (email.isEmpty) {
      setState(() => _linkEmailError = "Lütfen e-posta adresinizi giriniz.");
      return;
    }
    if (!GetUtils.isEmail(email)) {
      setState(() => _linkEmailError = "Geçerli bir e-posta adresi giriniz.");
      return;
    }
    if (password.isEmpty) {
      setState(() => _linkPasswordError = "Lütfen bir şifre belirleyiniz.");
      return;
    }
    if (password.length < 6) {
      setState(() => _linkPasswordError = "Şifre en az 6 karakter olmalıdır.");
      return;
    }
    if (confirmPassword != password) {
      setState(() => _linkConfirmPasswordError = "Şifreler birbiriyle eşleşmiyor.");
      return;
    }

    final success = await _controller.linkWithEmail(
      email: email,
      password: password,
      fullName: name.isNotEmpty ? name : null,
    );

    if (success && mounted) {
      _populateFieldsFromCurrentUser();
      setState(() {
        _isGuest = false;
        _isEmailLinkMode = false;
      });
    }
  }

  Future<void> _handleSave() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();

    if (firstName.isEmpty) {
      Get.snackbar(
        "Uyarı",
        "Lütfen adınızı giriniz",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.85),
        colorText: Colors.white,
      );
      return;
    }

    final success = await _controller.updateProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      profilePhoto: _clearPhoto ? null : _selectedAvatar,
      clearPhoto: _clearPhoto,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildAvatarImage(String path, double size, {double fontSize = 28}) {
    if (AvatarHelper.isAsset(path)) {
      return Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildInitialWidget(size, fontSize),
      );
    }
    return Image.network(
      path,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _buildInitialWidget(size, fontSize),
    );
  }

  Widget _buildInitialWidget(double size, double fontSize) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _avatarInitial,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Misafir Kullanıcı / Normal Kullanıcı Görünüm Ayrımı
            if (_isGuest)
              _isEmailLinkMode
                  ? _buildEmailLinkForm(isDark)
                  : _buildGuestLinkCard(isDark)
            else
              _buildStandardProfileForm(isDark),
          ],
        ),
      ),
    );
  }

  /// Misafir Kullanıcı İçin Kayıt / Hesap Bağlama Görünümü
  Widget _buildGuestLinkCard(bool isDark) {
    final displayIcon = widget.customIcon ?? Icons.cloud_sync_outlined;
    final displayTitle = widget.customTitle ?? "Profilinizi Özelleştirin";
    final displaySubtitle = widget.customSubtitle ??
        "Profil bilgilerinizi kaydetmek, avatarınızı seçmek ve ortak oda harcamalarınızı bulutta güvenceye almak için ücretsiz hesabınızı oluşturun.";

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sağ üst kapatma butonu
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              color: isDark ? Colors.white70 : Colors.black54,
              splashRadius: 20,
            ),
          ],
        ),
        const SizedBox(height: 4),

        // İkon/Görsel: Üst kısımda yumuşak arka planlı kilit veya bulut yedekleme ikonu
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.22),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              displayIcon,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Başlık
        Text(
          displayTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),

        // Açıklama
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            displaySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Hızlı Aksiyon Butonu: Tam renkli Google ikonuyla 'Google ile Bağla' butonu
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _controller.isLinking.value ? null : _handleLinkWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                elevation: 1,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
              ),
              child: _controller.isLinking.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icons/google_logo.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            'assets/icon/google_logo.png',
                            width: 22,
                            height: 22,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.g_mobiledata_rounded,
                              size: 26,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Google ile Bağla",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Alternatif: Altında 'veya E-posta ile Kaydol' seçeneği
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _isEmailLinkMode = true;
                _linkEmailError = null;
                _linkPasswordError = null;
                _linkConfirmPasswordError = null;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              "veya E-posta ile Kaydol",
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// E-posta & Şifre ile Hesap Bağlama Alt Görünümü
  Widget _buildEmailLinkForm(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Başlık ve Geri Butonu Satırı
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => setState(() => _isEmailLinkMode = false),
              icon: const Icon(Icons.arrow_back_rounded),
              color: isDark ? Colors.white70 : Colors.black54,
              tooltip: "Geri",
            ),
            Text(
              "E-posta ile Bağla",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "Mevcut misafir oturumunuzu e-posta ve şifrenizle bağlayarak verilerinizi güvenceye alın.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Ad Soyad (İsteğe bağlı)
        Text(
          "Ad Soyad (İsteğe bağlı)",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _linkNameController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            hintText: "Örn: Ahmet Yılmaz",
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // E-posta
        Text(
          "E-posta",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _linkEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
            hintText: "ornek@email.com",
            errorText: _linkEmailError,
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) {
            if (_linkEmailError != null) {
              setState(() => _linkEmailError = null);
            }
          },
        ),
        const SizedBox(height: 14),

        // Şifre
        Text(
          "Şifre",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _linkPasswordController,
          obscureText: _isLinkPasswordHidden,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _isLinkPasswordHidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(
                () => _isLinkPasswordHidden = !_isLinkPasswordHidden,
              ),
            ),
            hintText: "En az 6 karakter",
            errorText: _linkPasswordError,
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) {
            if (_linkPasswordError != null) {
              setState(() => _linkPasswordError = null);
            }
          },
        ),
        const SizedBox(height: 14),

        // Şifre Tekrar
        Text(
          "Şifre Tekrar",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _linkConfirmPasswordController,
          obscureText: _isLinkConfirmPasswordHidden,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _isLinkConfirmPasswordHidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(
                () => _isLinkConfirmPasswordHidden =
                    !_isLinkConfirmPasswordHidden,
              ),
            ),
            hintText: "Şifrenizi tekrar giriniz",
            errorText: _linkConfirmPasswordError,
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) {
            if (_linkConfirmPasswordError != null) {
              setState(() => _linkConfirmPasswordError = null);
            }
          },
        ),
        const SizedBox(height: 22),

        // Hesabı Bağla ve Devam Et Butonu
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _controller.isLinking.value ? null : _handleLinkWithEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              child: _controller.isLinking.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Hesabı Bağla ve Devam Et",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Normal Kullanıcı Görünümü (Standart Profil Düzenleme Formu)
  Widget _buildStandardProfileForm(bool isDark) {
    final effectiveAvatar = _clearPhoto ? null : _selectedAvatar;
    final isInitialSelected =
        effectiveAvatar == null || effectiveAvatar.isEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Profili Düzenle",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Bilgilerinizi ve avatarınızı güncelleyin",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Profile Avatar Preview (Temiz Dairesel Avatar)
        Center(
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: (effectiveAvatar != null && effectiveAvatar.isNotEmpty)
                ? ClipOval(
                    child: _buildAvatarImage(
                      effectiveAvatar,
                      86,
                      fontSize: 34,
                    ),
                  )
                : Text(
                    _avatarInitial,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 18),

        // Avatar Seçim Bölümü
        Text(
          "Avatarınızı Seçin",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Yatay Avatar Listesi
        SizedBox(
          height: 72,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. Seçenek: İsmin Baş Harfi (Varsayılan)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = null;
                    _clearPhoto = true;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isInitialSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(3.5),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF059669),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _avatarInitial,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          if (isInitialSelected)
                            Container(
                              width: 43,
                              height: 43,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.35),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),

              // 2. Hazır Avatar Seçenekleri
              ...AvatarHelper.availableAvatars.map((avatarPath) {
                final isSelected = effectiveAvatar == avatarPath;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatar = avatarPath;
                      _clearPhoto = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              padding: const EdgeInsets.all(3.5),
                              child: ClipOval(
                                child: _buildAvatarImage(
                                  avatarPath,
                                  43,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 43,
                                height: 43,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.35),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Adı (First Name) Field
        Text(
          "Ad",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _firstNameController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            hintText: "Adınız",
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),

        // Soyadı (Last Name) Field
        Text(
          "Soyad",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _lastNameController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            hintText: "Soyadınız",
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // E-posta (Email) Field
        Text(
          "E-posta",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
            hintText: "ornek@email.com",
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  "Vazgeç",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Obx(
                () => ElevatedButton(
                  onPressed: _controller.isUpdating.value ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: _controller.isUpdating.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Değişiklikleri Kaydet",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
