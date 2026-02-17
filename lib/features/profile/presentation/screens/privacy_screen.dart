import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'سياسة الخصوصية',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'آخر تحديث: فبراير 2026',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 24),
            
            _SectionTitle('1. المعلومات التي نجمعها'),
            _SectionBody(
              '• معلومات الموقع الجغرافي لعرض الأماكن القريبة منك\n'
              '• معرّف الجهاز للتعرف على حسابك\n'
              '• الأماكن المفضلة والعروض المستخدمة\n'
              '• إحصائيات الاستخدام لتحسين التطبيق',
            ),
            
            _SectionTitle('2. كيف نستخدم معلوماتك'),
            _SectionBody(
              '• تقديم توصيات مخصصة للأماكن\n'
              '• عرض العروض المتاحة في منطقتك\n'
              '• تحسين تجربة المستخدم\n'
              '• التواصل معك بخصوص العروض الجديدة',
            ),
            
            _SectionTitle('3. مشاركة المعلومات'),
            _SectionBody(
              'نحن لا نبيع أو نشارك معلوماتك الشخصية مع أطراف ثالثة '
              'إلا في الحالات التالية:\n'
              '• بموافقتك الصريحة\n'
              '• للامتثال للقوانين والأنظمة\n'
              '• لحماية حقوقنا أو ممتلكاتنا',
            ),
            
            _SectionTitle('4. أمان البيانات'),
            _SectionBody(
              'نستخدم تقنيات تشفير متقدمة لحماية بياناتك. '
              'يتم تخزين جميع البيانات على خوادم Firebase المؤمنة.',
            ),
            
            _SectionTitle('5. حقوقك'),
            _SectionBody(
              '• يمكنك طلب حذف بياناتك في أي وقت\n'
              '• يمكنك إيقاف خدمات الموقع من الإعدادات\n'
              '• يمكنك التواصل معنا لأي استفسارات',
            ),
            
            _SectionTitle('6. التواصل معنا'),
            _SectionBody(
              'للاستفسارات حول سياسة الخصوصية:\n'
              'البريد الإلكتروني: privacy@wain.app',
            ),
            
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  const _SectionBody(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        height: 1.6,
      ),
    );
  }
}
