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

class LastVisitedNotifier extends StateNotifier<LastVisitedEvent?> {
  LastVisitedNotifier() : super(null) {
    _load();
  }

  static const String _prefsKey = 'last_visited_event';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null) {
      try {
        state = LastVisitedEvent.fromJson(jsonDecode(jsonStr));
      } catch (_) {
        // Ignore corrupt data
      }
    }
  }

  Future<void> save(LastVisitedEvent event) async {
    state = event;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(event.toJson()));
  }
}

final lastVisitedProvider =
    StateNotifierProvider<LastVisitedNotifier, LastVisitedEvent?>((ref) {
  return LastVisitedNotifier();
});
