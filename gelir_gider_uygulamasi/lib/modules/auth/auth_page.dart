import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/auth/auth_controller.dart';
import 'package:gelir_gider_uygulamasi/modules/auth/widgets/forgot_password_sheet.dart';
import 'package:gelir_gider_uygulamasi/modules/profile/widgets/legal_document_sheet.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';
import 'package:get/get.dart';

/// Modern E-posta & Şifre Odaklı Giriş ve Kayıt Olma Ekranı (Ortak Oda)
class AuthPage extends GetView<AuthController> {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. ÜST BAŞLIK BÖLÜMÜ
                  _buildHeader(),
                  const SizedBox(height: 30),

                  // 2. ANA FORM KARTI (Giriş / Kayıt Sekmeli)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.06,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Segmented TabBar (Giriş Yap / Kayıt Ol)
                        _buildTabSelector(isDark),
                        const SizedBox(height: 22),

                        // Sekmeye Göre Form İçeriği
                        Obx(() {
                          final isLogin = controller.selectedTab.value == 0;
                          return AnimatedCrossFade(
                            duration: const Duration(milliseconds: 250),
                            crossFadeState: isLogin
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            firstChild: _buildLoginForm(context, isDark),
                            secondChild: _buildRegisterForm(context, isDark),
                          );
                        }),

                        const SizedBox(height: 22),

                        // "veya" Ayracı
                        _buildDivider(isDark),
                        const SizedBox(height: 18),

                        // Google ile Devam Et Butonu
                        _buildGoogleButton(context, isDark),

                        const SizedBox(height: 12),

                        // Misafir Olarak Devam Et (Kayıt Olmadan Keşfet) Butonu
                        _buildGuestButton(isDark),
                      ],
                    ),
                  ),

                  // 3. FOOTER & SÜRÜM BİLGİSİ
                  const SizedBox(height: 20),
                  Text(
                    "v1.0.0",
                    style: TextStyle(
                      fontSize: 11.5,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white24 : Colors.grey.shade400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. ÜST BAŞLIK BÖLÜMÜ
  // ===========================================================================
  Widget _buildHeader() {
    return const Center(
      child: Text(
        "Hesaply",
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. SEGMENTED TAB SELECTOR (Giriş Yap vs Kayıt Ol)
  // ===========================================================================
  Widget _buildTabSelector(bool isDark) {
    return Obx(() {
      final active = controller.selectedTab.value;

      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Giriş Yap Sekmesi
            Expanded(
              child: InkWell(
                onTap: () {
                  controller.selectedTab.value = 0;
                  controller.clearErrors();
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active == 0
                        ? (isDark ? AppColors.primary : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: active == 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      "Giriş Yap",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: active == 0
                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Kayıt Ol Sekmesi
            Expanded(
              child: InkWell(
                onTap: () {
                  controller.selectedTab.value = 1;
                  controller.clearErrors();
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active == 1
                        ? (isDark ? AppColors.primary : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: active == 1
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      "Kayıt Ol",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: active == 1
                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ===========================================================================
  // 3. GİRİŞ YAP FORMU (Satır İçi Hata Gösterimli)
  // ===========================================================================
  Widget _buildLoginForm(BuildContext context, bool isDark) {
    return Form(
      key: controller.loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // E-posta Alanı
          Obx(() {
            final rawError = controller.emailError.value;
            final isPureBorderError =
                rawError != null && rawError.trim().isEmpty;
            final hasEmailError = rawError != null && rawError.isNotEmpty;
            final displayErrorText = isPureBorderError ? null : rawError;

            return _AuthTextField(
              controller: controller.loginEmailController,
              label: "E-posta Adresi",
              hint: "ornek@gmail.com",
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: controller.validateEmail,
              errorText: displayErrorText,
              showErrorBorder: hasEmailError,
              onChanged: (_) => controller.clearEmailError(),
              isDark: isDark,
            );
          }),
          const SizedBox(height: 16),

          // Şifre Alanı
          Obx(() {
            final isHidden = controller.isLoginPasswordHidden.value;
            final errorText = controller.passwordError.value;
            return _AuthTextField(
              controller: controller.loginPasswordController,
              label: "Şifre",
              hint: "••••••••",
              icon: Icons.lock_outline_rounded,
              obscureText: isHidden,
              validator: controller.validatePassword,
              errorText: errorText,
              onChanged: (_) => controller.clearPasswordError(),
              isDark: isDark,
              suffixIcon: IconButton(
                icon: Icon(
                  isHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
                onPressed: () =>
                    controller.isLoginPasswordHidden.value = !isHidden,
              ),
            );
          }),

          // Şifremi Unuttum Bağlantısı
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showForgotPasswordDialog(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                "Şifremi Unuttum?",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Giriş Yap Ana Butonu
          _buildSubmitButton(
            title: "Giriş Yap",
            onPressed: () => controller.loginWithEmail(),
            isDark: isDark,
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. KAYIT OL FORMU (Satır İçi Hata & Canlı Şifre Kriter Kontrollü)
  // ===========================================================================
  Widget _buildRegisterForm(BuildContext context, bool isDark) {
    return Form(
      key: controller.registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ad Soyad Alanı
          _AuthTextField(
            controller: controller.registerNameController,
            label: "Ad Soyad",
            hint: "Örn: Yiğitcan Çelik",
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            validator: controller.validateFullName,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // E-posta Alanı
          Obx(() {
            return _AuthTextField(
              controller: controller.registerEmailController,
              label: "E-posta Adresi",
              hint: "ornek@gmail.com",
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: controller.validateEmail,
              errorText: controller.emailError.value,
              showErrorBorder: controller.emailError.value != null &&
                  controller.emailError.value!.isNotEmpty,
              onChanged: (_) => controller.clearEmailError(),
              isDark: isDark,
            );
          }),
          const SizedBox(height: 16),

          // Şifre Alanı
          Obx(() {
            final isHidden = controller.isRegisterPasswordHidden.value;
            final errorText = controller.passwordError.value;
            return _AuthTextField(
              controller: controller.registerPasswordController,
              label: "Şifre",
              hint: "En az 8 karakter",
              icon: Icons.lock_outline_rounded,
              obscureText: isHidden,
              validator: controller.validatePassword,
              errorText: errorText,
              showErrorBorder: errorText != null && errorText.isNotEmpty,
              onChanged: (val) => controller.checkPasswordCriteria(val),
              onFocusChange: (focused) =>
                  controller.isRegisterPasswordFocused.value = focused,
              isDark: isDark,
              suffixIcon: IconButton(
                icon: Icon(
                  isHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
                onPressed: () =>
                    controller.isRegisterPasswordHidden.value = !isHidden,
              ),
            );
          }),

          // Canlı Şifre Kriter Göstergesi
          _buildPasswordCriteria(isDark),
          const SizedBox(height: 16),

          // Şifre Tekrar Alanı
          Obx(() {
            final isHidden = controller.isRegisterConfirmPasswordHidden.value;
            final errorText = controller.confirmPasswordError.value;
            return _AuthTextField(
              controller: controller.registerConfirmPasswordController,
              label: "Şifre Tekrar",
              hint: "••••••••",
              icon: Icons.lock_outline_rounded,
              obscureText: isHidden,
              validator: controller.validateConfirmPassword,
              errorText: errorText,
              showErrorBorder: errorText != null && errorText.isNotEmpty,
              onChanged: (val) => controller.checkConfirmPassword(val),
              isDark: isDark,
              suffixIcon: IconButton(
                icon: Icon(
                  isHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
                onPressed: () => controller
                    .isRegisterConfirmPasswordHidden.value = !isHidden,
              ),
            );
          }),
          const SizedBox(height: 20),

          // Kayıt Ol Ana Butonu
          _buildSubmitButton(
            title: "Kayıt Ol",
            onPressed: () => controller.registerWithEmail(),
            isDark: isDark,
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          const SizedBox(height: 14),

          // Gizlilik Politikası ve Kullanım Koşulları Metni
          _TermsAndPrivacyText(isDark: isDark),
        ],
      ),
    );
  }

  /// Canlı Şifre Kriterleri Listesi
  Widget _buildPasswordCriteria(bool isDark) {
    return Obx(() {
      final showCriteria = controller.isRegisterPasswordFocused.value ||
          controller.registerPasswordController.text.isNotEmpty;

      return AnimatedCrossFade(
        duration: const Duration(milliseconds: 250),
        crossFadeState: showCriteria
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
        firstChild: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCriterionRow(
                "En az 8 karakter",
                controller.hasMinLength.value,
                isDark,
              ),
              _buildCriterionRow(
                "En az 1 büyük harf (A-Z)",
                controller.hasUpperCase.value,
                isDark,
              ),
              _buildCriterionRow(
                "En az 1 rakam (0-9)",
                controller.hasNumber.value,
                isDark,
              ),
              _buildCriterionRow(
                "En az 1 özel karakter (!@#\$&*~)",
                controller.hasSpecialChar.value,
                isDark,
              ),
            ],
          ),
        ),
        secondChild: const SizedBox.shrink(),
      );
    });
  }

  /// Kriter Satırı Öğesi
  Widget _buildCriterionRow(String text, bool isMet, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMet
                  ? const Color(0xFF10B981)
                  : (isDark ? Colors.white12 : Colors.grey.shade300),
            ),
            child: Icon(
              isMet ? Icons.check_rounded : Icons.circle,
              size: isMet ? 11 : 5,
              color: isMet
                  ? Colors.white
                  : (isDark ? Colors.white30 : Colors.grey.shade400),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isMet ? FontWeight.w600 : FontWeight.w500,
                color: isMet
                    ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                    : (isDark ? Colors.white54 : Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. ANA İŞLEM BUTONU (Yumuşak Uyumlu Gölge & Yükleniyor Destekli)
  // ===========================================================================
  Widget _buildSubmitButton({
    required String title,
    required VoidCallback onPressed,
    required bool isDark,
    required Gradient gradient,
  }) {
    return Obx(() {
      final isLoading = controller.isLoading;

      return Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: isLoading ? null : gradient,
          color: isLoading
              ? (isDark ? Colors.white12 : Colors.grey.shade300)
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      );
    });
  }

  // ===========================================================================
  // 6. "VEYA" AYRACI
  // ===========================================================================
  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "veya",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 7. GOOGLE İLE DEVAM ET BUTONU (Ölçüleri Giriş Butonuyla Birebir Eşit)
  // ===========================================================================
  Widget _buildGoogleButton(BuildContext context, bool isDark) {
    return Obx(() {
      final isLoading = controller.isLoading;

      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.grey.shade300,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : () => controller.signInWithGoogle(),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGoogleLogoBadge(),
                const SizedBox(width: 12),
                Text(
                  "Google ile Devam Et",
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Resmi ve Tam Renkli Google "G" Logosu Rozeti
  Widget _buildGoogleLogoBadge() {
    return Image.asset(
      'assets/icons/google_logo.png',
      width: 20,
      height: 20,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/icon/google_logo.png',
        width: 20,
        height: 20,
        fit: BoxFit.contain,
      ),
    );
  }

  // ===========================================================================
  // 8. MİSAFİR GİRİŞİ BUTONU (Kayıt Olmadan Keşfet)
  // ===========================================================================
  Widget _buildGuestButton(bool isDark) {
    return Obx(() {
      final isLoading = controller.isLoading;

      return TextButton(
        onPressed: isLoading ? null : () => controller.signInAnonymously(),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          minimumSize: const Size.fromHeight(38),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          "Kayıt Olmadan Keşfet",
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white60 : Colors.grey.shade700,
          ),
        ),
      );
    });
  }

  // ===========================================================================
  // 9. ŞİFREMİ UNUTTUM DİYALOĞU (İzole, GPU & Rebuild Optimize)
  // ===========================================================================
  void _showForgotPasswordDialog(BuildContext context) {
    controller.resetEmailController.text =
        controller.loginEmailController.text.trim();
    controller.clearResetEmailError();

    Get.bottomSheet(
      const ForgotPasswordSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    );
  }
}

// ===========================================================================
// DİNAMİK ODAKLANMA (isFocused) VE SATIR İÇİ HATA DESTEKLİ MODERN TEXT FIELD
// ===========================================================================
class _AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final String? errorText;
  final bool showErrorBorder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<bool>? onFocusChange;
  final Widget? suffixIcon;

  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.errorText,
    this.showErrorBorder = false,
    this.onChanged,
    this.onFocusChange,
    this.suffixIcon,
  });

  @override
  State<_AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<_AuthTextField> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted && _isFocused != _focusNode.hasFocus) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      widget.onFocusChange?.call(_focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasErrorText =
        widget.errorText != null && widget.errorText!.isNotEmpty;
    final isError = hasErrorText || widget.showErrorBorder;

    // Odaklanma ve hata durumuna göre dinamik ikon rengi
    final defaultIconColor =
        widget.isDark ? Colors.white38 : Colors.grey.shade400;
    final activeIconColor = isError
        ? Colors.redAccent
        : (_isFocused ? AppColors.primary : defaultIconColor);

    final normalBorderSide = BorderSide(
      color: widget.isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.grey.shade300,
    );

    final enabledBorderSide = isError
        ? const BorderSide(color: Colors.redAccent, width: 1.4)
        : normalBorderSide;

    final focusedBorderSide = BorderSide(
      color: isError ? Colors.redAccent : AppColors.primary,
      width: isError ? 1.8 : 1.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          validator: widget.validator,
          onChanged: widget.onChanged,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontSize: 13.5,
              color: widget.isDark ? Colors.white30 : Colors.grey.shade400,
            ),
            errorText: widget.errorText,
            errorStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.redAccent,
              height: 1.3,
            ),
            filled: true,
            fillColor:
                widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            prefixIcon: Icon(
              widget.icon,
              size: 20,
              color: activeIconColor,
            ),
            suffixIcon: widget.suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: enabledBorderSide,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: enabledBorderSide,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: focusedBorderSide,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.4,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Kayıt Ol Butonu Altındaki Gizlilik Politikası ve Kullanım Koşulları Metni
class _TermsAndPrivacyText extends StatefulWidget {
  final bool isDark;
  const _TermsAndPrivacyText({required this.isDark});

  @override
  State<_TermsAndPrivacyText> createState() => _TermsAndPrivacyTextState();
}

class _TermsAndPrivacyTextState extends State<_TermsAndPrivacyText> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => LegalDocumentSheet.showTerms(context);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => LegalDocumentSheet.showPrivacy(context);
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final regularColor =
        widget.isDark ? Colors.white60 : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text.rich(
        TextSpan(
          text: "Kayıt olarak ",
          style: TextStyle(
            fontSize: 11.5,
            height: 1.45,
            color: regularColor,
          ),
          children: [
            TextSpan(
              text: "Kullanım Koşulları",
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
              recognizer: _termsRecognizer,
            ),
            const TextSpan(text: "'nı ve "),
            TextSpan(
              text: "Gizlilik Politikası",
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
              recognizer: _privacyRecognizer,
            ),
            const TextSpan(text: "'nı kabul etmiş olursunuz."),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

