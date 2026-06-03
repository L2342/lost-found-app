import 'package:flutter/foundation.dart';

class AppConfig {
  static const String adminToken = String.fromEnvironment(
    'ADMIN_TOKEN',
    defaultValue: 'admin-token-encuentralo',
  );

  static const String _baseUrlOverride = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: '',
  );

  static String get backendBaseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;

    if (kIsWeb) return 'http://127.0.0.1:5000';

    return 'http://10.0.2.2:5000';
  }
}
