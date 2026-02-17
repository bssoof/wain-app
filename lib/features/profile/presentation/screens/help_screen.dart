import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wain_app/core/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المساعدة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Contact Section
          const Text(
            'تواصل معنا',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildContactTile(
            context,
            icon: Icons.email,
            title: 'البريد الإلكتروني',
            subtitle: 'support@wain.app',
            onTap: () => _launchEmail(),
          ),
          
          _buildContactTile(
            context,
            icon: Icons.chat,
            title: 'واتساب',
            subtitle: '+970 59 XXX XXXX',
            onTap: () => _launchWhatsApp(),
          ),
          
          const SizedBox(height: 32),
          
          // FAQ Section
          const Text(
            'الأسئلة الشائعة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildFaqItem(
            'كيف أستخدم العروض؟',
            'اضغط على أي عرض متاح، ثم اضغط "احصل على العرض". '
            'سيظهر لك رمز QR يمكنك إظهاره للتاجر خلال 10 دقائق.',
          ),
          
          _buildFaqItem(
            'هل يمكنني استخدام العرض أكثر من مرة؟',
            'كل عرض له حد استخدام معين. بعض العروض يمكن استخدامها مرة واحدة فقط، '
            'بينما البعض الآخر يمكن استخدامه عدة مرات.',
          ),
          
          _buildFaqItem(
            'لماذا لا يظهر موقعي؟',
            'تأكد من السماح للتطبيق بالوصول للموقع من إعدادات الهاتف. '
            'اذهب إلى الإعدادات > التطبيقات > وين > الأذونات > الموقع.',
          ),
          
          _buildFaqItem(
            'كيف أضيف مكاني للتطبيق؟',
            'إذا كنت صاحب مطعم أو كافيه وترغب في الانضمام، '
            'تواصل معنا عبر البريد الإلكتروني وسنقوم بإضافة مكانك.',
          ),
          
          _buildFaqItem(
            'هل التطبيق مجاني؟',
            'نعم! التطبيق مجاني تماماً للمستخدمين. '
            'نحن نعمل مع الشركاء لتوفير أفضل العروض لكم.',
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildContactTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
  
  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@wain.app',
      query: 'subject=استفسار من تطبيق وين',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  Future<void> _launchWhatsApp() async {
    // Replace with actual WhatsApp number
    final uri = Uri.parse('https://wa.me/970590000000?text=مرحباً، لدي استفسار');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
