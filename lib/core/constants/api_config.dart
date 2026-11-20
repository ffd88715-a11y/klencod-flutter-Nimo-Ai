/// Configurable self-hosted TALKORA AI backend endpoints (no paid commercial API keys).
class ApiConfig {
  const ApiConfig._();

  // Android emulator maps host localhost to 10.0.2.2; override in Settings for LAN/production server
  static const String defaultBaseUrl = 'http://10.0.2.2:8000';
  static const String defaultWsUrl = 'ws://10.0.2.2:8000';
}
