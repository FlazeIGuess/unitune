import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../../../core/widgets/liquid_glass_container.dart';

/// Onboarding Slide Component
///
/// Full-screen slide with clear visual hierarchy, glass containers,
/// and illustrations demonstrating key features.
///
/// Validates: Requirements 12.1, 12.2, 12.3, 12.5
class OnboardingSlide extends StatelessWidget {
  final String title;
  final String description;
  final Widget illustration;
  final int slideIndex;
  final int totalSlides;

  const OnboardingSlide({
    super.key,
    required this.title,
    required this.description,
    required this.illustration,
    required this.slideIndex,
    required this.totalSlides,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            SizedBox(height: AppTheme.spacing.xxl),

            // Illustration area
            Expanded(flex: 3, child: Center(child: illustration)),

            SizedBox(height: AppTheme.spacing.xxl),

            // Content area with glass container
            LiquidGlassContainer(
              borderRadius: AppTheme.radii.xLarge,
              padding: EdgeInsets.all(AppTheme.spacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.colors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing.m),

                  // Description
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.colors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppTheme.spacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Builder(
      builder: (context) {
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
      },
    );
  }
}
