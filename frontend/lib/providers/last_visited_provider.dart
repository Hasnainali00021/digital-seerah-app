import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LastVisitedEvent {
  final String id;
  final String title;
  final String? imageUrl;
  final String date;
  final String period;
  final String description;

  LastVisitedEvent({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.date,
    required this.period,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'date': date,
        'period': period,
        'description': description,
      };

  factory LastVisitedEvent.fromJson(Map<String, dynamic> json) =>
      LastVisitedEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        imageUrl: json['imageUrl'] as String?,
        date: json['date'] as String,
        period: json['period'] as String,
        description: json['description'] as String,
      );
}

/// Uses the SAME proven pattern as ReadEventsNotifier (which works).
class LastVisitedNotifier extends StateNotifier<LastVisitedEvent?> {
  LastVisitedNotifier() : super(null) {
    _initFuture = _load();
  }

  static const String _prefsKey = 'last_visited_event';
  late final Future<void> _initFuture;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        state = LastVisitedEvent.fromJson(jsonDecode(jsonStr));
        print('📖 Last visited loaded from disk: ${state!.title}');
      } catch (e) {
        print('⚠️ Corrupt last_visited_event: $e');
      }
    } else {
      print('ℹ️ No last visited event on disk');
    }
  }

  Future<void> save(LastVisitedEvent event) async {
    // Wait for initial load to finish first (same pattern as ReadEventsNotifier)
    await _initFuture;

    state = event;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(event.toJson());
    await prefs.setString(_prefsKey, jsonStr);

    // Immediately verify the save by reading back
    final verify = prefs.getString(_prefsKey);
    if (verify != null && verify == jsonStr) {
      print('✅ Last visited saved & verified: ${event.title}');
    } else {
      print('❌ SAVE VERIFICATION FAILED for: ${event.title}');
    }
  }

  /// Force reload from disk — use when app resumes from background.
  Future<void> reload() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        state = LastVisitedEvent.fromJson(jsonDecode(jsonStr));
        print('🔄 Last visited reloaded: ${state!.title}');
      } catch (e) {
        print('⚠️ Corrupt data on reload: $e');
      }
    } else {
      print('ℹ️ Nothing to reload from disk');
    }
  }
}

final lastVisitedProvider =
    StateNotifierProvider<LastVisitedNotifier, LastVisitedEvent?>((ref) {
  return LastVisitedNotifier();
});
