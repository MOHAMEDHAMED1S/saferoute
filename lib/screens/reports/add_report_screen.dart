import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/report_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/common/bottom_navigation_widget.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';

class AddReportScreen extends StatefulWidget {
  static const String routeName = '/add-report';
  const AddReportScreen({Key? key}) : super(key: key);

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  ReportType? _selectedType;
  bool _isSubmitting = false;
  int _currentStep = 0; // 0: نوع البلاغ، 1: التفاصيل، 2: المراجعة

  final List<String> _stepTitles = ['اختر نوع البلاغ', 'أضف التفاصيل', 'راجع البلاغ'];

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
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

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) {
      _showErrorSnackBar('يرجى ملء جميع الحقول المطلوبة');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reportsProvider = Provider.of<ReportsProvider>(context, listen: false);

    if (!authProvider.isLoggedIn) {
      _showErrorSnackBar('يجب تسجيل الدخول أولاً');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await reportsProvider.createReport(
        type: _selectedType!,
        description: _descriptionController.text.trim(),
        createdBy: authProvider.userModel!.id,
        imageUrl: null,
      );

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar(reportsProvider.errorMessage ?? 'خطأ في إرسال البلاغ');
      }
    } catch (e) {
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
        backgroundColor: LiquidGlassTheme.getGradientByName('danger').colors.first,
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
                color: LiquidGlassTheme.getGradientByName('success').colors.first.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 48,
                color: LiquidGlassTheme.getGradientByName('success').colors.first,
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
                Navigator.of(context).pop(); // إغلاق الحوار
                Navigator.of(context).pop(); // العودة للصفحة السابقة
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
                  // شريط العلوي مع زر الرجوع والعنوان
                  Row(
                    children: [
                      LiquidGlassContainer(
                        type: LiquidGlassType.secondary,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.all(8),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: LiquidGlassTheme.getTextColor('primary'),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
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
                                color: LiquidGlassTheme.getTextColor('secondary'),
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
        final isCompleted = index < _currentStep;
        
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isActive 
                      ? LiquidGlassTheme.getGradientByName('primary').colors.first
                      : LiquidGlassTheme.getTextColor('secondary')?.withOpacity(0.3),
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
                    color: LiquidGlassTheme.getGradientByName('info').colors.first.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: LiquidGlassTheme.getGradientByName('info').colors.first,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختر نوع المخطر',
                        style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 16),
                      ),
                      Text(
                        'حدد نوع المخطر الذي تريد الإبلاغ عنه',
                        style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 12),
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
          // عرض النوع المحدد
          LiquidGlassContainer(
            type: LiquidGlassType.secondary,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getReportColor(_selectedType!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getReportIcon(_selectedType!),
                    color: _getReportColor(_selectedType!),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _getReportTypeTitle(_selectedType!),
                  style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 16),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _previousStep,
                  child: Text('تغيير', style: TextStyle(color: LiquidGlassTheme.getGradientByName('primary').colors.first)),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // حقل الوصف
          Text(
            'وصف مفصل للمخطر',
            style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'اكتب وصفاً واضحاً يساعد السائقين الآخرين',
            style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 16),
          
          LiquidGlassContainer(
            type: LiquidGlassType.secondary,
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
          
          // معلومات الموقع
          LiquidGlassContainer(
            type: LiquidGlassType.primary,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: LiquidGlassTheme.getTextColor('primary'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الموقع الحالي',
                        style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 14),
                      ),
                      Text(
                        'سيتم استخدام موقعك الحالي للبلاغ',
                        style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: LiquidGlassTheme.getGradientByName('success').colors.first,
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
          Text(
            'مراجعة البلاغ',
            style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'تأكد من صحة البيانات قبل الإرسال',
            style: LiquidGlassTheme.bodyTextStyle,
          ),
          
          const SizedBox(height: 24),
          
          // معاينة البلاغ
          LiquidGlassContainer(
            type: LiquidGlassType.secondary,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getReportColor(_selectedType!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getReportIcon(_selectedType!),
                        color: _getReportColor(_selectedType!),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getReportTypeTitle(_selectedType!),
                            style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 18),
                          ),
                          Text(
                            'الآن',
                            style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: LiquidGlassTheme.backgroundColor?.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _descriptionController.text.trim(),
                    style: LiquidGlassTheme.bodyTextStyle,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: LiquidGlassTheme.getTextColor('secondary'),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'الموقع الحالي',
                      style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // تحذير مهم
          LiquidGlassContainer(
            type: LiquidGlassType.primary,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: LiquidGlassTheme.getGradientByName('warning').colors.first,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تأكد من صحة البيانات',
                        style: LiquidGlassTheme.headerTextStyle.copyWith(fontSize: 14),
                      ),
                      Text(
                        'البلاغات الخاطئة تؤثر على مصداقية حسابك',
                        style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
        return _formKey.currentState?.validate() == true ? _nextStep : () {
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
      childAspectRatio: 1.2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: ReportType.values.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedType = type;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: LiquidGlassContainer(
              type: isSelected ? LiquidGlassType.primary : LiquidGlassType.secondary,
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? Colors.white.withOpacity(0.1)
                        : _getReportColor(type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getReportIcon(type),
                      size: 24,
                      color: isSelected 
                        ? Colors.white
                        : _getReportColor(type),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getReportTypeTitle(type),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                        ? Colors.white
                        : LiquidGlassTheme.getTextColor('primary'),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        return LiquidGlassTheme.getTextColor('secondary') ?? Colors.grey;
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
}