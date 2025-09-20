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

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  
  ReportType? _selectedType;
  // File? _selectedImage; // TODO: Add image_picker dependency
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // TODO: Implement image picker when image_picker dependency is added
    _showErrorSnackBar('ميزة إضافة الصور غير متوفرة حالياً');
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
      // TODO: Upload image if selected
      String? imageUrl;

      final success = await reportsProvider.createReport(
        type: _selectedType!,
        description: _descriptionController.text.trim(),
        createdBy: authProvider.userModel!.id,
        imageUrl: imageUrl,
      );

      if (success) {
        _showSuccessSnackBar('تم إرسال البلاغ بنجاح');
        Navigator.of(context).pop();
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
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'إضافة بلاغ جديد',
          style: LiquidGlassTheme.primaryTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: LiquidGlassTheme.primaryTextStyle.color),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Report Type Selection
              Text(
                'نوع البلاغ',
                style: LiquidGlassTheme.primaryTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildReportTypeGrid(),
              
              const SizedBox(height: 32),
              
              // Description Field
              Text(
                'وصف البلاغ',
                style: LiquidGlassTheme.primaryTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'وصف البلاغ',
                hintText: 'اكتب وصفاً مفصلاً للبلاغ...',
                maxLines: 4,
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
              
              const SizedBox(height: 32),
              
              // Image Section
              Text(
                'إضافة صورة (اختياري)',
                style: LiquidGlassTheme.primaryTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildImageSection(),
              
              const SizedBox(height: 32),
              
              // Location Info
              LiquidGlassContainer(
                type: LiquidGlassType.secondary,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: LiquidGlassTheme.adaptiveTextColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الموقع الحالي',
                            style: LiquidGlassTheme.primaryTextStyle.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'سيتم استخدام موقعك الحالي للبلاغ',
                            style: LiquidGlassTheme.secondaryTextStyle.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Submit Button
              LiquidGlassButton(
                text: _isSubmitting ? 'جاري الإرسال...' : 'إرسال البلاغ',
                onPressed: _isSubmitting ? null : _submitReport,
                type: LiquidGlassType.primary,
                borderRadius: 12,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: 2, // Add report tab index
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacementNamed('/dashboard');
              break;
            case 1:
              Navigator.of(context).pushReplacementNamed('/home');
              break;
            case 2:
              // Already on add report screen
              break;
            case 3:
              // Navigate to community screen
              break;
            case 4:
              Navigator.of(context).pushReplacementNamed('/profile');
              break;
          }
        },
      ),
    );
  }

  Widget _buildReportTypeGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: ReportType.values.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedType = type;
            });
          },
          child: LiquidGlassContainer(
            type: isSelected ? LiquidGlassType.primary : LiquidGlassType.secondary,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getReportIcon(type),
                  size: 24,
                  color: isSelected ? Colors.white : _getReportColor(type),
                ),
                const SizedBox(height: 8),
                Text(
                  _getReportTypeTitle(type),
                  style: isSelected 
                    ? LiquidGlassTheme.primaryTextStyle.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      )
                    : LiquidGlassTheme.primaryTextStyle.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: LiquidGlassContainer(
        type: LiquidGlassType.secondary,
        borderRadius: BorderRadius.circular(12),
        height: 120,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 32,
              color: LiquidGlassTheme.secondaryTextStyle.color,
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط لإضافة صورة',
              style: LiquidGlassTheme.secondaryTextStyle.copyWith(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
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
        return Colors.red;
      case ReportType.jam:
        return Colors.orange;
      case ReportType.carBreakdown:
        return Colors.blue;
      case ReportType.bump:
        return Colors.amber;
      case ReportType.closedRoad:
        return Colors.purple;
      default:
        return Colors.grey;
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