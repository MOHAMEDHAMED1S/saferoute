import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: 'كيف يعمل نظام كشف الطوارئ؟',
      answer:
          'يستخدم التطبيق مستشعرات الهاتف لكشف الحوادث تلقائياً. عند اكتشاف حادث محتمل، يبدأ عد تنازلي لإرسال تنبيه طوارئ. يمكنك إلغاء التنبيه إذا كنت بخير.',
    ),
    FAQItem(
      question: 'كيف أبلغ عن خطر في الطريق؟',
      answer:
          'اضغط على زر الإبلاغ في الشاشة الرئيسية، اختر نوع الخطر، وحدد الموقع. سيتم إرسال البلاغ فوراً لتحذير المستخدمين الآخرين.',
    ),
    FAQItem(
      question: 'هل يستهلك التطبيق البطارية كثيراً؟',
      answer:
          'التطبيق محسن لاستهلاك أقل للبطارية. يمكنك تعديل إعدادات المراقبة في قسم الإعدادات لتوفير المزيد من البطارية.',
    ),
    FAQItem(
      question: 'كيف أغير إعدادات السرعة؟',
      answer:
          'اذهب إلى إعدادات القيادة واختر الملف الشخصي المناسب أو قم بتخصيص حدود السرعة حسب احتياجاتك.',
    ),
    FAQItem(
      question: 'هل بياناتي آمنة؟',
      answer:
          'نعم، جميع بياناتك مشفرة ومحمية. يمكنك مراجعة إعدادات الخصوصية للتحكم في مشاركة البيانات.',
    ),
    FAQItem(
      question: 'كيف أتواصل مع جهات الاتصال في الطوارئ؟',
      answer:
          'يمكنك إضافة جهات اتصال الطوارئ في الإعدادات. سيتم إرسال رسائل تلقائية لهم في حالة اكتشاف طوارئ.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'المساعدة والدعم',
          style: LiquidGlassTheme.headerTextStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: LiquidGlassTheme.getTextColor('primary'),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات التطبيق
            LiquidGlassContainer(
          type: LiquidGlassType.ultraLight,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LiquidGlassTheme.getGradientByName('primary'),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.shield,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SafeRoute',
                    style: LiquidGlassTheme.headerTextStyle.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الإصدار 1.0.0',
                    style: LiquidGlassTheme.bodyTextStyle.copyWith(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'تطبيق السلامة على الطرق الذكي',
                    style: LiquidGlassTheme.bodyTextStyle.copyWith(
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // الأسئلة الشائعة
            LiquidGlassContainer(
              type: LiquidGlassType.ultraLight,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الأسئلة الشائعة',
                    style: LiquidGlassTheme.headerTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._faqItems.map((item) => _buildFAQItem(item)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // التواصل معنا
            LiquidGlassContainer(
            type: LiquidGlassType.ultraLight,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تواصل معنا',
                    style: LiquidGlassTheme.headerTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildContactTile(
                    'البريد الإلكتروني',
                    'support@saferoute.com',
                    Icons.email,
                    () => _launchEmail('support@saferoute.com'),
                  ),
                  _buildContactTile(
                    'الهاتف',
                    '+966 11 123 4567',
                    Icons.phone,
                    () => _launchPhone('+966111234567'),
                  ),
                  _buildContactTile(
                    'الموقع الإلكتروني',
                    'www.saferoute.com',
                    Icons.web,
                    () => _launchWebsite('https://www.saferoute.com'),
                  ),
                  _buildContactTile(
                    'تويتر',
                    '@SafeRouteApp',
                    Icons.alternate_email,
                    () => _launchWebsite('https://twitter.com/SafeRouteApp'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // إرسال ملاحظات
            LiquidGlassContainer(
              type: LiquidGlassType.ultraLight,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إرسال ملاحظات',
                    style: LiquidGlassTheme.headerTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ساعدنا في تحسين التطبيق بإرسال ملاحظاتك واقتراحاتك',
                    style: LiquidGlassTheme.bodyTextStyle.copyWith(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: LiquidGlassButton(
                          text: 'إرسال ملاحظات',
                          onPressed: () => _sendFeedback(),
                          type: LiquidGlassType.primary,
                          borderRadius: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LiquidGlassButton(
                          text: 'تقييم التطبيق',
                          onPressed: () => _rateApp(),
                          type: LiquidGlassType.ultraLight,
                          borderRadius: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // معلومات قانونية
            LiquidGlassContainer(
              type: LiquidGlassType.ultraLight,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'معلومات قانونية',
                    style: LiquidGlassTheme.headerTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLegalTile('شروط الاستخدام', () {}),
                  _buildLegalTile('سياسة الخصوصية', () {}),
                  _buildLegalTile('اتفاقية الترخيص', () {}),
                  _buildLegalTile('إخلاء المسؤولية', () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem item) {
    return ExpansionTile(
      title: Text(
        item.question,
        style: LiquidGlassTheme.headerTextStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            item.answer,
            style: LiquidGlassTheme.bodyTextStyle.copyWith(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
      iconColor: LiquidGlassTheme.getGradientByName('primary').colors.first,
      collapsedIconColor: LiquidGlassTheme.getTextColor('secondary'),
    );
  }

  Widget _buildContactTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: LiquidGlassTheme.getGradientByName(
            'primary',
          ).colors.first.withAlpha(51),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: LiquidGlassTheme.getGradientByName('primary').colors.first,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: LiquidGlassTheme.headerTextStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 14),
      ),
      trailing: Icon(
        Icons.open_in_new,
        color: LiquidGlassTheme.getTextColor('secondary'),
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLegalTile(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: LiquidGlassTheme.headerTextStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: LiquidGlassTheme.getTextColor('secondary'),
      ),
      onTap: onTap,
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=SafeRoute Support',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showErrorSnackBar('لا يمكن فتح تطبيق البريد الإلكتروني');
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showErrorSnackBar('لا يمكن إجراء المكالمة');
    }
  }

  Future<void> _launchWebsite(String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('لا يمكن فتح الرابط');
    }
  }

  void _sendFeedback() {
    _launchEmail('feedback@saferoute.com');
  }

  void _rateApp() {
    // يمكن إضافة رابط متجر التطبيقات هنا
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('شكراً لك! سيتم توجيهك لتقييم التطبيق'),
        backgroundColor: LiquidGlassTheme.getGradientByName(
          'success',
        ).colors.first,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LiquidGlassTheme.getGradientByName(
          'danger',
        ).colors.first,
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
