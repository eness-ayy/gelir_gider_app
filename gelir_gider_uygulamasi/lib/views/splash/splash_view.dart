import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';

/// Basit, şık ve tema uyumlu karşılama (Splash) ekranı.
/// Bu ekran herhangi bir yönlendirme mantığı içermez;
/// yönlendirme kararını doğrudan kalıcı AuthController verir.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121316) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? Colors.white54 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // Uygulama Logosu / İkonu (Tamamen Yuvarlak)
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D2FF).withValues(alpha: isDark ? 0.35 : 0.2),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 52,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Uygulama Adı
              Text(
                "hesaply",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Kısa açıklama / alt başlık
              Text(
                "Finansal Takip & Yönetim",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                  letterSpacing: 0.2,
                ),
              ),

              const Spacer(flex: 2),

              // Modern Yükleme Göstergesi
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.primary : AppColors.primary,
                  ),
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
