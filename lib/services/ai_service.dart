import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AiSettings {
  String answerLength;
  String complexity;
  List<String> focusAreas;
  String targetExam;

  AiSettings({
    this.answerLength = 'Medium',
    this.complexity = 'Advanced',
    this.focusAreas = const ['Key Facts', 'Mechanisms'],
    this.targetExam = 'General',
  });

  Map<String, dynamic> toJson() => {
    'answerLength': answerLength,
    'complexity': complexity,
    'focusAreas': focusAreas,
    'targetExam': targetExam,
  };
}

class AiService {
  static const String baseUrl =
      'https://telecom-polls-herself-name.trycloudflare.com/api/generate';
  static const String model = 'phi3:mini';

  static const String systemPrompt = '''
You are a medical-only AI assistant.

STRICT RULES:
- Answer ONLY medical or healthcare-related questions.
- If the question is not medical, reply: "I can only answer medical-related questions."
- Output ONLY valid JSON. 
- No explanations, no markdown, no extra text.
''';

  /// ===============================
  /// SINGLE FLASHCARD
  /// ===============================
  Future<Map<String, String>> generateAnswer({
    required String question,
    required String topic,
    required String subject,
    required AiSettings settings,
  }) async {
    final prompt =
        '''
SYSTEM RULES (MANDATORY):
- Output ONLY valid JSON in this schema:
{
  "back": "Answer text",
  "explanation": "Explanation text"
}

QUESTION: "$question"
SUBJECT: $subject
TOPIC: $topic
''';

    try {
      final res = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'system': systemPrompt,
              'prompt': prompt,
              'stream': false,
              'format': 'json',
              'options': {'num_predict': 1500, 'temperature': 0.1},
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (res.statusCode != 200)
        throw Exception('AI Server error ${res.statusCode}');

      final data = jsonDecode(res.body);
      final responseText = (data['response'] ?? '').toString();
      debugPrint('AI Answer Response: $responseText');

      final clean = _tryExtractJson(responseText);
      final decoded = jsonDecode(clean);

      return {
        'back': decoded['back']?.toString() ?? 'No answer generated',
        'explanation': decoded['explanation']?.toString() ?? '',
      };
    } catch (e) {
      debugPrint('Generate Answer Error: $e');
      throw Exception('Failed to generate answer. Please try again.');
    }
  }

  /// ===============================
  /// FLASHCARDS
  /// ===============================
  Future<Map<String, dynamic>> generateFlashcards({
    required String topic,
    required String subject,
    required String folderTitle,
    required String examType,
    required int count,
    required double difficulty,
    required String contentType,
  }) async {
    final difficultyLabel = difficulty < 0.33
        ? 'Beginner'
        : difficulty < 0.66
        ? 'Intermediate'
        : 'Advanced';

    final prompt =
        '''
STRICT TASK: Generate EXACTLY $count medical flashcards.
TOPIC: $topic
SUBJECT: $subject
DIFFICULTY: $difficultyLabel

RULES (MANDATORY):
1. Return ONLY a JSON array of objects.
2. NO text before or after the JSON.
3. EACH object MUST HAVE: "front", "back", "explanation".

JSON SCHEMA:
[
  {
    "front": "The question or term",
    "back": "The concise answer",
    "explanation": "A detailed medical explanation"
  }
]
''';

    try {
      final res = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'system': systemPrompt,
              'prompt': prompt,
              'stream': false,
              'format': 'json',
              'options': {'num_predict': 4000, 'temperature': 0.1},
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (res.statusCode != 200)
        throw Exception('AI Server error ${res.statusCode}');

      final data = jsonDecode(res.body);
      final responseText = (data['response'] ?? '').toString();
      debugPrint('AI Flashcards Response: $responseText');

      final clean = _tryExtractJson(responseText);
      final decoded = jsonDecode(clean);

      List<dynamic> rawList = [];

      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map) {
        // AI might return {"flashcards": []} or similar
        // Look for any list that contains objects
        final listValue = decoded.values.firstWhere(
          (v) =>
              v is List &&
              v.isNotEmpty &&
              v.every(
                (e) =>
                    e is Map &&
                    (e.containsKey('front') || e.containsKey('question')),
              ),
          orElse: () => null,
        );

        if (listValue != null) {
          rawList = listValue as List;
        } else if (decoded.containsKey('front') ||
            decoded.containsKey('back')) {
          // It's a single card object
          rawList = [decoded];
        } else {
          // Maybe it's a map of maps? {"1": {}, "2": {}}
          final maps = decoded.values.whereType<Map>().toList();
          if (maps.isNotEmpty) {
            rawList = maps;
          }
        }
      }

      final normalized = rawList.map((item) {
        if (item is Map) {
          // Normalize individual values
          String f = _normalizeValue(
            item['front'] ?? item['question'] ?? item['q'] ?? item['Point'],
          );
          String b = _normalizeValue(
            item['back'] ?? item['answer'] ?? item['a'] ?? item['Description'],
          );
          String e = _normalizeValue(
            item['explanation'] ??
                item['details'] ??
                item['info'] ??
                item['reasoning'],
          );

          if (f.isEmpty && item.values.isNotEmpty)
            f = _normalizeValue(item.values.first);
          if (b.isEmpty && item.values.length > 1)
            b = _normalizeValue(item.values.elementAt(1));

          return {
            'front': f.isEmpty ? 'Knowledge Point' : f,
            'back': b.isEmpty ? 'Description' : b,
            'explanation': e,
          };
        }
        return {'front': topic, 'back': item.toString(), 'explanation': ''};
      }).toList();

      debugPrint('Normalized Count: ${normalized.length}');

      return {'success': true, 'answer': jsonEncode(normalized)};
    } catch (e) {
      debugPrint('Generate Flashcards Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// ===============================
  /// SUGGESTIONS
  /// ===============================
  Future<List<String>> suggestNextQuestions({
    required String topic,
    required String subject,
    required List<String> existingQuestions,
    required AiSettings settings,
  }) async {
    // Limit context to prevent AI saturation
    final recentQuestions = existingQuestions.length > 5
        ? existingQuestions.sublist(existingQuestions.length - 5)
        : existingQuestions;

    final prompt =
        '''
SYSTEM RULES (MANDATORY):
- Output ONLY a JSON array of 3 DIFFERENT follow-up medical questions.
- Each question MUST be a unique, real medical study question.
- DO NOT use placeholders like "New Question A?" or "Question 1?".
- NO markdown. NO text. NO repetitions.
- Start with [ and end with ].

CONTEXT:
Topic: $topic
Subject: $subject
Already Covered: ${recentQuestions.join('; ')}
''';

    try {
      final res = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'system': systemPrompt,
              'prompt': prompt,
              'stream': false,
              'format': 'json',
              'options': {'num_predict': 500, 'temperature': 0.7},
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);
      final responseText = (data['response'] ?? '').toString();
      debugPrint('AI Suggestions Response: $responseText');

      final clean = _tryExtractJson(responseText);
      final decoded = jsonDecode(clean);

      final List<String> rawQuestions = [];
      if (decoded is List) {
        rawQuestions.addAll(
          decoded.map((e) {
            if (e is Map)
              return (e['question'] ?? e['front'] ?? e.values.first).toString();
            return e.toString();
          }),
        );
      } else if (decoded is Map) {
        final innerList = decoded.values.firstWhere(
          (v) => v is List,
          orElse: () => null,
        );
        if (innerList != null && (innerList as List).isNotEmpty) {
          rawQuestions.addAll(
            innerList.map((e) {
              if (e is Map)
                return (e['question'] ?? e['front'] ?? e.values.first)
                    .toString();
              return e.toString();
            }),
          );
        } else {
          decoded.forEach((key, value) {
            // Check if the key itself is a medical question (ignore placeholders like "New Question A")
            if (key.toString().contains('?') &&
                !key.toString().toLowerCase().contains('question a')) {
              rawQuestions.add(key.toString());
            } else if (value is String && value.contains('?')) {
              rawQuestions.add(value);
            } else if (value is String && value.length > 10) {
              rawQuestions.add(value);
            }
          });

          if (rawQuestions.isEmpty && decoded.values.isNotEmpty) {
            final firstVal = decoded.values.first.toString();
            if (!firstVal.toLowerCase().contains('question a')) {
              rawQuestions.add(firstVal);
            }
          }
        }
      }

      // Smart Split: If we only got 1 item, check if it contains multiple questions
      final List<String> finalQuestions = [];
      for (var q in rawQuestions) {
        if (rawQuestions.length == 1 &&
            (q.contains('?') && q.indexOf('?') != q.lastIndexOf('?'))) {
          final split = q
              .split(RegExp(r'(?<=\?)\s*'))
              .where((s) => s.isNotEmpty)
              .toList();
          finalQuestions.addAll(split);
        } else {
          finalQuestions.add(q);
        }
      }

      final result = finalQuestions
          .where((q) {
            final lq = q.toLowerCase();
            // Filter out AI placeholders/labels
            if (lq.contains('new question') || lq.contains('example question'))
              return false;
            if (lq.length < 8) return false;
            return true;
          })
          .map((q) => q.trim())
          .toSet()
          .toList();

      return result.take(5).toList();
    } catch (e) {
      debugPrint('Suggest Questions Error: $e');
      return [];
    }
  }

  /// ===============================
  /// INTERNAL HELPERS (NO REGEX)
  /// ===============================

  String _tryExtractJson(String text) {
    text = text.trim();

    int openBrace = text.indexOf('{');
    int openBracket = text.indexOf('[');

    if (openBrace == -1 && openBracket == -1) return text;

    // Pick the earliest opening character
    int start;
    if (openBrace != -1 && openBracket != -1) {
      start = openBrace < openBracket ? openBrace : openBracket;
    } else {
      start = openBrace != -1 ? openBrace : openBracket;
    }

    int closeBrace = text.lastIndexOf('}');
    int closeBracket = text.lastIndexOf(']');

    // Pick the latest closing character
    int end;
    if (closeBrace != -1 && closeBracket != -1) {
      end = closeBrace > closeBracket ? closeBrace : closeBracket;
    } else {
      end = closeBrace != -1 ? closeBrace : closeBracket;
    }

    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }

    return text;
  }

  /// Helper to convert various AI types into strings
  String _normalizeValue(dynamic val) {
    if (val == null) return '';
    if (val is String) return val.trim();
    if (val is List) return val.map((i) => i.toString()).join('\n').trim();
    if (val is Map) {
      // Return the first string-like value found in the map
      final firstStr = val.values.firstWhere(
        (v) => v is String,
        orElse: () => null,
      );
      if (firstStr != null) return firstStr.toString().trim();
      return val.toString();
    }
    return val.toString().trim();
  }
}
