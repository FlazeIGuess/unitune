import 'package:flutter/material.dart';
import 'responsive.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_container.dart';

/// Example screen demonstrating responsive utilities
///
/// This file shows how to use ResponsiveUtils to create layouts
/// that adapt to different screen sizes (320px - 428px)
class ResponsiveExample extends StatelessWidget {
  const ResponsiveExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Get scaled spacing and typography
    final spacing = ResponsiveUtils.spacing(context);
    final typography = ResponsiveUtils.typography(context);

    return Scaffold(
      backgroundColor: AppTheme.colors.backgroundDeep,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.screenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: spacing.l),

              // Example 1: Responsive Text
              Text(
                'Responsive Typography',
                style: typography.displayMedium.copyWith(
                  color: AppTheme.colors.textPrimary,
                ),
              ),
              SizedBox(height: spacing.s),
              Text(
                'This text scales proportionally based on screen width',
                style: typography.bodyMedium.copyWith(
                  color: AppTheme.colors.textSecondary,
                ),
              ),

              SizedBox(height: spacing.xl),

              // Example 2: Responsive Container
              ResponsiveContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Responsive Container',
                      style: typography.titleMedium.copyWith(
                        color: AppTheme.colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: spacing.s),
                    Text(
                      'Padding adapts from 16px (320px width) to 24px (428px width)',
                      style: typography.bodyMedium.copyWith(
                        color: AppTheme.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: spacing.xl),

              // Example 3: Responsive Album Art
              Center(
                child: Container(
                  width: ResponsiveUtils.albumArtSize(context),
                  height: ResponsiveUtils.albumArtSize(context),
                  decoration: BoxDecoration(
                    color: AppTheme.colors.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radii.large),
                  ),
                  child: Center(
                    child: Text(
                      'Album Art\n${ResponsiveUtils.albumArtSize(context).toStringAsFixed(0)}px',
                      textAlign: TextAlign.center,
                      style: typography.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: spacing.xl),

              // Example 4: Screen Info
              ResponsiveContainer(
                backgroundColor: AppTheme.colors.backgroundMedium,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Screen Information',
                      style: typography.titleMedium.copyWith(
                        color: AppTheme.colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: spacing.m),
                    _buildInfoRow(
                      context,
                      'Width',
                      '${ResponsiveUtils.screenWidth(context).toStringAsFixed(0)}px',
                      typography,
                    ),
                    SizedBox(height: spacing.s),
                    _buildInfoRow(
                      context,
                      'Scale Factor',
                      ResponsiveUtils.scaleFactor(context).toStringAsFixed(2),
                      typography,
                    ),
                    SizedBox(height: spacing.s),
                    _buildInfoRow(
                      context,
                      'Is Min Width',
                      ResponsiveUtils.isMinWidth(context).toString(),
                      typography,
                    ),
                    SizedBox(height: spacing.s),
                    _buildInfoRow(
                      context,
                      'Is Max Width',
                      ResponsiveUtils.isMaxWidth(context).toString(),
                      typography,
                    ),
                  ],
                ),
              ),

              SizedBox(height: spacing.xl),

              // Example 5: Responsive Spacing
              ResponsiveContainer(
                backgroundColor: AppTheme.colors.backgroundMedium,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scaled Spacing Values',
                      style: typography.titleMedium.copyWith(
                        color: AppTheme.colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: spacing.m),
                    _buildInfoRow(
                      context,
                      'XS',
                      '${spacing.xs.toStringAsFixed(1)}px',
                      typography,
                    ),
                    SizedBox(height: spacing.s),
                    _buildInfoRow(
                      context,
                      'S',
                      '${spacing.s.toStringAsFixed(1)}px',
                      typography,
                    ),
                    SizedBox(height: spacing.s),
                    _buildInfoRow(
                      context,
                      'M',
                      '${spacing.m.toStringAsFixed(1)}px',
                      typography,
                    ),
                    SizedBox(height: spacing.s),
                    _buildInfoRow(
                      context,
                      'L',
                      '${spacing.l.toStringAsFixed(1)}px',
                      typography,
                    ),
                    SizedBox(height: spacing.s),
                    _buildInfoRow(
                      context,
                      'XL',
                      '${spacing.xl.toStringAsFixed(1)}px',
                      typography,
                    ),
                    SizedBox(height: spacing.s),
                    _buildInfoRow(
                      context,
                      'XXL',
                      '${spacing.xxl.toStringAsFixed(1)}px',
                      typography,
                    ),
                  ],
                ),
              ),

              SizedBox(height: spacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    ScaledTypography typography,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: typography.bodyMedium.copyWith(
            color: AppTheme.colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: typography.bodyMedium.copyWith(
            color: AppTheme.colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
