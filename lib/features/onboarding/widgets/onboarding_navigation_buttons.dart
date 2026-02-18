import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';

/// Navigation Buttons for Onboarding Screens
///
/// Layout: 20% Back button (icon only) + 80% Continue button
/// Back button is hidden on first screen
class OnboardingNavigationButtons extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onContinue;
  final String continueLabel;
  final bool isEnabled;

  const OnboardingNavigationButtons({
    super.key,
    this.onBack,
    this.onContinue,
    this.continueLabel = 'Continue',
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Back button (20% width, only if onBack is provided)
        if (onBack != null) ...[
          Expanded(flex: 20, child: _buildBackButton(context)),
          SizedBox(width: AppTheme.spacing.m),
        ],

        // Continue button (80% width, or 100% if no back button)
        Expanded(
          flex: onBack != null ? 80 : 100,
          child: _buildContinueButton(context),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
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
          onBack?.call();
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
            child: Icon(
              Icons.arrow_back,
              color: AppTheme.colors.textSecondary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
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
                onContinue?.call();
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
                    continueLabel,
                    style: TextStyle(
                      color: context.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    continueLabel == 'Start Sharing'
                        ? Icons.check
                        : Icons.arrow_forward,
                    color: context.primaryColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
