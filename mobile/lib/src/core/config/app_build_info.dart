class AppBuildInfo {
  const AppBuildInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  const AppBuildInfo.fallback()
    : appName = '큐레이터',
      packageName = 'curator_mobile',
      version = 'dev',
      buildNumber = '0';

  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;

  String get versionLabel => '$version+$buildNumber';
}
