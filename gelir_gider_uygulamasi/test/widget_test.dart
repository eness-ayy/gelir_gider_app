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
}
