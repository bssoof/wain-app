import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Utility for launching navigation apps
class NavigationLauncher {
  NavigationLauncher._();

  /// Launch Waze navigation to coordinates
  static Future<bool> launchWaze(double lat, double lng) async {
    // Try native app first
    final appUri = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    
    try {
      final launched = await launchUrl(
        appUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    } catch (_) {
      // App not installed, try web
    }

    // Fallback to web
    final webUri = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  /// Launch Google Maps navigation to coordinates
  static Future<bool> launchGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Launch Apple Maps navigation to coordinates (iOS only)
  static Future<bool> launchAppleMaps(double lat, double lng) async {
    final uri = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Show navigation app choice dialog
  static Future<void> showNavDialog({
    required BuildContext context,
    required double lat,
    required double lng,
    required String venueName,
    VoidCallback? onWaze,
    VoidCallback? onGoogleMaps,
    VoidCallback? onAppleMaps,
  }) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                AppLocalizations.of(context)!.navDialogTitle,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                venueName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Waze Button
              _NavButton(
                icon: Icons.navigation,
                label: 'Waze',
                color: const Color(0xFF33CCFF),
                onTap: () {
                  Navigator.pop(ctx);
                  onWaze?.call();
                  launchWaze(lat, lng);
                },
              ),
              const SizedBox(height: 12),

              // Google Maps Button
              _NavButton(
                icon: Icons.map,
                label: 'Google Maps',
                color: const Color(0xFF4285F4),
                onTap: () {
                  Navigator.pop(ctx);
                  onGoogleMaps?.call();
                  launchGoogleMaps(lat, lng);
                },
              ),
              const SizedBox(height: 12),

              // Apple Maps Button (iOS only)
              if (!kIsWeb && Platform.isIOS) ...[
                _NavButton(
                  icon: Icons.apple,
                  label: 'Apple Maps',
                  color: const Color(0xFF000000),
                  onTap: () {
                    Navigator.pop(ctx);
                    onAppleMaps?.call();
                    launchAppleMaps(lat, lng);
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Cancel Button
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.navCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(25),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

