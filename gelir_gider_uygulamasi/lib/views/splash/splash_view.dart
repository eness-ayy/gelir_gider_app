import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';

/// Basit, şık ve minimalist karşılama (Splash) ekranı.
/// İlk açılışta sadece 'Hesaply' başlığı görüntülenir ve ardından login ekranına yönlendirilir.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Spacer(flex: 3),

              // Sadece 'Hesaply' Başlığı
              Text(
                "Hesaply",
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: AppColors.primary,
                ),
              ),

              Spacer(flex: 2),

              // Zarif Yükleme Göstergesi
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),

              Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
