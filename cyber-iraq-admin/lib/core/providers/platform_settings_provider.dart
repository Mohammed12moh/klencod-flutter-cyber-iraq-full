import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/platform_settings_service.dart';

final platformSettingsServiceProvider =
    Provider<PlatformSettingsService>((ref) => PlatformSettingsService());

final platformSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(platformSettingsServiceProvider).fetchAll();
});
