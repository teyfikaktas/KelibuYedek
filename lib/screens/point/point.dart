import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PointsDisplay extends StatelessWidget {
  final int points;

  const PointsDisplay({Key? key, required this.points}) : super(key: key);

  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}K';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }

  Duration _calculateDuration(int points) {
    const int baseDuration = 500;
    const int maxDuration = 2000;
    final double factor =
        (math.log(points + 1) / math.log(10000)).clamp(0.0, 1.0);
    return Duration(
        milliseconds:
            (baseDuration + factor * (maxDuration - baseDuration)).round());
  }

  @override
  Widget build(BuildContext context) {
    final animationDuration = _calculateDuration(points);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      // Reduced even further
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200, width: 0.5),
        // Reduced even further
        borderRadius: BorderRadius.circular(16.r),
        // Reduced even further
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.3),
            blurRadius: 4, // Reduced even further
            offset: Offset(0, 1), // Reduced even further
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 45.w,
              height: 45.w,
              child: Center(
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 1.0, end: 1.3),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Image.asset(
                    'assets/point.png',
                    width: 72.w,
                    height: 72.w,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            // Reduced significantly to bring logo and text closer
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: points),
              duration: animationDuration,
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, int value, Widget? child) {
                return Text(
                  _formatNumber(value),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Usage
Widget buildPointsDisplay() {
  return PointsDisplay(points: 1234567);
}
