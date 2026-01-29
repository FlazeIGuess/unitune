import 'package:flutter/material.dart';
import '../../core/constants/services.dart';

/// BrandLogo - Widget zum Anzeigen von Brand-Logos
///
/// Zeigt das offizielle Logo eines Musik-Dienstes oder Messengers an.
/// Falls kein Logo verfügbar ist, wird ein Fallback-Icon angezeigt.
///
/// Usage:
/// ```dart
/// BrandLogo.music(
///   service: MusicService.spotify,
///   size: 48,
/// )
///
/// BrandLogo.messenger(
///   service: MessengerService.whatsapp,
///   size: 48,
/// )
/// ```
class BrandLogo extends StatelessWidget {
  final String assetPath;
  final String fallbackIcon;
  final Color fallbackColor;
  final double size;

  const BrandLogo({
    super.key,
    required this.assetPath,
    required this.fallbackIcon,
    required this.fallbackColor,
    this.size = 48,
  });

  /// Erstellt ein Logo für einen Musik-Streaming-Dienst
  factory BrandLogo.music({required MusicService service, double size = 48}) {
    return BrandLogo(
      assetPath: 'assets/images/brands/music/${_getFileName(service.name)}.png',
      fallbackIcon: service.icon,
      fallbackColor: Color(service.color),
      size: size,
    );
  }

  /// Erstellt ein Logo für einen Messenger
  factory BrandLogo.messenger({
    required MessengerService service,
    double size = 48,
  }) {
    return BrandLogo(
      assetPath:
          'assets/images/brands/messengers/${_getFileName(service.name)}.png',
      fallbackIcon: service.icon,
      fallbackColor: Color(service.color),
      size: size,
    );
  }

  /// Konvertiert Service-Namen in Dateinamen
  /// Beispiel: "Apple Music" -> "apple_music"
  static String _getFileName(String serviceName) {
    return serviceName.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback: Zeige Emoji-Icon wenn Logo nicht gefunden
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: fallbackColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(size * 0.2),
              ),
              child: Center(
                child: Text(
                  fallbackIcon,
                  style: TextStyle(fontSize: size * 0.5),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
