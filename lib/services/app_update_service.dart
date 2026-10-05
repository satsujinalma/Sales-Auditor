import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_update_info.dart';

class AppUpdateService {
  static const String _githubRepo = 'SansWars/Sales-Auditor';
  static const String _githubLatestReleaseUrl =
      'https://api.github.com/repos/$_githubRepo/releases/latest';

  final http.Client _httpClient;
  final FirebaseFirestore? firestore;

  AppUpdateService({
    http.Client? httpClient,
    this.firestore,
  }) : _httpClient = httpClient ?? http.Client();

  /// Checks for any available update via GitHub Releases or Cloud Firestore
  Future<AppUpdateInfo> checkForUpdate({String? forcedCurrentVersion}) async {
    String currentVersion = forcedCurrentVersion ?? '1.0.0';

    try {
      if (forcedCurrentVersion == null) {
        final packageInfo = await PackageInfo.fromPlatform();
        currentVersion = packageInfo.version;
      }
    } catch (_) {}

    // 1. Try GitHub Releases API
    try {
      final response = await _httpClient.get(
        Uri.parse(_githubLatestReleaseUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Sales-Auditor-App',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawTag = data['tag_name'] as String? ?? '';
        final remoteVersion = rawTag.replaceAll(RegExp(r'^[vV]'), '').trim();
        final releaseNotes = data['body'] as String? ?? 'Performance improvements and bug fixes.';
        final publishedAtStr = data['published_at'] as String?;
        final publishedAt = publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;

        // Locate APK asset
        String downloadUrl = '';
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final assetMap = asset as Map<String, dynamic>;
          final name = assetMap['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            downloadUrl = assetMap['browser_download_url'] as String? ?? '';
            break;
          }
        }

        // If no asset was attached, fallback to release url or zip
        if (downloadUrl.isEmpty && remoteVersion.isNotEmpty) {
          downloadUrl =
              'https://github.com/$_githubRepo/releases/download/$rawTag/app-release.apk';
        }

        if (remoteVersion.isNotEmpty &&
            downloadUrl.isNotEmpty &&
            isVersionHigher(remoteVersion, currentVersion)) {
          return AppUpdateInfo(
            currentVersion: currentVersion,
            latestVersion: remoteVersion,
            downloadUrl: downloadUrl,
            releaseNotes: releaseNotes,
            publishedAt: publishedAt,
            hasUpdate: true,
          );
        }
      }
    } catch (_) {
      // If GitHub is unreachable, proceed to Firestore check
    }

    // 2. Try Firestore fallback / remote config if available
    try {
      final db = firestore ?? FirebaseFirestore.instance;
      final doc = await db.collection('settings').doc('app_update').get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final remoteVersion = data['latestVersion'] as String? ?? '';
        final downloadUrl = data['apkUrl'] as String? ?? '';
        final releaseNotes = data['releaseNotes'] as String? ??
            'New features and updates available.';
        final isMandatory = data['isMandatory'] as bool? ?? false;

        if (remoteVersion.isNotEmpty &&
            downloadUrl.isNotEmpty &&
            isVersionHigher(remoteVersion, currentVersion)) {
          return AppUpdateInfo(
            currentVersion: currentVersion,
            latestVersion: remoteVersion,
            downloadUrl: downloadUrl,
            releaseNotes: releaseNotes,
            hasUpdate: true,
            isMandatory: isMandatory,
          );
        }
      }
    } catch (_) {}

    return AppUpdateInfo.noUpdate(currentVersion);
  }

  /// Compares semantic versions (e.g. "1.0.1" > "1.0.0" -> true)
  static bool isVersionHigher(String remote, String current) {
    try {
      final remoteClean = remote.split('+').first.replaceAll(RegExp(r'[^0-9.]'), '');
      final currentClean = current.split('+').first.replaceAll(RegExp(r'[^0-9.]'), '');

      final remoteParts = remoteClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = currentClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLength = remoteParts.length > currentParts.length
          ? remoteParts.length
          : currentParts.length;

      for (int i = 0; i < maxLength; i++) {
        final r = i < remoteParts.length ? remoteParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;
        if (r > c) return true;
        if (r < c) return false;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Executes background OTA download and launches the native package installer
  Stream<OtaEvent> startOtaUpdate(String downloadUrl) {
    try {
      return OtaUpdate().execute(
        downloadUrl,
        destinationFilename: 'sales_auditor_update.apk',
      );
    } catch (e) {
      throw Exception('Failed to start update: $e');
    }
  }
}
