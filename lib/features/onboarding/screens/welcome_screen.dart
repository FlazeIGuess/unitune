import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../core/widgets/optimized_liquid_glass.dart';
import '../widgets/onboarding_slide.dart';
import '../widgets/onboarding_illustrations.dart';

/// Welcome Screen - First onboarding step
///
/// Full-screen slide with clear hierarchy, illustration, and glass container.
/// All text in English.
///
/// Validates: Requirements 12.1, 12.2, 12.3, 12.5, 17.1
class WelcomeScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const WelcomeScreen({super.key, required this.onContinue});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          0,
                          0,
                          0,
                          100, // Extra padding for floating button
                        ),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height - 180,
                          child: OnboardingSlide(
                            title: 'Share music universally',
                            description:
                                'Send songs to friends, regardless of which streaming service they use. UniTune converts links between Spotify, Apple Music, Tidal, and YouTube Music.',
                            illustration: const WelcomeIllustration(),
                            slideIndex: 0,
                            totalSlides: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
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
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onContinue();
        },
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Get Started',
                  style: TextStyle(
                    color: context.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  color: context.primaryColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
