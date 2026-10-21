import 'package:flutter/material.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';

class ExtraModuleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeTextColor;
  final Color? badgeBgColor;
  final VoidCallback onTap;

  const ExtraModuleCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeTextColor,
    this.badgeBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Koyu tema için özel #1E1E1E zemin
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade200;

    final effectiveBadgeBg = badgeBgColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.shade100);

    final effectiveBadgeText = badgeTextColor ??
        (isDark ? Colors.white70 : AppColors.lightTextSecondary);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: iconColor.withValues(alpha: 0.12),
          highlightColor: iconColor.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Yuvarlak renkli zeminli modül ikonu
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),

                // Başlık & Alt Açıklama
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Sağ Taraf: Mini Sayaç / Durum Rozeti (varsa) ve Chevron
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badgeText != null && badgeText!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: effectiveBadgeBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: effectiveBadgeText.withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          badgeText!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: effectiveBadgeText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
