import 'package:flutter/material.dart';
import 'package:saferoute/services/community_service.dart';
import 'package:saferoute/services/media_service.dart';
import 'package:saferoute/utils/error_handler.dart';
import 'package:saferoute/widgets/loading_widget.dart';
import 'package:saferoute/models/incident_report.dart';

class BackendConnectionTest extends StatefulWidget {
  const BackendConnectionTest({super.key});

  @override
  State<BackendConnectionTest> createState() => _BackendConnectionTestState();
}

class _BackendConnectionTestState extends State<BackendConnectionTest> {
  final CommunityService _communityService = CommunityService();
  final MediaService _mediaService = MediaService();
  bool _isLoading = false;
  String _testResults = '';

  @override
  void initState() {
    super.initState();
    _communityService.initialize();
  }

  @override
  void dispose() {
    _communityService.dispose();
    super.dispose();
  }

  Future<void> _testChatMessages() async {
    setState(() {
      _isLoading = true;
      _testResults = 'جاري اختبار الرسائل...';
    });

    try {
      final messages = await _communityService.getChatMessages();
      if (!mounted) return;
      setState(() {
        _testResults = 'تم استلام ${messages.length} رسالة بنجاح';
      });

      await _communityService.sendChatMessage(
        message: 'رسالة اختبار من تطبيق SafeRoute',
        userId: 'testUserId',
        userName: 'Test User',
      );
      if (!mounted) return;
      setState(() {
        _testResults += '\nتم إرسال رسالة اختبار بنجاح';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testResults += '\nفشل اختبار الرسائل: ${e.toString()}';
      });
      ErrorHandler.handleError(context, e);
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLeaderboard() async {
    setState(() {
      _isLoading = true;
      _testResults = 'جاري اختبار قائمة المتصدرين...';
    });

    try {
      final leaderboard = await _communityService.getLeaderboard();
      if (!mounted) return;
      setState(() {
        _testResults = 'تم استلام ${leaderboard.length} مستخدم في قائمة المتصدرين بنجاح';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testResults += '\nفشل اختبار قائمة المتصدرين: ${e.toString()}';
      });
      ErrorHandler.handleError(context, e);
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testIncidentReport() async {
    setState(() {
      _isLoading = true;
      _testResults = 'جاري اختبار إرسال بلاغ...';
    });

    try {
      final imageResult = await _mediaService.captureImageWithLocation();
      if (imageResult == null) {
        if (!mounted) return;
        setState(() {
          _testResults = 'تم إلغاء التقاط الصورة';
          _isLoading = false;
        });
        return;
      }

      await _communityService.sendIncidentReport(
        incidentType: IncidentType.accident,
        description: 'اختبار إرسال بلاغ',
        userId: 'testUserId',
        userName: 'Test User',
        location: {
          'latitude': imageResult['latitude'],
          'longitude': imageResult['longitude'],
        },
        imageUrl: imageResult['image'],
      );

      if (!mounted) return;
      setState(() {
        _testResults = 'تم إرسال البلاغ بنجاح';
      });
      ErrorHandler.showSuccessSnackBar(context, 'تم إرسال البلاغ بنجاح');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testResults += '\nفشل اختبار إرسال البلاغ: ${e.toString()}';
      });
      ErrorHandler.handleError(context, e);
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testOnlineUsers() async {
    setState(() {
      _isLoading = true;
      _testResults = 'جاري اختبار عدد المستخدمين المتصلين...';
    });

    try {
      final count = await _communityService.getOnlineUsersCount();
      if (!mounted) return;
      setState(() {
        _testResults = 'عدد المستخدمين المتصلين حالياً: $count';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testResults += '\nفشل اختبار عدد المستخدمين المتصلين: ${e.toString()}';
      });
      ErrorHandler.handleError(context, e);
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار الاتصال بالخادم'),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        loadingText: 'جاري الاختبار...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _testChatMessages,
                child: const Text('اختبار الرسائل'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _testLeaderboard,
                child: const Text('اختبار قائمة المتصدرين'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _testIncidentReport,
                child: const Text('اختبار إرسال بلاغ'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _testOnlineUsers,
                child: const Text('اختبار عدد المستخدمين المتصلين'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'نتائج الاختبار:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _testResults.isEmpty ? 'لم يتم إجراء أي اختبار بعد' : _testResults,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
