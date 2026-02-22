import 'package:flutter/material.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.privacyTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.privacyLastUpdate,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            _SectionTitle(l10n.privacySection1Title),
            _SectionBody(l10n.privacySection1Body),
            
            _SectionTitle(l10n.privacySection2Title),
            _SectionBody(l10n.privacySection2Body),
            
            _SectionTitle(l10n.privacySection3Title),
            _SectionBody(l10n.privacySection3Body),
            
            _SectionTitle(l10n.privacySection4Title),
            _SectionBody(l10n.privacySection4Body),
            
            _SectionTitle(l10n.privacySection5Title),
            _SectionBody(l10n.privacySection5Body),
            
            _SectionTitle(l10n.privacySection6Title),
            _SectionBody(l10n.privacySection6Body),
            
            const SizedBox(height: 40),
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
