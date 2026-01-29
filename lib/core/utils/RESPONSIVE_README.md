# Responsive Utilities

This document describes the responsive layout system for UniTune, which adapts layouts to different screen sizes in the mobile range (320px - 428px).

## Overview

The `ResponsiveUtils` class provides MediaQuery-based utilities for:
- Screen width detection
- Proportional spacing scaling
- Proportional typography scaling
- Responsive container padding
- Responsive section margins
- Responsive album art sizing

## Screen Width Range

- **Minimum**: 320px (iPhone SE, small Android phones)
- **Base**: 390px (iPhone 12/13/14 Pro - reference device)
- **Maximum**: 428px (iPhone 14 Pro Max, large Android phones)

## Scale Factor

The scale factor is calculated as: `screenWidth / baseScreenWidth (390px)`

- At 320px: scale = 0.82 (82% of base)
- At 390px: scale = 1.00 (100% - base)
- At 428px: scale = 1.10 (110% of base)

## Usage Examples

### 1. Basic Screen Width Detection

```dart
import 'package:unitune/core/utils/responsive.dart';

Widget build(BuildContext context) {
  final width = ResponsiveUtils.screenWidth(context);
  final isSmallScreen = ResponsiveUtils.isMinWidth(context);
  final isLargeScreen = ResponsiveUtils.isMaxWidth(context);
  
  return Text('Screen width: $width px');
}
```

### 2. Scaled Spacing

```dart
Widget build(BuildContext context) {
  final spacing = ResponsiveUtils.spacing(context);
  
  return Column(
    children: [
      SizedBox(height: spacing.l), // Scales from ~19.7px to ~26.4px
      Container(
        padding: EdgeInsets.all(spacing.m), // Scales from ~13.1px to ~17.6px
        child: Text('Content'),
      ),
    ],
  );
}
```

### 3. Scaled Typography

```dart
Widget build(BuildContext context) {
  final typography = ResponsiveUtils.typography(context);
  
  return Column(
    children: [
      Text(
        'Title',
        style: typography.displayLarge, // Scales from ~32.8px to ~44px
      ),
      Text(
        'Body text',
        style: typography.bodyMedium, // Scales from ~11.5px to ~15.4px
      ),
    ],
  );
}
```

### 4. Responsive Container Padding

```dart
Widget build(BuildContext context) {
  return Container(
    padding: ResponsiveUtils.containerPadding(context),
    // Padding scales from 16px (320px width) to 24px (428px width)
    child: Text('Content'),
  );
}
```

### 5. Responsive Section Margins

```dart
Widget build(BuildContext context) {
  final margin = ResponsiveUtils.sectionMargin(context);
  // Margin scales from 16px (320px width) to 32px (428px width)
  
  return Column(
    children: [
      Section1(),
      SizedBox(height: margin),
      Section2(),
    ],
  );
}
```

### 6. Responsive Album Art

```dart
Widget build(BuildContext context) {
  final size = ResponsiveUtils.albumArtSize(context);
  // Size scales from 200px (320px width) to 280px (428px width)
  
  return Container(
    width: size,
    height: size,
    child: Image.network(albumArtUrl),
  );
}
```

### 7. Screen Padding

```dart
Widget build(BuildContext context) {
  return Padding(
    padding: ResponsiveUtils.screenPadding(context),
    // Horizontal padding based on scaled spacing.m
    child: Column(
      children: [
        // Content
      ],
    ),
  );
}
```

## Helper Widgets

### ResponsiveContainer

A container that automatically applies responsive padding:

```dart
ResponsiveContainer(
  child: Text('Content with responsive padding'),
)
```

### ResponsiveText

A text widget that automatically scales font size:

```dart
ResponsiveText(
  'Hello World',
  baseStyle: AppTheme.typography.titleLarge,
)
```

### ResponsiveSizedBox

A sized box that automatically scales dimensions:

```dart
ResponsiveSizedBox(
  width: 100,
  height: 50,
  child: Text('Scaled box'),
)
```

## Scaling Behavior

### Spacing Values

| Value | 320px | 390px | 428px |
|-------|-------|-------|-------|
| xs (8px) | 6.6px | 8.0px | 8.8px |
| s (12px) | 9.8px | 12.0px | 13.2px |
| m (16px) | 13.1px | 16.0px | 17.6px |
| l (24px) | 19.7px | 24.0px | 26.4px |
| xl (32px) | 26.2px | 32.0px | 35.2px |
| xxl (48px) | 39.4px | 48.0px | 52.7px |

### Typography Values

| Style | 320px | 390px | 428px |
|-------|-------|-------|-------|
| displayLarge (40px) | 32.8px | 40.0px | 44.0px |
| displayMedium (32px) | 26.2px | 32.0px | 35.2px |
| titleLarge (24px) | 19.7px | 24.0px | 26.4px |
| titleMedium (20px) | 16.4px | 20.0px | 22.0px |
| bodyLarge (16px) | 13.1px | 16.0px | 17.6px |
| bodyMedium (14px) | 11.5px | 14.0px | 15.4px |
| labelLarge (14px) | 11.5px | 14.0px | 15.4px |
| labelMedium (12px) | 9.8px | 12.0px | 13.2px |

### Container Padding

- At 320px: 16px
- At 390px: ~21.2px
- At 428px: 24px

### Section Margin

- At 320px: 16px
- At 390px: ~26.4px
- At 428px: 32px

### Album Art Size

- At 320px: 200px
- At 390px: ~251.9px
- At 428px: 280px

## Testing

All responsive utilities are thoroughly tested at minimum (320px), base (390px), and maximum (428px) widths. See `test/core/utils/responsive_test.dart` for comprehensive test coverage.

## Requirements Validation

This implementation validates the following requirements:

- **15.1**: Responsive layout adapts to screen widths from 320px to 428px
- **15.2**: Typography scales proportionally for different screen sizes
- **15.3**: Spacing and padding adjust for optimal use of screen real estate
- **5.6**: Spacing adapts proportionally for different screen sizes

## Best Practices

1. **Always use ResponsiveUtils for spacing**: Instead of hardcoded values, use `ResponsiveUtils.spacing(context)` to ensure consistent scaling.

2. **Use scaled typography**: Apply `ResponsiveUtils.typography(context)` for text that should scale with screen size.

3. **Test at extremes**: Always test layouts at both 320px and 428px to ensure no overflow or clipping occurs.

4. **Use helper widgets**: Leverage `ResponsiveContainer`, `ResponsiveText`, and `ResponsiveSizedBox` for common responsive patterns.

5. **Maintain touch targets**: Even with scaling, ensure interactive elements maintain minimum 44x44px touch targets.

## Example Screen

See `lib/core/utils/responsive_example.dart` for a complete example screen demonstrating all responsive utilities in action.
