import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_auditor/models/app_update_info.dart';
import 'package:sales_auditor/services/app_update_service.dart';
import 'package:sales_auditor/widgets/app_update_dialog.dart';

void main() {
  group('AppUpdateService Semantic Version Comparison Tests', () {
    test('Identifies higher minor and patch versions correctly', () {
      expect(AppUpdateService.isVersionHigher('1.0.1', '1.0.0'), true);
      expect(AppUpdateService.isVersionHigher('1.1.0', '1.0.9'), true);
      expect(AppUpdateService.isVersionHigher('2.0.0', '1.9.9'), true);
      expect(AppUpdateService.isVersionHigher('1.0.10', '1.0.9'), true);
      expect(AppUpdateService.isVersionHigher('v1.0.1', '1.0.0'), true);
    });

    test('Identifies equal or lower versions correctly', () {
      expect(AppUpdateService.isVersionHigher('1.0.0', '1.0.0'), false);
      expect(AppUpdateService.isVersionHigher('1.0.0', '1.0.1'), false);
      expect(AppUpdateService.isVersionHigher('0.9.9', '1.0.0'), false);
      expect(AppUpdateService.isVersionHigher('1.0.0+2', '1.0.0+1'), false);
    });
  });

  group('AppUpdateDialog Widget Tests', () {
    testWidgets('Renders update dialog with version details and release notes',
        (WidgetTester tester) async {
      const updateInfo = AppUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.0.1',
        downloadUrl:
            'https://github.com/SansWars/Sales-Auditor/releases/download/v1.0.1/app-release.apk',
        releaseNotes: '• Added 1-tap OTA updater\n• Performance optimizations',
        hasUpdate: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppUpdateDialog(updateInfo: updateInfo),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header & version info
      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('Version 1.0.1 is ready'), findsOneWidget);
      expect(find.text('Current: v1.0.0'), findsOneWidget);
      expect(find.text('New: v1.0.1'), findsOneWidget);

      // Verify release notes
      expect(find.text("What's New:"), findsOneWidget);
      expect(
        find.text('• Added 1-tap OTA updater\n• Performance optimizations'),
        findsOneWidget,
      );

      // Verify action buttons
      expect(find.text('Later'), findsOneWidget);
      expect(find.text('UPDATE APP NOW'), findsOneWidget);
    });
  });
}
