/// Runtime configuration for the backend API.
///
/// Supply `--dart-define=API_BASE_URL=https://api.example.com` for deployed
/// builds. The development default deliberately remains local for backwards
/// compatibility with the existing backend project.
class ApiConfiguration {
  const ApiConfiguration({required this.baseUri});

  factory ApiConfiguration.fromEnvironment() {
    const configuredUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://localhost:7002',
    );
    return ApiConfiguration(baseUri: Uri.parse(configuredUrl));
  }

  final Uri baseUri;

  Uri endpoint(String path) => baseUri.resolve(path);
}
