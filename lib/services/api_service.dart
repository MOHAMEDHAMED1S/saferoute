import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:saferoute/models/chat_message.dart';
import 'package:saferoute/models/incident_report.dart';
import 'package:saferoute/models/leaderboard_user.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.saferoute.app/v1';

  // تهيئة الخدمة
  Future<void> initialize() async {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // إضافة interceptors للتعامل مع الأخطاء والتوثيق
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // يمكن إضافة توكن المصادقة هنا
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));
  }

  // الحصول على رسائل الدردشة
  Future<List<ChatMessage>> getChatMessages() async {
    try {
      final response = await _dio.get('/chat/messages');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting chat messages: $e');
      throw 'Failed to load chat messages';
    }
  }

  // إرسال رسالة دردشة
  Future<ChatMessage> sendChatMessage({
    required String userId,
    required String userName,
    required String message,
    String? userAvatar,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'userId': userId,
        'userName': userName,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (userAvatar != null) {
        data['userAvatar'] = userAvatar;
      }
      
      final response = await _dio.post('/chat/messages', data: data);
      return ChatMessage.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('Error sending chat message: $e');
      throw 'Failed to send message';
    }
  }

  // إرسال تقرير حادث
  Future<IncidentReport> sendIncidentReport({
    required String userId,
    required String userName,
    required IncidentType incidentType,
    Map<String, double>? location,
    String? imageUrl,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'userId': userId,
        'userName': userName,
        'incidentType': incidentType.toString().split('.').last,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (location != null) {
        data['location'] = location;
      }

      if (imageUrl != null) {
        data['imageUrl'] = imageUrl;
      }

      if (description != null) {
        data['description'] = description;
      }

      final response = await _dio.post('/incidents/reports', data: data);
      return IncidentReport.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('Error sending incident report: $e');
      throw 'Failed to send incident report';
    }
  }

  // الحصول على قائمة المتصدرين
  Future<List<LeaderboardUser>> getLeaderboard() async {
    try {
      final response = await _dio.get('/community/leaderboard');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => LeaderboardUser.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      throw 'Failed to load leaderboard';
    }
  }
  
  // الحصول على عدد المستخدمين المتصلين
  Future<int> getOnlineUsersCount() async {
    try {
      final response = await _dio.get('/community/online-users/count');
      return response.data['count'] as int;
    } catch (e) {
      debugPrint('Error getting online users count: $e');
      throw 'Failed to get online users count';
    }
  }
}