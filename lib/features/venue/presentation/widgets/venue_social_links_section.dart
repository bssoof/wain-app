import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';

class VenueSocialLinksSection extends StatelessWidget {
  final Venue venue;

  const VenueSocialLinksSection({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.link, color: Colors.purple.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'روابط التواصل',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (venue.instagram.isNotEmpty)
              _socialChip(
                Icons.camera_alt,
                'Instagram',
                'https://instagram.com/${venue.instagram}',
              ),
            if (venue.facebook.isNotEmpty)
              _socialChip(Icons.facebook, 'Facebook', venue.facebook),
            if (venue.website.isNotEmpty)
              _socialChip(Icons.language, 'Website', venue.website),
            if (venue.whatsapp.isNotEmpty)
              _socialChip(
                Icons.chat,
                'WhatsApp',
                'https://wa.me/${venue.whatsappNumber}',
              ),
          ],
        ),
      ],
    );
  }

  Widget _socialChip(IconData icon, String label, String url) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
