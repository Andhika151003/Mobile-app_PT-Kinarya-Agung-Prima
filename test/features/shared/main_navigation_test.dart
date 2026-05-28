import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce/features/shared/main_navigation_admin.dart';
import 'package:ecommerce/features/shared/main_navigation_user.dart';
import 'package:ecommerce/features/shared/main_navigation_cs.dart';

void main() {
  group('Shared Navigation Widget Tests', () {
    testWidgets('MainNavigationAdmin renders BottomNavigationBar and changes index', (WidgetTester tester) async {
      final mockPages = List.generate(5, (index) => Center(child: Text('Admin Page $index')));
      
      await tester.pumpWidget(MaterialApp(home: MainNavigationAdmin(pages: mockPages)));
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Admin Page 0'), findsOneWidget); // initially page 0

      // Tap 'Products' (index 1)
      await tester.tap(find.text('Products').last);
      await tester.pumpAndSettle();
      expect(find.text('Admin Page 1'), findsOneWidget);
    });

    testWidgets('MainNavigationUser renders BottomNavigationBar and changes index', (WidgetTester tester) async {
      final mockPages = List.generate(4, (index) => Center(child: Text('User Page $index')));

      await tester.pumpWidget(MaterialApp(home: MainNavigationUser(pages: mockPages)));
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('User Page 0'), findsOneWidget);

      // Tap 'Orders' (index 2)
      await tester.tap(find.text('Orders').last);
      await tester.pumpAndSettle();
      expect(find.text('User Page 2'), findsOneWidget);
    });

    testWidgets('MainNavigationCs renders BottomNavigationBar and changes index', (WidgetTester tester) async {
      final mockPages = List.generate(4, (index) => Center(child: Text('Cs Page $index')));

      await tester.pumpWidget(MaterialApp(home: MainNavigationCs(pages: mockPages)));
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Cs Page 0'), findsOneWidget);
      
      // Verifikasi item di CS
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Orders'), findsWidgets);
      expect(find.text('Supports'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);

      // Coba tap item 'Orders'
      await tester.tap(find.text('Orders').last);
      await tester.pumpAndSettle();
      expect(find.text('Cs Page 1'), findsOneWidget);
    });
  });
}
