import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';

class LogoutConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const LogoutConfirmationDialog({
    super.key,
    required this.onConfirm,
    this.onCancel,
  });

  /// iOS 17 / Dribbble tarzı modern çıkış onay modalını yumuşak scale & fade animasyonuyla gösterir.
  static Future<bool?> show(
    BuildContext context, {
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Çıkış Yap Onay Modalı",
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (ctx, anim1, anim2) {
        return LogoutConfirmationDialog(
          onConfirm: onConfirm,
          onCancel: onCancel,
        );
      },
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 6 * curved.value,
            sigmaY: 6 * curved.value,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: FadeTransition(
              opacity: curved,
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tema Renkleri (Saf siyah yerine modern antrasit/füme #18181B)
    final cardBgColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final cardBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final titleColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? const Color(0xFFA1A1AA) : Colors.grey.shade600;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 340),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: cardBorderColor,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
              if (isDark)
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.06),
                  blurRadius: 28,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Dairesel Rozet İkon (Yarı saydam kırmızı zemin & modern logout ikonu)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.22),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.20),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.logout_rounded,
                    size: 30,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 2. Başlık: "Çıkış Yap"
              Text(
                "Çıkış Yap",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 10),

              // 3. Alt Açıklama (Hafif soluk gri font)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  "Hesabınızdan çıkış yapmak istediğinize emin misiniz? İstediğiniz zaman tekrar giriş yapabilirsiniz.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                    color: subtitleColor,
                  ),
                ),
              ),
              const SizedBox(height: 26),

              // 4. Aksiyon Butonları (Vazgeç & Evet, Çıkış Yap)
              Row(
                children: [
                  // İkincil Buton: "Vazgeç"
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                          onCancel?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.grey.shade100,
                          foregroundColor: isDark
                              ? const Color(0xFFE4E4E7)
                              : Colors.grey.shade800,
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(
                          "Vazgeç",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFE4E4E7)
                                : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Birincil Buton: "Evet, Çıkış Yap" (Mercan/Kırmızı Gradient & Hafif Glow)
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFEF4444),
                            Color(0xFFDC2626),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Evet, Çıkış Yap",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
