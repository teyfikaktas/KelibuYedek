import 'dart:math' as math;

import 'package:flutter/material.dart';

class HexagonWidget extends StatelessWidget {
  final Widget child;
  final double size;
  final Color backgroundColor;

  const HexagonWidget({
    Key? key,
    required this.child,
    this.size = 60.0,
    this.backgroundColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HexagonPainter(backgroundColor),
        child: Center(child: child),
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Color backgroundColor;

  _HexagonPainter(this.backgroundColor);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    var path = Path();
    double width = size.width;
    double height = size.height;
    double r = width / 2;
    double sqrt3 = math.sqrt(3);
    double hexHeight = sqrt3 * r / 2;

    path.moveTo(width / 2, 0);
    path.lineTo(width, hexHeight);
    path.lineTo(width, hexHeight + (height / 2));
    path.lineTo(width / 2, height);
    path.lineTo(0, hexHeight + (height / 2));
    path.lineTo(0, hexHeight);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
