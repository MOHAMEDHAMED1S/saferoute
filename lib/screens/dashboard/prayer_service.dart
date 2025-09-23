import 'dart:convert';
import 'package:http/http.dart' as http;

class PrayerService {
  static const String baseUrl =
      "https://api.aladhan.com/v1/timingsByCity?city=Cairo&country=Egypt&method=5";

  static Future<Map<String, dynamic>> fetchPrayerTimes() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["data"]["timings"];
    } else {
      throw Exception("فشل في جلب مواعيد الصلاة");
    }
  }
}