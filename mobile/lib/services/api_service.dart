import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TrendData {
  final String date;
  final double avgScore;
  final double avgErrors;
  final int totalSessions;

  TrendData({
    required this.date,
    required this.avgScore,
    required this.avgErrors,
    required this.totalSessions,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      date: json['date'],
      avgScore: (json['avg_score'] as num).toDouble(),
      avgErrors: (json['avg_errors'] as num).toDouble(),
      totalSessions: json['total_sessions'],
    );
  }
}

// Helper getter to avoid typing this multiple times
String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://neuroassist-ner-1.onrender.com';

Future<List<TrendData>> fetchAnalyticsTrends() async {
  final response = await http.get(Uri.parse('$_baseUrl/api/analytics/trends'));

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<dynamic> trendsJson = data['trends'];
    return trendsJson.map((json) => TrendData.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load trends data');
  }
}

Future<String> fetchPredictiveInsights() async {
  final response = await http.get(Uri.parse('$_baseUrl/api/ai/insights'));

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    return data['insight'] ?? "No insight generated.";
  } else {
    throw Exception('Failed to load AI insights');
  }
}