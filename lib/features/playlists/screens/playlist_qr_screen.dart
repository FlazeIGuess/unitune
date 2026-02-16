import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../core/widgets/optimized_liquid_glass.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/mini_playlist.dart';
import '../../../data/repositories/playlist_repository.dart';
import '../services/playlist_share_service.dart';

class PlaylistQRScreen extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistQRScreen({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistQRScreen> createState() => _PlaylistQRScreenState();
}

class _PlaylistQRScreenState extends ConsumerState<PlaylistQRScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MiniPlaylist?>(
      future: ref.read(playlistRepositoryProvider).getById(widget.playlistId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final playlist = snapshot.data;
        if (playlist == null) {
          return Scaffold(
            body: Center(
              child: Text(
                'Playlist not found',
                style: AppTheme.typography.bodyLarge.copyWith(
                  color: AppTheme.colors.textSecondary,
                ),
              ),
            ),
          );
        }

        return _buildContent(context, playlist);
      },
    );
  }

  Widget _buildContent(BuildContext context, MiniPlaylist playlist) {
    return FutureBuilder<String?>(
      future:
          ref
              .read(playlistShareServiceProvider)
              .resolveShareLink(ref, playlist),
      builder: (context, snapshot) {
        final shareLink = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (shareLink == null) {
          return Scaffold(
            body: Center(
              child: Text(
                'Failed to create share link',
                style: AppTheme.typography.bodyLarge.copyWith(
                  color: AppTheme.colors.textSecondary,
                ),
              ),
            ),
          );
        }
        return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),
          OptimizedLiquidGlassLayer(
            settings: AppTheme.liquidGlassDefault,
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(AppTheme.spacing.l),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Screenshot(
                              controller: _screenshotController,
                              child: _buildQRCard(context, playlist, shareLink),
                            ),
                            SizedBox(height: AppTheme.spacing.xl),
                            _buildActions(context, shareLink),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppTheme.spacing.l),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppTheme.colors.textSecondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(width: AppTheme.spacing.m),
          Text(
            'QR Code',
            style: AppTheme.typography.titleLarge.copyWith(
              color: AppTheme.colors.textPrimary,
              fontFamily: 'ZalandoSansExpanded',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCard(
    BuildContext context,
    MiniPlaylist playlist,
    String shareLink,
  ) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radii.large),
        boxShadow: AppTheme.shadowStrong,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: shareLink,
            version: QrVersions.auto,
            size: 280,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
          SizedBox(height: AppTheme.spacing.l),
          Text(
            playlist.title,
            style: AppTheme.typography.titleMedium.copyWith(
              color: Colors.black,
              fontFamily: 'ZalandoSansExpanded',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spacing.s),
          Text(
            '${playlist.tracks.length} tracks',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: Colors.black54,
            ),
          ),
          SizedBox(height: AppTheme.spacing.m),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_note, size: 16, color: context.primaryColor),
              SizedBox(width: AppTheme.spacing.s),
              Text(
                'UniTune',
                style: AppTheme.typography.bodyMedium.copyWith(
                  color: context.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'ZalandoSansExpanded',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, String shareLink) {
    return Column(
      children: [
        PrimaryButton(
          label: 'Save QR Code',
          onPressed: () => _saveQRCode(context),
          isLoading: _isSaving,
          icon: Icons.download,
        ),
        SizedBox(height: AppTheme.spacing.m),
        PrimaryButton(
          label: 'Share QR Code',
          onPressed: () => _shareQRCode(context),
          icon: Icons.share,
        ),
        SizedBox(height: AppTheme.spacing.m),
        InlineGlassButton(
          label: 'Copy Link',
          onPressed: () => _copyLink(context, shareLink),
          icon: Icons.copy,
        ),
      ],
    );
  }

  Future<void> _saveQRCode(BuildContext context) async {
    setState(() => _isSaving = true);

    try {
      final image = await _screenshotController.capture();
      if (image == null) throw Exception('Failed to capture QR code');

      final directory = await getApplicationDocumentsDirectory();
      final imagePath =
          '${directory.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);

      if (context.mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('QR code saved'),
            backgroundColor: AppTheme.colors.accentSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving QR code: $e'),
            backgroundColor: AppTheme.colors.accentError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareQRCode(BuildContext context) async {
    HapticFeedback.mediumImpact();

    try {
      final image = await _screenshotController.capture();
      if (image == null) throw Exception('Failed to capture QR code');

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/qr_code_temp.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);

      await Share.shareXFiles([
        XFile(imagePath),
      ], text: 'Scan to open playlist');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing QR code: $e'),
            backgroundColor: AppTheme.colors.accentError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyLink(BuildContext context, String link) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Link copied to clipboard'),
        backgroundColor: AppTheme.colors.backgroundCard,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
