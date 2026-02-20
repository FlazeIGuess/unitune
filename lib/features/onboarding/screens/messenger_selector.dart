import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../core/widgets/liquid_glass_container.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/optimized_liquid_glass.dart';
import '../../../core/constants/services.dart';
import '../../settings/preferences_manager.dart';
import '../widgets/onboarding_progress_bar.dart';
import '../widgets/onboarding_navigation_buttons.dart';

/// Messenger Selection Screen - Step 3 of onboarding (Final)
///
/// Lets users select their preferred messenger app.
/// All text in English.
///
/// Validates: Requirements 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 17.1
class MessengerSelector extends ConsumerStatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const MessengerSelector({
    super.key,
    required this.onContinue,
    required this.onBack,
  });

  @override
  ConsumerState<MessengerSelector> createState() => _MessengerSelectorState();
}

class _MessengerSelectorState extends ConsumerState<MessengerSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  MessengerService? _selectedMessenger;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.animation.durationSlow,
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppTheme.animation.curveDecelerate,
      ),
    );

    _controller.forward();

    // Load current preference if exists
    _selectedMessenger = ref
        .read(preferencesManagerProvider)
        .preferredMessenger;
    _detectInstalledMessenger();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _completeOnboarding() {
    if (_selectedMessenger != null) {
      ref
          .read(preferencesManagerProvider)
          .setPreferredMessenger(_selectedMessenger!)
          .then((_) {
            ref.read(preferredMessengerProvider.notifier).state =
                _selectedMessenger;
            return ref
                .read(preferencesManagerProvider)
                .setOnboardingComplete(true);
          })
          .then((_) {
            ref.read(isOnboardingCompleteProvider.notifier).state = true;
            widget.onContinue();
          });
    }
  }

  Future<void> _detectInstalledMessenger() async {
    if (_selectedMessenger != null) return;
    final order = [
      MessengerService.whatsapp,
      MessengerService.telegram,
      MessengerService.signal,
      MessengerService.sms,
    ];
    for (final messenger in order) {
      final uri = _messengerUri(messenger);
      if (uri == null) continue;
      final canOpen = await canLaunchUrl(uri);
      if (canOpen && mounted) {
        setState(() {
          _selectedMessenger = messenger;
        });
        return;
      }
    }
    if (mounted) {
      setState(() {
        _selectedMessenger = MessengerService.systemShare;
      });
    }
  }

  Uri? _messengerUri(MessengerService messenger) {
    switch (messenger) {
      case MessengerService.whatsapp:
        return Uri.parse('whatsapp://');
      case MessengerService.telegram:
        return Uri.parse('tg://');
      case MessengerService.signal:
        return Uri.parse('sgnl://');
      case MessengerService.sms:
        return Uri.parse('sms:');
      case MessengerService.systemShare:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),
          // Glass layer for all glass elements
          OptimizedLiquidGlassLayer(
            settings: AppTheme.liquidGlassDefault,
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.spacing.xl,
                    AppTheme.spacing.xl,
                    AppTheme.spacing.xl,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress indicator
                      _buildProgressIndicator(),
                      SizedBox(height: AppTheme.spacing.xl),

                      // Title
                      Text(
                        'How do you share music?',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppTheme.colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'ZalandoSansExpanded',
                            ),
                      ),
                      SizedBox(height: AppTheme.spacing.s),

                      // Description
                      Text(
                        'Choose your favorite messenger for quick sharing',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.colors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacing.xl),

                      // Messenger options with scrolling
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Column(
                            children: [
                              for (
                                int i = 0;
                                i < MessengerService.values.length;
                                i++
                              ) ...[
                                _buildMessengerOption(
                                  MessengerService.values[i],
                                ),
                                if (i < MessengerService.values.length - 1)
                                  SizedBox(height: AppTheme.spacing.m),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Floating Navigation Buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: OnboardingNavigationButtons(
                  onBack: widget.onBack,
                  onContinue: _completeOnboarding,
                  continueLabel: 'Start Sharing',
                  isEnabled: _selectedMessenger != null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalSlides = Platform.isAndroid ? 4 : 3;
    final slideIndex = Platform.isAndroid ? 3 : 2; // Messenger is last step

    return OnboardingProgressBar(
      currentStep: slideIndex,
      totalSteps: totalSlides,
    );
  }

  Widget _buildMessengerOption(MessengerService messenger) {
    final isSelected = _selectedMessenger == messenger;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedMessenger = messenger;
        });
      },
      child: LiquidGlassContainer(
        borderRadius: AppTheme.radii.large,
        blurSigma: isSelected ? 20 : 10,
        glassColor: isSelected
            ? AppTheme.colors.glassBase.withValues(alpha: 0.15)
            : AppTheme.colors.glassBase.withValues(alpha: 0.08),
        borderColor: isSelected
            ? AppTheme.colors.glassBorder.withValues(alpha: 0.3)
            : AppTheme.colors.glassBorder.withValues(alpha: 0.15),
        child: Container(
          height: 70,
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.m),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: context.primaryColor, width: 2)
                : null,
            borderRadius: BorderRadius.circular(AppTheme.radii.large),
          ),
          child: Row(
            children: [
              BrandLogo.messenger(service: messenger, size: 40),
              SizedBox(width: AppTheme.spacing.m),
              Expanded(
                child: Text(
                  messenger.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.colors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontFamily: 'ZalandoSansExpanded',
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: context.primaryColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
