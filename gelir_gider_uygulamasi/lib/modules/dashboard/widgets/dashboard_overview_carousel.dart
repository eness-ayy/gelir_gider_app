import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/widgets/account_balances_card.dart';
import 'package:gelir_gider_uygulamasi/modules/dashboard/widgets/budget_overview_card.dart';
import 'package:gelir_gider_uygulamasi/themes/app_colors.dart';

/// Cüzdan & Hesap Bakiyeleri ile Aylık Bütçe Takibi kartlarını
/// yatay kaydırmalı (carousel) olarak sunan bileşen.
/// Varsayılan olarak ilk sırada Cüzdan kartı gösterilir.
///
/// Carousel yüksekliği sabit değildir: her sayfanın içerik yüksekliği ölçülür ve
/// aktif sayfaya göre (kaydırma sırasında iki sayfa arasında yumuşak geçişle)
/// ayarlanır. Böylece bütçe listesi genişletildiğinde tüm kategoriler görünür.
class DashboardOverviewCarousel extends StatefulWidget {
  const DashboardOverviewCarousel({super.key});

  @override
  State<DashboardOverviewCarousel> createState() =>
      _DashboardOverviewCarouselState();
}

class _DashboardOverviewCarouselState extends State<DashboardOverviewCarousel> {
  static const int _pageCount = 2;
  static const double _fallbackHeight = 230;

  final PageController _pageController = PageController();
  final List<double?> _pageHeights = List<double?>.filled(_pageCount, null);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageSize(int index, Size size) {
    if (!mounted || _pageHeights[index] == size.height) return;
    setState(() => _pageHeights[index] = size.height);
  }

  double _heightOf(int index) =>
      _pageHeights[index] ??
      _pageHeights.firstWhere((h) => h != null, orElse: () => null) ??
      _fallbackHeight;

  /// Kaydırma konumuna göre iki sayfa yüksekliği arasında enterpolasyon yapar.
  double _currentHeight() {
    double page = _currentPage.toDouble();
    if (_pageController.hasClients &&
        _pageController.position.hasContentDimensions) {
      page = _pageController.page ?? page;
    }
    page = page.clamp(0, _pageCount - 1).toDouble();
    final lower = page.floor();
    final upper = page.ceil();
    final t = page - lower;
    return _heightOf(lower) + (_heightOf(upper) - _heightOf(lower)) * t;
  }

  Widget _measuredPage(int index, Widget child) {
    // OverflowBox sayesinde kart doğal yüksekliğinde çizilir ve ölçülür;
    // PageView'in o anki yüksekliğinden bağımsızdır (taşma hatası oluşmaz).
    return OverflowBox(
      alignment: Alignment.topCenter,
      minHeight: 0,
      maxHeight: double.infinity,
      child: _SizeReporter(
        onSizeChanged: (size) => _onPageSize(index, size),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Yatay Kaydırmalı Kartlar (PageView) - yükseklik içeriğe göre değişir
        AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) =>
              SizedBox(height: _currentHeight(), child: child),
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              // 1. Cüzdan & Hesap Bakiyeleri (İlk başta cüzdan)
              _measuredPage(
                0,
                const AccountBalancesCard(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
              ),
              // 2. Aylık Bütçe Takibi (Sola kaydırınca gelen bütçe kartı)
              _measuredPage(
                1,
                const BudgetOverviewCard(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Sayfa Göstergesi (Dots Indicator)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_pageCount, (index) {
            final isSelected = _currentPage == index;
            return GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                width: isSelected ? 22 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white24 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 6),
      ],
    );
  }
}

/// Çocuğunun layout sonrası boyutunu bildiren yardımcı widget.
class _SizeReporter extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onSizeChanged;

  const _SizeReporter({required this.onSizeChanged, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSizeChanged);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) {
    renderObject.onSizeChanged = onSizeChanged;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSizeChanged);

  ValueChanged<Size> onSizeChanged;
  Size? _lastSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = size;
    if (_lastSize == newSize) return;
    _lastSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSizeChanged(newSize));
  }
}
