import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math' as math;
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/reports_provider.dart';
import '../../models/report_model.dart';
import '../../models/dashboard_models.dart';
import '../../models/incident_report.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';
import '../../services/reports_firebase_service.dart';
import '../../services/location_service.dart';

class AddReportScreen extends StatefulWidget {
  static const String routeName = '/add-report';
  const AddReportScreen({Key? key}) : super(key: key);

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  ReportType? _selectedType;
  bool _isSubmitting = false;
  int _currentStep = 0; // 0: نوع البلاغ، 1: التفاصيل، 2: المراجعة
  double _selectedDistance = 100; // المسافة بالمتر

  // إضافة متغيرات للصور
  final ImagePicker _picker = ImagePicker();
  List<XFile> _reportImages = [];

  final List<String> _stepTitles = [
    'اختر نوع البلاغ',
    'أضف التفاصيل',
    'راجع البلاغ',
  ];
  final List<double> _distanceOptions = [
    50,
    100,
    200,
    500,
    1000,
  ]; // خيارات المسافة بالمتر

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  // دالة لالتقاط الصور من الكاميرا
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _reportImages.add(image);
        });
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء التقاط الصورة');
    }
  }

  // دالة لاختيار الصور من المعرض
  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(
        imageQuality: 80,
      );
      if (images != null && images.isNotEmpty) {
        setState(() {
          _reportImages.addAll(images);
          if (_reportImages.length > 3) {
            _reportImages = _reportImages.sublist(0, 3);
            _showErrorSnackBar('يمكنك إضافة 3 صور كحد أقصى');
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء اختيار الصور');
    }
  }

  // دالة لحذف صورة
  void _removeImage(int index) {
    setState(() {
      _reportImages.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) {
      _showErrorSnackBar('يرجى ملء جميع الحقول المطلوبة');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );

    if (!authProvider.isLoggedIn) {
      _showErrorSnackBar('يجب تسجيل الدخول أولاً');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      debugPrint('AddReportScreen: بدء عملية إرسال البلاغ');

      // فحص حالة المصادقة مرة أخرى قبل الإرسال
      if (!authProvider.isLoggedIn || authProvider.userModel == null) {
        debugPrint('AddReportScreen: المستخدم غير مسجل دخول، إعادة توجيه');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // الحصول على الموقع الحالي
      final currentLocation = await locationService.getCurrentLocation();
      debugPrint(
        'AddReportScreen: تم الحصول على الموقع: ${currentLocation.latitude}, ${currentLocation.longitude}',
      );

      // إنشاء كائن ReportsFirebaseService
      final reportsFirebaseService = ReportsFirebaseService();

      // إنشاء نموذج الإبلاغ
      final report = ReportModel(
        id: '', // سيتم تعيينه بواسطة Firestore
        type: _selectedType!,
        description: _descriptionController.text.trim(),
        location: ReportLocation(
          lat: currentLocation.latitude,
          lng: currentLocation.longitude,
        ),
        createdBy: authProvider.userModel!.id,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 24)), // صلاحية 24 ساعة
        status: ReportStatus.pending,
        confirmations: ReportConfirmations(trueVotes: 0, falseVotes: 0),
        confirmedBy: [],
        deniedBy: [],
        imageUrls: [],
        updatedAt: DateTime.now(),
      );

      debugPrint('AddReportScreen: تم إنشاء نموذج البلاغ');

      // رفع الصور وإنشاء الإبلاغ
      String reportId = '';
      if (_reportImages.isNotEmpty) {
        debugPrint('AddReportScreen: رفع الصور مع البلاغ');
        // استخدام الدالة الجديدة لرفع الصور وإنشاء الإبلاغ
        reportId = await reportsFirebaseService.createReportWithImages(
          report,
          _reportImages,
        );

        if (reportId.isEmpty) {
          debugPrint('AddReportScreen: فشل في إرسال البلاغ مع الصور');
          _showErrorSnackBar(
            'خطأ في إرسال البلاغ - لم يتم الحصول على معرف البلاغ',
          );
          return;
        }
        debugPrint(
          'AddReportScreen: تم إرسال البلاغ مع الصور بنجاح: $reportId',
        );
      } else {
        debugPrint('AddReportScreen: إرسال البلاغ بدون صور');
        // إنشاء إبلاغ بدون صور
        reportId = await reportsFirebaseService.createReport(report);
        if (reportId.isEmpty) {
          debugPrint('AddReportScreen: فشل في إرسال البلاغ بدون صور');
          _showErrorSnackBar(
            'خطأ في إرسال البلاغ - لم يتم الحصول على معرف البلاغ',
          );
          return;
        }
        debugPrint(
          'AddReportScreen: تم إرسال البلاغ بدون صور بنجاح: $reportId',
        );
      }

      // إضافة البلاغ إلى Dashboard و Map بدلاً من المجتمع
      try {
        debugPrint('AddReportScreen: إضافة البلاغ إلى Dashboard والخريطة');
        
        // إضافة البلاغ إلى Dashboard Provider
        final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
        final nearbyReport = NearbyReport(
          id: reportId,
          title: '${_getReportTypeNameArabic(_selectedType!)} - ${_descriptionController.text.trim().substring(0, math.min(20, _descriptionController.text.trim().length))}...',
          description: _descriptionController.text.trim(),
          distance: '0م', // سيتم حساب المسافة الفعلية في Dashboard Provider
          timeAgo: 'الآن',
          confirmations: 0,
          type: _selectedType!,
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
        );
        dashboardProvider.addNearbyReport(nearbyReport);
        
        // تحديث Reports Provider لإظهار البلاغ على الخريطة
        final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);
        await reportsProvider.refreshLocation();
        
        debugPrint('AddReportScreen: تم إضافة البلاغ إلى Dashboard والخريطة بنجاح');
      } catch (e) {
        debugPrint('AddReportScreen: خطأ في إضافة البلاغ إلى Dashboard والخريطة: $e');
        // لا نوقف العملية هنا، البلاغ تم حفظه في Firestore
      }

      _showSuccessDialog();
    } catch (e) {
      debugPrint('AddReportScreen: خطأ في إرسال البلاغ: $e');
      _showErrorSnackBar('خطأ في إرسال البلاغ: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: LiquidGlassTheme.getGradientByName(
          'danger',
        ).colors.first,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: LiquidGlassTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LiquidGlassTheme.getGradientByName(
                  'success',
                ).colors.first.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 48,
                color: LiquidGlassTheme.getGradientByName(
                  'success',
                ).colors.first,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'تم إرسال البلاغ بنجاح!',
              style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'شكراً لمساهمتك في تحسين السلامة على الطرق',
              style: LiquidGlassTheme.bodyTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            LiquidGlassButton(
              text: 'حسناً',
              onPressed: () {
                if (!mounted) return;

                try {
                  // إغلاق الحوار أولاً
                  Navigator.of(context).pop();

                  // العودة للصفحة الرئيسية مباشرة
                  if (mounted) {
                    try {
                      // استخدام pushReplacementNamed للعودة للصفحة الرئيسية
                      Navigator.of(context).pushReplacementNamed('/dashboard');
                    } catch (e) {
                      debugPrint('AddReportScreen: خطأ في التنقل: $e');
                      // محاولة بديلة للعودة
                      if (mounted) {
                        try {
                          Navigator.of(context).pop();
                        } catch (popError) {
                          debugPrint('AddReportScreen: خطأ في pop: $popError');
                        }
                      }
                    }
                  }
                } catch (e) {
                  debugPrint('AddReportScreen: خطأ في إغلاق الحوار: $e');
                  // محاولة إغلاق الحوار بطريقة بديلة
                  if (mounted) {
                    try {
                      Navigator.of(context).pop();
                    } catch (popError) {
                      debugPrint(
                        'AddReportScreen: خطأ في pop البديل: $popError',
                      );
                    }
                  }
                }
              },
              type: LiquidGlassType.primary,
              borderRadius: 12,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header مخصص مع شريط التقدم
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // شريط العلوي مع اللوجو والعنوان
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.jpg',
                        width: 40,
                        height: 40,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إنشاء بلاغ جديد',
                              style: LiquidGlassTheme.headerTextStyle.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _stepTitles[_currentStep],
                              style: LiquidGlassTheme.bodyTextStyle.copyWith(
                                fontSize: 14,
                                color: LiquidGlassTheme.getTextColor(
                                  'secondary',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // شريط التقدم
                  _buildProgressBar(),
                ],
              ),
            ),

            // المحتوى الأساسي
            Expanded(
              child: Form(
                key: _formKey,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildCurrentStepContent(),
                      ),
                    );
                  },
                ),
              ),
            ),

            // الأزرار السفلية
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isActive
                        ? LiquidGlassTheme.getGradientByName(
                            'primary',
                          ).colors.first
                        : LiquidGlassTheme.getTextColor(
                            'secondary',
                          ).withOpacity(0.3),
                  ),
                ),
              ),
              if (index < 2) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildReportTypeStep();
      case 1:
        return _buildDescriptionStep();
      case 2:
        return _buildReviewStep();
      default:
        return _buildReportTypeStep();
    }
  }

  Widget _buildReportTypeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LiquidGlassContainer(
            type: LiquidGlassType.secondary,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LiquidGlassTheme.getGradientByName(
                      'info',
                    ).colors.first.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: LiquidGlassTheme.getGradientByName(
                      'info',
                    ).colors.first,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختر نوع المخطر',
                        style: LiquidGlassTheme.headerTextStyle.copyWith(
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'حدد نوع المخطر الذي تريد الإبلاغ عنه',
                        style: LiquidGlassTheme.bodyTextStyle.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildReportTypeGrid(),
        ],
      ),
    );
  }

  Widget _buildDescriptionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عرض النوع المحدد مع تصميم محسن
          LiquidGlassContainer(
            type: LiquidGlassType.secondary,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getReportColor(_selectedType!).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getReportIcon(_selectedType!),
                    color: _getReportColor(_selectedType!),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getReportTypeTitle(_selectedType!),
                        style: LiquidGlassTheme.headerTextStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'تم اختيار هذا النوع من البلاغات',
                        style: LiquidGlassTheme.bodyTextStyle.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _previousStep,
                  icon: Icon(
                    Icons.edit,
                    size: 16,
                    color: LiquidGlassTheme.getGradientByName(
                      'primary',
                    ).colors.first,
                  ),
                  label: Text(
                    'تغيير',
                    style: TextStyle(
                      color: LiquidGlassTheme.getGradientByName(
                        'primary',
                      ).colors.first,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // حقل الوصف مع تصميم محسن
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: LiquidGlassTheme.getGradientByName(
                  'primary',
                ).colors.first,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'وصف مفصل للمخطر',
                style: LiquidGlassTheme.headerTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'اكتب وصفاً واضحاً يساعد السائقين الآخرين على فهم المخطر',
            style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 16),

          LiquidGlassContainer(
            type: LiquidGlassType.ultraLight,
            isInteractive: true,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              controller: _descriptionController,
              maxLines: 6,
              style: LiquidGlassTheme.primaryTextStyle,
              decoration: InputDecoration(
                hintText: _getDescriptionHint(_selectedType!),
                hintStyle: LiquidGlassTheme.bodyTextStyle.copyWith(
                  color: LiquidGlassTheme.getTextColor('secondary'),
                ),
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال وصف البلاغ';
                }
                if (value.trim().length < 10) {
                  return 'يجب أن يكون الوصف 10 أحرف على الأقل';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 24),

          // إضافة صور للبلاغ
          Row(
            children: [
              Icon(
                Icons.photo_camera_outlined,
                color: LiquidGlassTheme.getGradientByName(
                  'primary',
                ).colors.first,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'إضافة صور للبلاغ',
                style: LiquidGlassTheme.headerTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '(اختياري)',
                style: LiquidGlassTheme.bodyTextStyle.copyWith(
                  fontSize: 12,
                  color: LiquidGlassTheme.getTextColor('secondary'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك إضافة حتى 3 صور توضيحية للبلاغ',
            style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 16),

          // عرض الصور المختارة
          if (_reportImages.isNotEmpty)
            Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _reportImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImageWidget(_reportImages[index]),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          // أزرار إضافة الصور
          Row(
            children: [
              Expanded(
                child: LiquidGlassButton(
                  text: 'التقاط صورة',
                  onPressed: _reportImages.length >= 3
                      ? null
                      : _pickImageFromCamera,
                  type: LiquidGlassType.secondary,
                  borderRadius: 12,
                  icon: Icons.camera_alt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LiquidGlassButton(
                  text: ' من المعرض',
                  onPressed: _reportImages.length >= 3
                      ? null
                      : _pickImagesFromGallery,
                  type: LiquidGlassType.secondary,
                  borderRadius: 12,
                  icon: Icons.photo_library,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // تحديد المسافة
          Row(
            children: [
              Icon(
                Icons.straighten_outlined,
                color: LiquidGlassTheme.getGradientByName(
                  'primary',
                ).colors.first,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'مسافة تأثير البلاغ',
                style: LiquidGlassTheme.headerTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'حدد المسافة التي يؤثر فيها هذا البلاغ على السائقين',
            style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 16),

          _buildDistanceSelector(),

          const SizedBox(height: 24),

          // معلومات الموقع مع تصميم محسن
          LiquidGlassContainer(
            type: LiquidGlassType.primary,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: LiquidGlassTheme.getGradientByName(
                      'success',
                    ).colors.first.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: LiquidGlassTheme.getGradientByName(
                      'success',
                    ).colors.first,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الموقع الحالي',
                        style: LiquidGlassTheme.headerTextStyle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'سيتم استخدام موقعك الحالي للبلاغ',
                        style: LiquidGlassTheme.bodyTextStyle.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: LiquidGlassTheme.getGradientByName(
                    'success',
                  ).colors.first,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان المراجعة مع أيقونة
          Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                color: LiquidGlassTheme.getGradientByName(
                  'primary',
                ).colors.first,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'مراجعة البلاغ',
                style: LiquidGlassTheme.headerTextStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'راجع تفاصيل البلاغ قبل الإرسال للتأكد من صحة المعلومات',
            style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 24),

          // عرض نوع البلاغ بتصميم محسن
          LiquidGlassContainer(
            type: LiquidGlassType.ultraLight,
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            // تعيين لون الخلفية إلى اللون الأبيض
            backgroundColor: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      color: _getReportColor(
                        _selectedType ?? ReportType.accident,
                      ),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'نوع البلاغ',
                      style: LiquidGlassTheme.bodyTextStyle.copyWith(
                        color: LiquidGlassTheme.primaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _currentStep = 0),
                      child: Text(
                        'تعديل',
                        style: TextStyle(
                          color: LiquidGlassTheme.getGradientByName(
                            'primary',
                          ).colors.first,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getReportColor(
                          _selectedType!,
                        ).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getReportIcon(_selectedType!),
                        color: _getReportColor(_selectedType!),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getReportTypeTitle(_selectedType!),
                      style: LiquidGlassTheme.headerTextStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // عرض الوصف بتصميم محسن
          LiquidGlassContainer(
            type: LiquidGlassType.ultraLight,
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            backgroundColor: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: LiquidGlassTheme.primaryTextColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'وصف البلاغ',
                      style: LiquidGlassTheme.bodyTextStyle.copyWith(
                        color: LiquidGlassTheme.primaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _currentStep = 1),
                      child: Text(
                        'تعديل',
                        style: TextStyle(
                          color: LiquidGlassTheme.getGradientByName(
                            'primary',
                          ).colors.first,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _descriptionController.text,
                  style: LiquidGlassTheme.primaryTextStyle,
                ),
              ],
            ),
          ),

          // عرض الصور المرفقة
          if (_reportImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            LiquidGlassContainer(
              type: LiquidGlassType.ultraLight,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              backgroundColor: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        color: LiquidGlassTheme.primaryTextColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'الصور المرفقة',
                        style: LiquidGlassTheme.bodyTextStyle.copyWith(
                          color: LiquidGlassTheme.primaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _currentStep = 1),
                        child: Text(
                          'تعديل',
                          style: TextStyle(
                            color: LiquidGlassTheme.getGradientByName(
                              'primary',
                            ).colors.first,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _reportImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildImageWidget(_reportImages[index]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // رسالة عندما لا توجد صور مرفقة
            const SizedBox(height: 16),
            LiquidGlassContainer(
              type: LiquidGlassType.ultraLight,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              backgroundColor: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        color: Colors.grey.shade400,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'الصور المرفقة',
                        style: LiquidGlassTheme.bodyTextStyle.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _currentStep = 1),
                        child: Text(
                          'إضافة',
                          style: TextStyle(
                            color: LiquidGlassTheme.getGradientByName(
                              'primary',
                            ).colors.first,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'لا توجد صور مرفقة',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // عرض المسافة بتصميم محسن
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.straighten_outlined,
                      color: LiquidGlassTheme.getTextColor('secondary'),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'مسافة التأثير',
                      style: LiquidGlassTheme.bodyTextStyle.copyWith(
                        color: LiquidGlassTheme.getTextColor('secondary'),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _currentStep = 1),
                      child: Text(
                        'تعديل',
                        style: TextStyle(
                          color: LiquidGlassTheme.getGradientByName(
                            'primary',
                          ).colors.first,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: LiquidGlassTheme.getGradientByName(
                          'info',
                        ).colors.first.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.route,
                        color: LiquidGlassTheme.getGradientByName(
                          'info',
                        ).colors.first,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getDistanceDescription(_selectedDistance),
                      style: LiquidGlassTheme.primaryTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // عرض الموقع بتصميم محسن
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: LiquidGlassTheme.getTextColor('secondary'),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'الموقع',
                      style: LiquidGlassTheme.bodyTextStyle.copyWith(
                        color: LiquidGlassTheme.getTextColor('secondary'),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: LiquidGlassTheme.getGradientByName(
                          'success',
                        ).colors.first.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: LiquidGlassTheme.getGradientByName(
                          'success',
                        ).colors.first,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الموقع الحالي',
                          style: LiquidGlassTheme.primaryTextStyle.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'سيتم استخدام موقعك الحالي للبلاغ',
                          style: LiquidGlassTheme.bodyTextStyle.copyWith(
                            fontSize: 12,
                            color: LiquidGlassTheme.getTextColor('secondary'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_isSubmitting) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    'جاري إرسال البلاغ...',
                    style: LiquidGlassTheme.bodyTextStyle,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: LiquidGlassButton(
                text: 'السابق',
                onPressed: _previousStep,
                type: LiquidGlassType.secondary,
                borderRadius: 12,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: LiquidGlassButton(
              text: _getButtonText(),
              onPressed: _getButtonAction(),
              type: LiquidGlassType.primary,
              borderRadius: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        return _selectedType == null ? 'اختر نوع البلاغ' : 'التالي';
      case 1:
        return 'مراجعة البلاغ';
      case 2:
        return _isSubmitting ? 'جاري الإرسال...' : 'إرسال البلاغ';
      default:
        return 'التالي';
    }
  }

  VoidCallback? _getButtonAction() {
    if (_isSubmitting) return null;

    switch (_currentStep) {
      case 0:
        return _selectedType == null ? null : _nextStep;
      case 1:
        return _formKey.currentState?.validate() == true
            ? _nextStep
            : () {
                _formKey.currentState?.validate();
              };
      case 2:
        return _submitReport;
      default:
        return _nextStep;
    }
  }

  Widget _buildReportTypeGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.3, // تعديل نسبة العرض للارتفاع
      crossAxisSpacing: 12, // تقليل المسافة بين العناصر
      mainAxisSpacing: 12, // تقليل المسافة بين العناصر
      children: ReportType.values.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedType = type;
            });
            // تأثير اهتزاز خفيف عند الاختيار
            HapticFeedback.lightImpact();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuart,
            // تكبير الكارد عند الاختيار
            transform: isSelected
                ? (Matrix4.identity()..scale(1.05))
                : Matrix4.identity(),
            transformAlignment: Alignment.center,
            child: LiquidGlassContainer(
              type: isSelected
                  ? LiquidGlassType.primary
                  : LiquidGlassType.ultraLight,
              isInteractive: true,
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.all(14), // تقليل الحشو الداخلي
              backgroundColor: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(
                      10,
                    ), // تقليل الحشو الداخلي للأيقونة
                    decoration: BoxDecoration(
                      color: _getReportColor(
                        type,
                      ).withOpacity(isSelected ? 0.25 : 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? Border.all(color: _getReportColor(type), width: 2)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _getReportColor(type).withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _getReportIcon(type),
                      size: 26, // تقليل حجم الأيقونة قليلاً
                      color: _getReportColor(type),
                    ),
                  ),
                  const SizedBox(height: 8), // تقليل المسافة
                  Text(
                    _getReportTypeTitle(type),
                    style: LiquidGlassTheme.headerTextStyle.copyWith(
                      fontSize: isSelected
                          ? 15
                          : 14, // زيادة حجم النص عند الاختيار
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? _getReportColor(
                              type,
                            ) // تغيير لون النص ليكون بنفس لون نوع التقرير عند الاختيار
                          : LiquidGlassTheme.primaryTextColor.withOpacity(
                              0.9,
                            ), // تعتيم النص قليلاً عند عدم الاختيار
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'محدد',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getDescriptionHint(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return 'مثال: حادث بسيط بين سيارتين في المسار الأيمن، لا توجد إصابات...';
      case ReportType.jam:
        return 'مثال: ازدحام شديد بسبب أعمال صيانة، السرعة أقل من 10 كم/س...';
      case ReportType.carBreakdown:
        return 'مثال: سيارة معطلة في المسار الأيسر، السائق يطلب المساعدة...';
      case ReportType.bump:
        return 'مثال: مطب كبير وخطير قد يضر بالسيارات، غير واضح في الليل...';
      case ReportType.closedRoad:
        return 'مثال: الطريق مغلق بالكامل بسبب أعمال الصيانة، يوجد طريق بديل...';
      default:
        return 'اكتب وصفاً مفصلاً للمخطر...';
    }
  }

  IconData _getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return Icons.car_crash;
      case ReportType.jam:
        return Icons.traffic;
      case ReportType.carBreakdown:
        return Icons.car_repair;
      case ReportType.bump:
        return Icons.warning;
      case ReportType.closedRoad:
        return Icons.block;
      default:
        return Icons.report;
    }
  }

  Color _getReportColor(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return LiquidGlassTheme.getGradientByName('danger').colors.first;
      case ReportType.jam:
        return LiquidGlassTheme.getGradientByName('warning').colors.first;
      case ReportType.carBreakdown:
        return LiquidGlassTheme.getGradientByName('info').colors.first;
      case ReportType.bump:
        return LiquidGlassTheme.getGradientByName('warning').colors.last;
      case ReportType.closedRoad:
        return LiquidGlassTheme.getGradientByName('primary').colors.first;
      default:
        return LiquidGlassTheme.getTextColor('secondary');
    }
  }

  String _getReportTypeTitle(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return 'حادث مروري';
      case ReportType.jam:
        return 'ازدحام مروري';
      case ReportType.carBreakdown:
        return 'عطل مركبة';
      case ReportType.bump:
        return 'مطب';
      case ReportType.closedRoad:
        return 'طريق مغلق';
      default:
        return 'بلاغ';
    }
  }

  Widget _buildDistanceSelector() {
    return LiquidGlassContainer(
      type: LiquidGlassType.ultraLight,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المسافة: ${_selectedDistance.toInt()} متر',
                style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: LiquidGlassTheme.getGradientByName(
                    'primary',
                  ).colors.first.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getDistanceDescription(_selectedDistance),
                  style: LiquidGlassTheme.bodyTextStyle.copyWith(
                    fontSize: 12,
                    color: LiquidGlassTheme.getGradientByName(
                      'primary',
                    ).colors.first,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _distanceOptions.map((distance) {
              final isSelected = _selectedDistance == distance;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDistance = distance;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? LiquidGlassTheme.getGradientByName(
                            'primary',
                          ).colors.first
                        : LiquidGlassTheme.backgroundColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? LiquidGlassTheme.getGradientByName(
                              'primary',
                            ).colors.first
                          : LiquidGlassTheme.getTextColor(
                              'secondary',
                            ).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${distance.toInt()} م',
                    style: LiquidGlassTheme.bodyTextStyle.copyWith(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white
                          : LiquidGlassTheme.getTextColor('primary'),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getDistanceDescription(double distance) {
    if (distance <= 50) {
      return 'قريب جداً';
    } else if (distance <= 100) {
      return 'قريب';
    } else if (distance <= 200) {
      return 'متوسط';
    } else if (distance <= 500) {
      return 'بعيد';
    } else {
      return 'بعيد جداً';
    }
  }

  // تحويل نوع البلاغ من ReportType إلى IncidentType
  IncidentType _convertReportTypeToIncidentType(ReportType reportType) {
    switch (reportType) {
      case ReportType.accident:
        return IncidentType.accident;
      case ReportType.jam:
        return IncidentType.traffic;
      case ReportType.carBreakdown:
        return IncidentType.hazard;
      case ReportType.bump:
        return IncidentType.speedBump;
      case ReportType.closedRoad:
        return IncidentType.roadBlock;
      case ReportType.hazard:
        return IncidentType.hazard;
      case ReportType.police:
        return IncidentType.policeCheckpoint;
      case ReportType.traffic:
        return IncidentType.traffic;
      case ReportType.other:
        return IncidentType.other;
    }
  }

  // عند رفع الصور
  Future<Uint8List> _readImageBytes(XFile xfile) async {
    return xfile.readAsBytes();
  }

  // عند العرض:
  Widget _buildImageWidget(XFile xfile) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: _readImageBytes(xfile),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) => _errorImageWidget(),
            );
          } else if (snapshot.hasError) {
            return _errorImageWidget();
          } else {
            return Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
        },
      );
    } else {
      return Image.file(
        File(xfile.path),
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        errorBuilder: (context, error, stackTrace) => _errorImageWidget(),
      );
    }
  }

  Widget _errorImageWidget() {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 24),
          const SizedBox(height: 4),
          Text(
            'خطأ في الصورة',
            style: TextStyle(color: Colors.red, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // دالة للحصول على اسم نوع الإبلاغ بالعربية
  String _getReportTypeNameArabic(ReportType type) {
    switch (type) {
      case ReportType.accident:
        return 'حادث';
      case ReportType.jam:
        return 'ازدحام';
      case ReportType.carBreakdown:
        return 'عطل سيارة';
      case ReportType.bump:
        return 'مطب';
      case ReportType.closedRoad:
        return 'طريق مغلق';
      case ReportType.hazard:
        return 'خطر';
      case ReportType.police:
        return 'شرطة';
      case ReportType.traffic:
        return 'إشارة مرور';
      case ReportType.other:
        return 'أخرى';
    }
  }
}
