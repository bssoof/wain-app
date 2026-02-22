import 'package:flutter/material.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wain_app/core/theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.helpTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Contact Section
          Text(
            AppLocalizations.of(context)!.helpContactUs,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildContactTile(
            context,
            icon: Icons.email,
            title: AppLocalizations.of(context)!.helpEmail,
            subtitle: 'support@wain.app',
            onTap: () => _launchEmail(),
          ),
          
          _buildContactTile(
            context,
            icon: Icons.chat,
            title: AppLocalizations.of(context)!.helpWhatsApp,
            subtitle: '+970 59 XXX XXXX',
            onTap: () => _launchWhatsApp(),
          ),
          
          const SizedBox(height: 32),
          
          // FAQ Section
          Text(
            AppLocalizations.of(context)!.helpFaq,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildFaqItem(
            AppLocalizations.of(context)!.helpFaqOffersQ,
            AppLocalizations.of(context)!.helpFaqOffersA,
          ),
          
          _buildFaqItem(
            AppLocalizations.of(context)!.helpFaqMultiUseQ,
            AppLocalizations.of(context)!.helpFaqMultiUseA,
          ),
          
          _buildFaqItem(
            AppLocalizations.of(context)!.helpFaqLocationQ,
            AppLocalizations.of(context)!.helpFaqLocationA,
          ),
          
          _buildFaqItem(
            AppLocalizations.of(context)!.helpFaqAddPlaceQ,
            AppLocalizations.of(context)!.helpFaqAddPlaceA,
          ),
          
          _buildFaqItem(
            AppLocalizations.of(context)!.helpFaqFreeQ,
            AppLocalizations.of(context)!.helpFaqFreeA,
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
      query: 'subject=Inquiry from WAIN app',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  Future<void> _launchWhatsApp() async {
    // Replace with actual WhatsApp number
    final uri = Uri.parse('https://wa.me/970590000000?text=Hello, I have an inquiry');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
