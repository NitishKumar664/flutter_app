import 'package:dio/dio.dart';
import 'api_client.dart';
import 'file_service.dart';

/// Mirrors just the subset of GET/PUT /api/settings this app edits:
/// appName, defaultExpiryHours, storageLimitMb, and the three feature
/// toggles. Storage backend (S3/R2), SMTP, and AI settings involve secrets
/// and more complex forms — left to the web dashboard for now.
class AppSettings {
  final String appName;
  final String defaultExpiryHours;
  final int? storageLimitMb;
  final bool memberAuthEnabled;
  final bool nearbyShareEnabled;
  final bool supportEnabled;

  AppSettings({
    required this.appName,
    required this.defaultExpiryHours,
    required this.memberAuthEnabled,
    required this.nearbyShareEnabled,
    required this.supportEnabled,
    this.storageLimitMb,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final features = json['features'] as Map<String, dynamic>? ?? {};
    final memberAuth = features['memberAuth'] as Map<String, dynamic>? ?? {};
    final nearbyShare = features['nearbyShare'] as Map<String, dynamic>? ?? {};
    final support = features['support'] as Map<String, dynamic>? ?? {};
    return AppSettings(
      appName: json['appName'] as String? ?? 'File Drop',
      defaultExpiryHours: json['defaultExpiryHours'] as String? ?? '',
      storageLimitMb: (json['storageLimitMb'] as num?)?.toInt(),
      memberAuthEnabled: memberAuth['enabled'] as bool? ?? false,
      nearbyShareEnabled: nearbyShare['enabled'] as bool? ?? false,
      supportEnabled: support['enabled'] as bool? ?? false,
    );
  }
}

class SettingsService {
  Dio get _dio => ApiClient.instance.dio;

  /// GET /api/settings — requires admin or owner role (Viewer accounts get a 403).
  Future<AppSettings> getSettings() async {
    final res = await _dio.get('/api/settings');
    _throwIfError(res);
    return AppSettings.fromJson(res.data as Map<String, dynamic>);
  }

  /// PUT /api/settings — general fields + feature toggles only.
  /// Requires the Owner role for changes to actually be accepted server-side.
  Future<void> updateGeneral({
    required String appName,
    required String defaultExpiryHours,
    int? storageLimitMb,
  }) async {
    final res = await _dio.put('/api/settings', data: {
      'appName': appName,
      'defaultExpiryHours': defaultExpiryHours,
      'storageLimitMb': storageLimitMb,
    });
    _throwIfError(res);
  }

  Future<void> updateFeatureFlags({
    bool? memberAuthEnabled,
    bool? nearbyShareEnabled,
    bool? supportEnabled,
  }) async {
    final features = <String, dynamic>{};
    if (memberAuthEnabled != null) features['memberAuth'] = {'enabled': memberAuthEnabled};
    if (nearbyShareEnabled != null) features['nearbyShare'] = {'enabled': nearbyShareEnabled};
    if (supportEnabled != null) features['support'] = {'enabled': supportEnabled};
    final res = await _dio.put('/api/settings', data: {'features': features});
    _throwIfError(res);
  }

  void _throwIfError(Response res) {
    if (res.statusCode == null || res.statusCode! >= 400) {
      final message = (res.data is Map && res.data['error'] != null)
          ? res.data['error'].toString()
          : 'Request failed (${res.statusCode})';
      throw FileServiceException(message, statusCode: res.statusCode);
    }
  }
}
