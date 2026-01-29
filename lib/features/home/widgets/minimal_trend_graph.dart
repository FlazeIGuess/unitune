import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';

/// Minimalist interactive trend line graph with scrubbing support
class MinimalTrendGraph extends StatefulWidget {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;
  final Color gradientStartColor;
  final Color gradientEndColor;
  final double height;
  final ValueChanged<int?>? onPointSelected;

  const MinimalTrendGraph({
    super.key,
    required this.data,
    required this.labels,
    this.lineColor = const Color(0xFF58A6FF),
    this.gradientStartColor = const Color(0x4D58A6FF),
    this.gradientEndColor = const Color(0x0058A6FF),
    this.height = 96,
    this.onPointSelected,
  });

  @override
  State<MinimalTrendGraph> createState() => _MinimalTrendGraphState();
}

class _MinimalTrendGraphState extends State<MinimalTrendGraph> {
  int? _selectedIndex;
  bool _isDragging = false;
  bool _isLongPressing = false;
  String? _dataKey;

  @override
  void didUpdateWidget(MinimalTrendGraph oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset state when data changes
    final newKey = widget.data.join(',') + widget.labels.join(',');
    if (_dataKey != newKey) {
      _dataKey = newKey;
      setState(() {
        _selectedIndex = null;
        _isDragging = false;
        _isLongPressing = false;
      });
    }
  }

  void _handleLongPressStart(LongPressStartDetails details, Size size) {
    if (widget.data.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isLongPressing = true;
      _isDragging = true;
      _selectedIndex = _getNearestPointIndex(
        details.localPosition.dx,
        size.width,
      );
    });
    widget.onPointSelected?.call(_selectedIndex);
  }

  void _handleLongPressMoveUpdate(
    LongPressMoveUpdateDetails details,
    Size size,
  ) {
    if (widget.data.isEmpty || !_isLongPressing) return;

    final newIndex = _getNearestPointIndex(
      details.localPosition.dx,
      size.width,
    );
    if (newIndex != _selectedIndex) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedIndex = newIndex;
      });
      widget.onPointSelected?.call(_selectedIndex);
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_isLongPressing) return;

    setState(() {
      _isLongPressing = false;
      _isDragging = false;
    });

    // Auto-clear after 300ms
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_isLongPressing) {
        setState(() {
          _selectedIndex = null;
        });
        widget.onPointSelected?.call(null);
      }
    });
  }

  int _getNearestPointIndex(double dx, double width) {
    if (widget.data.isEmpty) return 0;
    if (widget.data.length == 1) return 0;

    final spacing = width / (widget.data.length - 1);
    final index = (dx / spacing).round().clamp(0, widget.data.length - 1);
    return index;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No data',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textMuted,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, widget.height);

        return GestureDetector(
          onLongPressStart: (details) => _handleLongPressStart(details, size),
          onLongPressMoveUpdate: (details) =>
              _handleLongPressMoveUpdate(details, size),
          onLongPressEnd: _handleLongPressEnd,
          child: CustomPaint(
            size: size,
            painter: _TrendGraphPainter(
              data: widget.data,
              selectedIndex: _selectedIndex,
              lineColor: widget.lineColor,
              gradientStartColor: widget.gradientStartColor,
              gradientEndColor: widget.gradientEndColor,
            ),
          ),
        );
      },
    );
  }
}

class _TrendGraphPainter extends CustomPainter {
  final List<double> data;
  final int? selectedIndex;
  final Color lineColor;
  final Color gradientStartColor;
  final Color gradientEndColor;

  _TrendGraphPainter({
    required this.data,
    this.selectedIndex,
    required this.lineColor,
    required this.gradientStartColor,
    required this.gradientEndColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Normalize data
    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final range = maxValue - minValue;

    // Add padding to top and bottom
    final padding = size.height * 0.1;
    final graphHeight = size.height - (padding * 2);

    // Calculate points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? size.width / 2
          : (i / (data.length - 1)) * size.width;

      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;

      final y = padding + (graphHeight * (1 - normalizedValue));
      points.add(Offset(x, y));
    }

    // Draw gradient fill
    _drawGradientFill(canvas, size, points);

    // Draw line
    _drawLine(canvas, points);

    // Draw selected point indicator
    if (selectedIndex != null && selectedIndex! < points.length) {
      _drawSelectedIndicator(canvas, size, points[selectedIndex!]);
    }
  }

  void _drawGradientFill(Canvas canvas, Size size, List<Offset> points) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.dx, size.height);

    // Create smooth curve through points
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        path.lineTo(points[i].dx, points[i].dy);
      } else {
        final prevPoint = points[i - 1];
        final currentPoint = points[i];

        // Cubic Bezier curve
        final controlPoint1 = Offset(
          prevPoint.dx + (currentPoint.dx - prevPoint.dx) / 3,
          prevPoint.dy,
        );
        final controlPoint2 = Offset(
          prevPoint.dx + 2 * (currentPoint.dx - prevPoint.dx) / 3,
          currentPoint.dy,
        );

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          currentPoint.dx,
          currentPoint.dy,
        );
      }
    }

    path.lineTo(points.last.dx, size.height);
    path.close();

    final gradient = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height), [
      gradientStartColor,
      gradientEndColor,
    ]);

    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  void _drawLine(Canvas canvas, List<Offset> points) {
    if (points.length < 2) {
      // Single point - draw a small circle
      final paint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points.first, 3, paint);
      return;
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    // Create smooth curve through points
    for (int i = 1; i < points.length; i++) {
      final prevPoint = points[i - 1];
      final currentPoint = points[i];

      // Cubic Bezier curve
      final controlPoint1 = Offset(
        prevPoint.dx + (currentPoint.dx - prevPoint.dx) / 3,
        prevPoint.dy,
      );
      final controlPoint2 = Offset(
        prevPoint.dx + 2 * (currentPoint.dx - prevPoint.dx) / 3,
        currentPoint.dy,
      );

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        currentPoint.dx,
        currentPoint.dy,
      );
    }

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  void _drawSelectedIndicator(Canvas canvas, Size size, Offset point) {
    // Vertical line
    final linePaint = Paint()
      ..color = lineColor.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(point.dx, 0),
      Offset(point.dx, size.height),
      linePaint,
    );

    // Concentric circles
    final circles = [
      (radius: 14.0, opacity: 0.15),
      (radius: 10.0, opacity: 0.25),
      (radius: 6.0, opacity: 0.4),
    ];

    for (final circle in circles) {
      final paint = Paint()
        ..color = lineColor.withOpacity(circle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(point, circle.radius, paint);
    }

    // Center dot
    final centerPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(point, 3, centerPaint);
  }

  @override
  bool shouldRepaint(_TrendGraphPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.lineColor != lineColor;
  }
}
