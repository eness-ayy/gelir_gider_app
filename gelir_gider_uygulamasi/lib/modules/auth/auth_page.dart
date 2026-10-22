import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/modules/auth/auth_controller.dart';
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
                  // 1. ÜST LOGO & BAŞLIK BÖLÜMÜ
                  _buildHeader(isDark),
                  const SizedBox(height: 28),

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
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Alt Bilgilendirme
                  Text(
                    "Ortak Ev & Yurt Harcama ve İhtiyaç Yönetimi",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
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
  // 1. ÜST LOGO VE BAŞLIK
  // ===========================================================================
  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        // Modern Logo Rozeti (Glow Efektli Degrade İkon)
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.cottage_rounded,
              size: 42,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Başlık
        const Text(
          "Ortak Oda",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),

        // Alt Slogan
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Masrafları ve odayı arkadaşlarınla kolayca yönet",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
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
                onTap: () => controller.selectedTab.value = 0,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active == 0
                        ? (isDark ? const Color(0xFF0D9488) : Colors.white)
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
                onTap: () => controller.selectedTab.value = 1,
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active == 1
                        ? (isDark ? const Color(0xFF0D9488) : Colors.white)
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
  // 3. GİRİŞ YAP FORMU
  // ===========================================================================
  Widget _buildLoginForm(BuildContext context, bool isDark) {
    return Form(
      key: controller.loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // E-posta Alanı
          _buildTextField(
            controller: controller.loginEmailController,
            label: "E-posta Adresi",
            hint: "ornek@gmail.com",
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: controller.validateEmail,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Şifre Alanı
          Obx(() {
            final isHidden = controller.isLoginPasswordHidden.value;
            return _buildTextField(
              controller: controller.loginPasswordController,
              label: "Şifre",
              hint: "••••••••",
              icon: Icons.lock_outline_rounded,
              obscureText: isHidden,
              validator: controller.validatePassword,
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
              onPressed: () => _showForgotPasswordDialog(context, isDark),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "Şifremi Unuttum?",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D9488),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Giriş Yap Ana Butonu
          _buildSubmitButton(
            title: "Giriş Yap",
            onPressed: () => controller.loginWithEmail(),
            isDark: isDark,
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. KAYIT OL FORMU
  // ===========================================================================
  Widget _buildRegisterForm(BuildContext context, bool isDark) {
    return Form(
      key: controller.registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ad Soyad Alanı
          _buildTextField(
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
          _buildTextField(
            controller: controller.registerEmailController,
            label: "E-posta Adresi",
            hint: "ornek@gmail.com",
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: controller.validateEmail,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // Şifre Alanı
          Obx(() {
            final isHidden = controller.isRegisterPasswordHidden.value;
            return _buildTextField(
              controller: controller.registerPasswordController,
              label: "Şifre",
              hint: "En az 6 karakter",
              icon: Icons.lock_outline_rounded,
              obscureText: isHidden,
              validator: controller.validatePassword,
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
          const SizedBox(height: 18),

          // Hesap Oluştur Ana Butonu
          _buildSubmitButton(
            title: "Hesap Oluştur",
            onPressed: () => controller.registerWithEmail(),
            isDark: isDark,
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. ŞIK TEXT FORM FIELD TASARIMI
  // ===========================================================================
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13.5,
              color: isDark ? Colors.white30 : Colors.grey.shade400,
            ),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            prefixIcon: Icon(
              icon,
              size: 20,
              color: const Color(0xFF0D9488),
            ),
            suffixIcon: suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF0D9488),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 6. ANA İŞLEM BUTONU (Degrade & Yükleniyor Destekli)
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
                    color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
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
  // 7. "VEYA" AYRACI
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
  // 8. GOOGLE İLE DEVAM ET BUTONU
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
              blurRadius: 8,
              offset: const Offset(0, 2),
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

  /// Modern Google "G" Logosu Rozeti
  Widget _buildGoogleLogoBadge() {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      child: RichText(
        text: const TextSpan(
          text: "G",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4285F4),
            fontFamily: "Roboto",
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 9. ŞİFREMİ UNUTTUM DİYALOĞU
  // ===========================================================================
  void _showForgotPasswordDialog(BuildContext context, bool isDark) {
    controller.resetEmailController.text =
        controller.loginEmailController.text.trim();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          top: 22,
          bottom: MediaQuery.of(context).viewInsets.bottom + 22,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Form(
          key: controller.resetFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Üst Sürükleme Tutamacı
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Başlık ve Açıklama
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Color(0xFF0D9488),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Şifre Sıfırlama",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "E-posta adresinize sıfırlama bağlantısı gönderilecektir.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // E-posta Girişi
              _buildTextField(
                controller: controller.resetEmailController,
                label: "E-posta Adresiniz",
                hint: "ornek@gmail.com",
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: controller.validateEmail,
                isDark: isDark,
              ),
              const SizedBox(height: 20),

              // Gönder Butonu
              Obx(() {
                final isSending = controller.isResetLoading.value;
                return ElevatedButton(
                  onPressed:
                      isSending ? null : () => controller.sendPasswordReset(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Sıfırlama Bağlantısı Gönder",
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              }),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
