import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadEventsNotifier extends StateNotifier<List<String>> {
  ReadEventsNotifier() : super([]) {
    _initFuture = _load();
  }

  static const String _prefsKey = 'read_event_ids';
  late final Future<void> _initFuture;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList(_prefsKey);
    if (stored != null) {
      state = stored;
    }
  }

  Future<void> markRead(String id) async {
    // Always wait for the initial load to finish first
    await _initFuture;

    if (state.contains(id)) {
      return;
    }
    state = [...state, id];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state);
  }
}

final readEventsProvider =
    StateNotifierProvider<ReadEventsNotifier, List<String>>((ref) {
  return ReadEventsNotifier();
});
