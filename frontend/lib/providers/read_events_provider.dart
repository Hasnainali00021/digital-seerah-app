import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadEventsNotifier extends StateNotifier<List<String>> {
  ReadEventsNotifier() : super([]) {
    _load();
  }

  static const String _prefsKey = 'read_event_ids';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey);
    if (stored != null) {
      final merged = {...state, ...stored}.toList();
      state = merged;
    }
  }

  Future<void> markRead(String id) async {
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
