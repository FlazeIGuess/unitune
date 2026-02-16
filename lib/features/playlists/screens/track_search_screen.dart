import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/optimized_liquid_glass.dart';
import '../../../core/widgets/glass_input_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/security/url_validator.dart';
import '../../../data/models/playlist_track.dart';
import '../../../data/repositories/unitune_repository.dart';

class TrackSearchScreen extends ConsumerStatefulWidget {
  const TrackSearchScreen({super.key});

  @override
  ConsumerState<TrackSearchScreen> createState() => _TrackSearchScreenState();
}

class _TrackSearchScreenState extends ConsumerState<TrackSearchScreen> {
  final TextEditingController _urlController = TextEditingController();
  final UnituneRepository _repo = UnituneRepository();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    _repo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacing.l),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paste a music link',
                            style: AppTheme.typography.titleMedium.copyWith(
                              color: AppTheme.colors.textPrimary,
                              fontFamily: 'ZalandoSansExpanded',
                            ),
                          ),
                          SizedBox(height: AppTheme.spacing.s),
                          Text(
                            'Spotify, Apple Music, Tidal, YouTube Music, Deezer, or Amazon Music',
                            style: AppTheme.typography.bodyMedium.copyWith(
                              color: AppTheme.colors.textSecondary,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacing.l),
                          GlassInputField(
                            controller: _urlController,
                            placeholder: 'https://open.spotify.com/track/...',
                            keyboardType: TextInputType.url,
                          ),
                          if (_error != null) ...[
                            SizedBox(height: AppTheme.spacing.m),
                            Container(
                              padding: EdgeInsets.all(AppTheme.spacing.m),
                              decoration: BoxDecoration(
                                color: AppTheme.colors.accentError.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radii.medium,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: AppTheme.colors.accentError,
                                    size: 20,
                                  ),
                                  SizedBox(width: AppTheme.spacing.s),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: AppTheme.typography.bodyMedium
                                          .copyWith(
                                            color: AppTheme.colors.accentError,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          PrimaryButton(
                            label: 'Add Track',
                            onPressed: _addTrack,
                            isLoading: _isLoading,
                            icon: Icons.add,
                          ),
                        ],
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
            'Add Track',
            style: AppTheme.typography.titleLarge.copyWith(
              color: AppTheme.colors.textPrimary,
              fontFamily: 'ZalandoSansExpanded',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTrack() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    debugPrint('TrackSearch.addTrack url=$url');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final validation = UrlValidator.validateAndSanitize(url);
      if (!validation.isValid) {
        debugPrint('TrackSearch.addTrack invalidUrl error=${validation.errorMessage}');
        setState(() {
          _error = validation.errorMessage ?? 'Invalid URL';
          _isLoading = false;
        });
        return;
      }

      final response = await _repo.getLinks(validation.sanitizedUrl);

      if (response == null) {
        debugPrint('TrackSearch.addTrack apiFailed url=${validation.sanitizedUrl}');
        setState(() {
          _error = 'Could not fetch track information';
          _isLoading = false;
        });
        return;
      }

      final convertedLinks = <String, String>{};
      response.linksByPlatform.forEach((key, value) {
        convertedLinks[key] = value.url;
      });

      final track = PlaylistTrack(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: response.title ?? 'Unknown Track',
        artist: response.artistName ?? 'Unknown Artist',
        originalUrl: validation.sanitizedUrl,
        thumbnailUrl: response.thumbnailUrl,
        convertedLinks: convertedLinks,
        addedAt: DateTime.now(),
      );

      if (mounted) {
        debugPrint('TrackSearch.addTrack success id=${track.id}');
        Navigator.of(context).pop(track);
      }
    } catch (e) {
      debugPrint('TrackSearch.addTrack error $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }
}
