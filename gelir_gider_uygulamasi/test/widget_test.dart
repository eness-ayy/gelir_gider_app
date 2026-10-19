import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test AnimatedBottomNavigationBar with 2 icons and center gap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: FloatingActionButton(onPressed: () {}),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: AnimatedBottomNavigationBar(
            icons: const [
              Icons.dashboard,
              Icons.pie_chart,
            ],
            activeIndex: 0,
            gapLocation: GapLocation.center,
            onTap: (index) {},
          ),
        ),
      ),
    );
    expect(find.byType(AnimatedBottomNavigationBar), findsOneWidget);
  });

  testWidgets('Test bottom navigation bar renders 4 tab labels correctly', (tester) async {
    const navItems = [
      "Dashboard",
      "Gruplar",
      "İstatistikler",
      "Profil",
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: FloatingActionButton(onPressed: () {}),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: AnimatedBottomNavigationBar.builder(
            itemCount: 4,
            tabBuilder: (index, isActive) => Text(navItems[index]),
            activeIndex: 1,
            gapLocation: GapLocation.center,
            onTap: (_) {},
          ),
        ),
      ),
    );

    for (final label in navItems) {
      expect(find.text(label), findsOneWidget);
    }
  });
}
