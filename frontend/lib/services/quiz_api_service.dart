import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:seerah_timeline/constants/api_constants.dart';
import '../models/quiz_model.dart';

class QuizApiService {
  // Using centralized ApiConstants
  static final String _baseUrl = ApiConstants.quizUrl;

  Future<List<QuizQuestion>> generateQuiz(String title, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'content': content}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> questionsJson = data['questions'];
        return questionsJson.map((q) => QuizQuestion.fromJson(q)).toList();
      } else {
        throw Exception('Failed to generate quiz: ${response.body}');
      }
    } catch (e) {
      print('Error generating quiz: $e');
      rethrow;
    }
  }
}
