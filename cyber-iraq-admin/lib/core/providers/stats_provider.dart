import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stats_service.dart';

final statsServiceProvider = Provider<StatsService>((ref) => StatsService());

final platformStatsProvider = FutureProvider<PlatformStats>((ref) {
  return ref.watch(statsServiceProvider).fetch();
});
