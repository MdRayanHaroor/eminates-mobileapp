import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final walkthroughProvider = StateNotifierProvider<WalkthroughNotifier, AsyncValue<bool>>((ref) {
  return WalkthroughNotifier();
});

class WalkthroughNotifier extends StateNotifier<AsyncValue<bool>> {
  WalkthroughNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  static const _key = 'walkthrough_seen';

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_key) ?? false;
      state = AsyncValue.data(seen);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  // For testing/debugging purposes
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = const AsyncValue.data(false);
  }
}
