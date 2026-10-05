class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final DateTime? publishedAt;
  final bool hasUpdate;
  final bool isMandatory;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    this.publishedAt,
    required this.hasUpdate,
    this.isMandatory = false,
  });

  factory AppUpdateInfo.noUpdate(String currentVersion) {
    return AppUpdateInfo(
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      downloadUrl: '',
      releaseNotes: '',
      hasUpdate: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentVersion': currentVersion,
      'latestVersion': latestVersion,
      'downloadUrl': downloadUrl,
      'releaseNotes': releaseNotes,
      'publishedAt': publishedAt?.toIso8601String(),
      'hasUpdate': hasUpdate,
      'isMandatory': isMandatory,
    };
  }
}
