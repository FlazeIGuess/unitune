import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../core/widgets/liquid_glass_container.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/constants/services.dart';
import '../../settings/preferences_manager.dart';

/// Messenger Selection Screen - Step 3 of onboarding (Final)
///
/// Lets users select their preferred messenger app.
/// All text in English.
///
/// Validates: Requirements 12.1, 12.2, 12.3, 12.4, 12.5, 12.6, 17.1
class MessengerSelector extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const MessengerSelector({super.key, required this.onContinue});

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
          LiquidGlassLayer(
            settings: AppTheme.liquidGlassDefault,
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.spacing.xl,
                    AppTheme.spacing.xl,
                    AppTheme.spacing.xl,
                    120, // Extra padding for floating button
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress indicator
                      _buildProgressIndicator(),
                      SizedBox(height: AppTheme.spacing.xl),
                      Text(
                        'Choose your messenger',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppTheme.colors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      SizedBox(height: AppTheme.spacing.s),
                      Text(
                        'Select your preferred messaging app for sharing songs. You can change this later in settings.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.colors.textSecondary,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacing.xl),
                      // Messenger options
                      _buildMessengerOption(MessengerService.whatsapp),
                      SizedBox(height: AppTheme.spacing.m),
                      _buildMessengerOption(MessengerService.telegram),
                      SizedBox(height: AppTheme.spacing.m),
                      _buildMessengerOption(MessengerService.signal),
                      SizedBox(height: AppTheme.spacing.m),
                      _buildMessengerOption(MessengerService.sms),
                      SizedBox(height: AppTheme.spacing.m),
                      _buildMessengerOption(MessengerService.systemShare),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Floating CTA Button - Bottom Nav style
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _buildFloatingButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton() {
    final isEnabled = _selectedMessenger != null;

    return LiquidGlass.withOwnLayer(
      settings: const LiquidGlassSettings(
        blur: 12,
        ambientStrength: 0.5,
        glassColor: Color(0x18FFFFFF),
        thickness: 12,
        lightIntensity: 0.5,
        saturation: 1.3,
        refractiveIndex: 1.15,
      ),
      shape: LiquidRoundedSuperellipse(borderRadius: 32),
      child: GestureDetector(
        onTap: isEnabled
            ? () {
                HapticFeedback.lightImpact();
                _completeOnboarding();
              }
            : null,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Opacity(
              opacity: isEnabled ? 1.0 : 0.5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Start Sharing',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.check, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    const totalSlides = 3;
    const slideIndex = 2; // Messenger is step 3 (index 2)

    return Row(
      children: List.generate(totalSlides, (index) {
        final isActive = index == slideIndex;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(
              right: index < totalSlides - 1 ? AppTheme.spacing.xs : 0,
            ),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        context.primaryColor,
                        context.primaryColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              color: isActive ? null : AppTheme.colors.backgroundCard,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
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
          padding: EdgeInsets.all(AppTheme.spacing.m),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: context.primaryColor, width: 2)
                : null,
            borderRadius: BorderRadius.circular(AppTheme.radii.large),
          ),
          child: Row(
            children: [
              BrandLogo.messenger(service: messenger, size: 48),
              SizedBox(width: AppTheme.spacing.m),
              Expanded(
                child: Text(
                  messenger.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.colors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
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
