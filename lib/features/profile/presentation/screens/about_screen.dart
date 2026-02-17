import 'package:flutter/material.dart';
import 'package:wain_app/core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عن وين'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.place,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App Name
            const Text(
              'وين',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'الإصدار 1.0.0',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Text(
                'وين هو تطبيق ذكي لاكتشاف أفضل الأماكن في فلسطين. '
                'نساعدك على إيجاد المطاعم والكافيهات المناسبة لمزاجك ومناسبتك.\n\n'
                'سواء كنت تبحث عن مكان رومانسي، أو تجمع عائلي، أو مكان للعمل - '
                'وين سيساعدك على اتخاذ القرار الصحيح!',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Features
            _buildFeature(Icons.location_on, 'اكتشف الأماكن القريبة'),
            _buildFeature(Icons.local_offer, 'عروض حصرية للمستخدمين'),
            _buildFeature(Icons.favorite, 'احفظ أماكنك المفضلة'),
            _buildFeature(Icons.navigation, 'توجيه مباشر للمكان'),
            
            const SizedBox(height: 40),
            
            Text(
              '© 2026 WAIN App',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
