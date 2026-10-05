import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import '../models/app_update_info.dart';
import '../services/app_update_service.dart';

class AppUpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;
  final AppUpdateService? updateService;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
    this.updateService,
  });

  /// Static helper to quickly show the update dialog
  static Future<void> show(
    BuildContext context,
    AppUpdateInfo updateInfo, {
    AppUpdateService? updateService,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.isMandatory,
      builder: (_) => AppUpdateDialog(
        updateInfo: updateInfo,
        updateService: updateService,
      ),
    );
  }

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  late final AppUpdateService _service;
  StreamSubscription<OtaEvent>? _otaSubscription;

  bool _isDownloading = false;
  int _downloadProgress = 0;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.updateService ?? AppUpdateService();
  }

  @override
  void dispose() {
    _otaSubscription?.cancel();
    super.dispose();
  }

  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _errorMessage = null;
      _statusMessage = 'Connecting to server...';
    });

    try {
      _otaSubscription = _service
          .startOtaUpdate(widget.updateInfo.downloadUrl)
          .listen(
        (OtaEvent event) {
          if (!mounted) return;

          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              final percent = int.tryParse(event.value ?? '0') ?? 0;
              setState(() {
                _downloadProgress = percent;
                _statusMessage = 'Downloading update... $percent%';
              });
              break;

            case OtaStatus.INSTALLING:
              setState(() {
                _downloadProgress = 100;
                _statusMessage = 'Opening Android Package Installer...';
              });
              break;

            case OtaStatus.ALREADY_RUNNING_ERROR:
              setState(() {
                _isDownloading = false;
                _errorMessage = 'An update download is already in progress.';
              });
              break;

            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              setState(() {
                _isDownloading = false;
                _errorMessage =
                    'Permission denied. Please grant install permission in Android Settings.';
              });
              break;

            case OtaStatus.INSTALLATION_DONE:
              setState(() {
                _isDownloading = false;
                _statusMessage = 'Update installation initiated.';
              });
              break;

            case OtaStatus.INTERNAL_ERROR:
            case OtaStatus.DOWNLOAD_ERROR:
            case OtaStatus.CHECKSUM_ERROR:
            default:
              setState(() {
                _isDownloading = false;
                _errorMessage =
                    'Download failed (${event.status.name}). Please try again.';
              });
              break;
          }
        },
        onError: (err) {
          if (!mounted) return;
          setState(() {
            _isDownloading = false;
            _errorMessage = 'Update error: $err';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _errorMessage = 'Failed to start download: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.updateInfo;

    return PopScope(
      canPop: !info.isMandatory && !_isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Colors.white,
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Emblem & Title
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.system_update_alt_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update Available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Version ${info.latestVersion} is ready',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Version comparison pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current: v${info.currentVersion}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: Color(0xFF0F766E)),
                    Text(
                      'New: v${info.latestVersion}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Release Notes Box
              if (info.releaseNotes.isNotEmpty) ...[
                const Text(
                  "What's New:",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      info.releaseNotes,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Error notification
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 18, color: Color(0xFFB91C1C)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Downloading Progress or Action Buttons
              if (_isDownloading) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _downloadProgress > 0
                            ? _downloadProgress / 100.0
                            : null,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF0F766E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage ?? 'Preparing update...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    if (!info.isMandatory)
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black54,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Later'),
                        ),
                      ),
                    if (!info.isMandatory) const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text(
                          'UPDATE APP NOW',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        onPressed: _startDownload,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
