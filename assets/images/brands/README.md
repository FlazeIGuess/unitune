# Brand Logos

Dieser Ordner enthält die offiziellen Logos der unterstützten Musik-Streaming-Dienste und Messenger-Apps.

## Ordnerstruktur

```
brands/
├── music/           # Musik-Streaming-Dienste
│   ├── spotify.png
│   ├── apple_music.png
│   ├── tidal.png
│   ├── youtube_music.png
│   ├── deezer.png
│   └── amazon_music.png
│
└── messengers/      # Messenger-Apps
    ├── whatsapp.png
    ├── telegram.png
    ├── signal.png
    ├── sms.png
    └── system_share.png
```

## Logo-Anforderungen

### Format
- **Dateityp**: PNG mit transparentem Hintergrund
- **Größe**: 512x512px (wird automatisch skaliert)
- **Farbmodus**: RGB

### Qualität
- Hochauflösende Logos verwenden (mindestens 512x512px)
- Transparenter Hintergrund für bessere Integration
- Offizielle Brand-Logos von den jeweiligen Websites herunterladen

### Naming Convention
- Kleinbuchstaben
- Unterstriche statt Leerzeichen
- Beispiel: `apple_music.png`, `youtube_music.png`

## Logo-Quellen

### Musik-Streaming-Dienste
- **Spotify**: https://developer.spotify.com/documentation/design
- **Apple Music**: https://developer.apple.com/apple-music/marketing-guidelines/
- **Tidal**: https://tidal.com/press
- **YouTube Music**: https://www.youtube.com/about/brand-resources/
- **Deezer**: https://www.deezer.com/company/press
- **Amazon Music**: https://developer.amazon.com/docs/amazon-music/design-and-brand-guidelines.html

### Messenger-Apps
- **WhatsApp**: https://www.whatsapp.com/brand
- **Telegram**: https://telegram.org/blog/brand
- **Signal**: https://signal.org/brand
- **SMS**: System-Icon verwenden
- **System Share**: System-Icon verwenden

## Integration in die App

Nach dem Hinzufügen der Logos:

1. **pubspec.yaml aktualisieren**:
   ```yaml
   flutter:
     assets:
       - assets/images/brands/music/
       - assets/images/brands/messengers/
   ```

2. **Logo in der App verwenden**:
   ```dart
   Image.asset(
     'assets/images/brands/music/spotify.png',
     width: 48,
     height: 48,
   )
   ```

## Rechtliche Hinweise

- Alle Logos sind Eigentum ihrer jeweiligen Markeninhaber
- Logos nur gemäß den Brand-Guidelines der jeweiligen Unternehmen verwenden
- Keine Modifikation der Logos ohne Genehmigung
- Trademark-Hinweise beachten

## Nächste Schritte

1. Logos von den offiziellen Quellen herunterladen
2. Auf 512x512px skalieren (falls nötig)
3. In die entsprechenden Unterordner kopieren
4. `pubspec.yaml` aktualisieren
5. App neu starten (`flutter run`)
