import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LastQuizResult {
  final String title;
  final int score;
  final int total;
  final int percentage;
  final String date;

  LastQuizResult({
    required this.title,
    required this.score,
    required this.total,
    required this.percentage,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'score': score,
        'total': total,
        'percentage': percentage,
        'date': date,
      };

  factory LastQuizResult.fromJson(Map<String, dynamic> json) => LastQuizResult(
        title: json['title'] as String? ?? '',
        score: json['score'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
        percentage: json['percentage'] as int? ?? 0,
        date: json['date'] as String? ?? '',
      );
}

class LastQuizResultNotifier extends StateNotifier<LastQuizResult?> {
  LastQuizResultNotifier() : super(null) {
    _load();
  }

  static const String _prefsKey = 'last_quiz_result';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null) {
      try {
        state = LastQuizResult.fromJson(jsonDecode(jsonStr));
      } catch (_) {
        // Ignore corrupt data
      }
      return;
    }

    final history = prefs.getStringList('quiz_history') ?? [];
    if (history.isEmpty) {
      return;
    }

    DateTime bestDate = DateTime(1970);
    Map<String, dynamic>? bestItem;

    for (final itemStr in history) {
      try {
        final item = jsonDecode(itemStr) as Map<String, dynamic>;
        final parsed = DateTime.tryParse(item['date'] ?? '') ?? DateTime(1970);
        if (parsed.isAfter(bestDate)) {
          bestDate = parsed;
          bestItem = item;
        }
      } catch (_) {
        // Ignore corrupt items
      }
    }

    if (bestItem != null) {
      state = LastQuizResult(
        title: bestItem['title'] as String? ?? '',
        score: bestItem['score'] as int? ?? 0,
        total: bestItem['total'] as int? ?? 0,
        percentage: bestItem['percentage'] as int? ?? 0,
        date: bestItem['date'] as String? ?? '',
      );
    }
  }

  Future<void> save(LastQuizResult result) async {
    state = result;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(result.toJson()));
  }
}

final lastQuizResultProvider =
    StateNotifierProvider<LastQuizResultNotifier, LastQuizResult?>((ref) {
  return LastQuizResultNotifier();
});
