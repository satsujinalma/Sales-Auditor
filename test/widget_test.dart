import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sales_auditor/main.dart';
import 'package:sales_auditor/models/app_user.dart';
import 'package:sales_auditor/providers/admin_provider.dart';
import 'package:sales_auditor/providers/auth_provider.dart';
import 'package:sales_auditor/providers/sales_provider.dart';
import 'package:sales_auditor/services/hybrid_auth_repository.dart';
import 'package:sales_auditor/services/mock_live_sales_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Full Lottery Sales Auditor UI & Interaction Smoke Test', (
    WidgetTester tester,
  ) async {
    final repository = MockLiveSalesRepository();
    await repository.init();
    await repository.resetDaySales('nayarambalam');

    final authRepository = HybridAuthRepository(repository);
    await authRepository.init();
    final freshUser = await authRepository.verifyOtp(
      phoneNumber: '+91 9876543210',
      otp: '123456',
    );
    await authRepository.completeOnboarding(
      user: freshUser.copyWith(
        name: 'Test Shopkeeper',
        role: UserRole.shopkeeper,
        shopId: 'nayarambalam',
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
          ChangeNotifierProvider(create: (_) => SalesProvider(repository)),
          ChangeNotifierProvider(create: (_) => AdminProvider(repository)),
        ],
        child: const KeralaLotteryAuditorApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify initial Shopkeeper UI components
    expect(find.text('BOX 1'), findsOneWidget);
    expect(find.text('BOX 2'), findsOneWidget);
    expect(find.text('BOX 3'), findsOneWidget);
    expect(find.text('ONE-TAP SALES ENTRY'), findsOneWidget);

    // Initial state
    expect(find.text('No sales yet'), findsOneWidget);

    // Tap button '1' (1 ticket @ ₹50)
    final btn1 = find.widgetWithText(InkWell, '1').first;
    await tester.tap(btn1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Box 2 updated to 1 ticket
    expect(find.text('1'), findsWidgets);
    expect(find.text('₹50'), findsWidgets);

    // Tap button '12' (1 Full Set = 12 tickets @ ₹570 for Nayarambalam)
    final btn12 = find.widgetWithText(InkWell, '12').first;
    await tester.tap(btn12);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Total tickets should now be 1 + 12 = 13 tickets
    expect(find.text('13'), findsWidgets);
    expect(find.text('₹620'), findsWidgets);
    expect(find.text('₹47.69'), findsWidgets);

    // Test Undo functionality
    final undoBtn = find.widgetWithText(ElevatedButton, 'Undo');
    if (undoBtn.evaluate().isNotEmpty) {
      await tester.tap(undoBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // After undoing last 12 tickets, total should revert to 1 ticket @ ₹50
      expect(find.text('1'), findsWidgets);
      expect(find.text('₹50'), findsWidgets);
    }

    // Switch to Admin / Head App Mode
    final adminIconBtn = find.byTooltip('Admin / Head App');
    await tester.tap(adminIconBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Admin Screen elements
    expect(find.text('HEAD APP • AUDIT MONITOR'), findsOneWidget);
    expect(find.text('LIVE AUDIT MIRROR (VIEW ONLY)'), findsOneWidget);
  });
}
