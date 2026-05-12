import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api.dart';

class StreakWidget extends StatefulWidget {
  final int streakCount;
  final int? dailyRank;
  final int? weeklyRank;
  final int? monthlyRank;
  final int? allTimeRank;
  final bool isDarkMode;

  const StreakWidget({
    Key? key,
    required this.streakCount,
    this.dailyRank,
    this.weeklyRank,
    this.monthlyRank,
    this.allTimeRank,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends State<StreakWidget> {
  int activeUserCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchActiveUsers();
  }

  Future<void> _fetchActiveUsers() async {
    try {
      final response = await ApiService().getUsersCount();
      setState(() {
        activeUserCount = response['total_users'] ?? 0;
      });
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isSmallScreen = maxWidth < 600;
        final scaleFactor = (maxWidth / 400); // %20 küçültme

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 8 * scaleFactor,
            vertical: 4 * scaleFactor,
          ),
          child: Container(
            padding: EdgeInsets.all(12 * scaleFactor),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Color(0xFF2C2C2C) : Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(15 * scaleFactor),
              boxShadow: [
                BoxShadow(
                  color: widget.isDarkMode
                      ? Colors.black
                      : Colors.black.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 8 * scaleFactor,
                  offset: Offset(0, 3 * scaleFactor),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStreakDisplay(scaleFactor),
                SizedBox(height: 8 * scaleFactor),
                _buildTallyMarks(scaleFactor),
                SizedBox(height: 8 * scaleFactor),
                _buildRankings(scaleFactor, isSmallScreen),
                _buildActiveUsersSection(scaleFactor),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).scale(
              duration: 300.ms,
              curve: Curves.elasticOut,
            );
      },
    );
  }

// _buildStreakDisplay metodundan sonra eklenecek metodlar:

  Widget _buildYearMonthDayDisplay(double scaleFactor) {
    int years = widget.streakCount ~/ 365;
    int months = (widget.streakCount % 365) ~/ 30;
    int days = widget.streakCount % 30;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (years > 0)
          _buildTimeUnit(
              years,
              "Yıl",
              widget.isDarkMode ? Colors.purpleAccent : Colors.purple,
              HandDrawnYearPainter(widget.isDarkMode),
              scaleFactor),
        if (years > 0 && (months > 0 || days > 0))
          SizedBox(width: 4 * scaleFactor),
        if (months > 0)
          _buildTimeUnit(
              months,
              "Ay",
              widget.isDarkMode ? Colors.greenAccent[700]! : Colors.green[700]!,
              HandDrawnMonthPainter(widget.isDarkMode),
              scaleFactor),
        if (months > 0 && days > 0) SizedBox(width: 4 * scaleFactor),
        if (days > 0 || (years == 0 && months == 0))
          _buildTimeUnit(
              days,
              "Gün",
              widget.isDarkMode ? Colors.orangeAccent : Colors.orange,
              HandDrawnDayPainter(widget.isDarkMode),
              scaleFactor),
      ],
    );
  }

  Widget _buildTallyMarks(double scaleFactor) {
    int remainingDays = widget.streakCount % 30;
    int groupCount = (remainingDays / 5).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final baseSize = maxWidth / 15;
        final size = max(12.0 * scaleFactor, min(baseSize, 24.0 * scaleFactor));

        return Wrap(
          spacing: 4 * scaleFactor,
          runSpacing: 4 * scaleFactor,
          alignment: WrapAlignment.center,
          children: List.generate(groupCount, (index) {
            int marksInGroup = index == groupCount - 1 ? remainingDays % 5 : 5;
            if (marksInGroup == 0) marksInGroup = 5;
            return CustomPaint(
              size: Size(size, size * 1.25),
              painter: TallyMarksPainter(
                  marksInGroup, (index + 1) % 7 == 0, widget.isDarkMode),
            )
                .animate(delay: (50 * index).ms)
                .scale(duration: 300.ms, curve: Curves.elasticOut);
          }),
        );
      },
    );
  }

  Widget _buildRankings(double scaleFactor, bool isSmallScreen) {
    return Column(
      children: [
        Text(
          "Sıralamalarımız",
          style: GoogleFonts.indieFlower(
            fontSize: 14 * scaleFactor, // küçültüldü
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white70 : Colors.brown[800],
          ),
        ),
        SizedBox(height: 4 * scaleFactor),
        Wrap(
          spacing: 6 * scaleFactor, // küçültüldü
          runSpacing: 4 * scaleFactor,
          alignment: WrapAlignment.center,
          children: [
            if (widget.dailyRank != null)
              _buildRankingItem(
                  "Günlük", widget.dailyRank!, scaleFactor, isSmallScreen),
            if (widget.weeklyRank != null)
              _buildRankingItem(
                  "Haftalık", widget.weeklyRank!, scaleFactor, isSmallScreen),
            if (widget.monthlyRank != null)
              _buildRankingItem(
                  "Aylık", widget.monthlyRank!, scaleFactor, isSmallScreen),
            if (widget.allTimeRank != null)
              _buildRankingItem(
                  "Tüm Zaman", widget.allTimeRank!, scaleFactor, isSmallScreen),
          ],
        ),
      ],
    );
  }

  Widget _buildRankingItem(
      String label, dynamic rank, double scaleFactor, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 5 * scaleFactor,
        vertical: 2 * scaleFactor,
      ),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[800] : Colors.brown[100],
        borderRadius: BorderRadius.circular(5 * scaleFactor),
        border: Border.all(
          color: widget.isDarkMode ? Colors.grey[600]! : Colors.brown[300]!,
          width: 0.8 * scaleFactor,
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.indieFlower(
              fontSize: (isSmallScreen ? 9 : 11) * scaleFactor,
              color: widget.isDarkMode ? Colors.white70 : Colors.brown[800]),
          children: [
            TextSpan(
                text: "$label: ",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
              text: rank == 'not_ranked' ? "Sıralamada Yok" : "#$rank",
              style: GoogleFonts.permanentMarker(
                  fontSize: (isSmallScreen ? 11 : 13) * scaleFactor),
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideX(begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildTimeUnit(int count, String unit, Color color,
      CustomPainter iconPainter, double scaleFactor) {
    return Row(
      children: [
        CustomPaint(
          size: Size(14 * scaleFactor, 14 * scaleFactor), // küçültüldü
          painter: iconPainter,
        ),
        SizedBox(width: 2 * scaleFactor),
        Text(
          '$count',
          style: GoogleFonts.indieFlower(
            fontSize: 16 * scaleFactor, // küçültüldü
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(width: 2 * scaleFactor),
        Text(
          unit,
          style: GoogleFonts.indieFlower(
            fontSize: 12 * scaleFactor, // küçültüldü
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ).animate().scale(duration: 300.ms, curve: Curves.elasticOut);
  }

  Widget _buildStreakDisplay(double scaleFactor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Seri: ",
          style: GoogleFonts.indieFlower(
            fontSize: 16 * scaleFactor,
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white70 : Colors.brown[800],
          ),
        ),
        _buildYearMonthDayDisplay(scaleFactor),
      ],
    ).animate().slideY(
        begin: -0.5, end: 0, duration: 400.ms, curve: Curves.elasticOut);
  }

  // ... Diğer widget build metodları buraya gelecek ...

  Widget _buildActiveUsersSection(double scaleFactor) {
    return Container(
      margin: EdgeInsets.only(top: 12 * scaleFactor),
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scaleFactor,
        vertical: 6 * scaleFactor,
      ),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.grey[850]!.withOpacity(0.5)
            : Colors.brown[50]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12 * scaleFactor),
        border: Border.all(
          color: widget.isDarkMode ? Colors.grey[700]! : Colors.brown[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPulsingDot(scaleFactor),
          SizedBox(width: 6 * scaleFactor),
          _buildUserCount(scaleFactor),
        ],
      ),
    ).animate().slideY(
          begin: 0.3,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildPulsingDot(double scaleFactor) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Container(
          width: 6 * scaleFactor,
          height: 6 * scaleFactor,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.greenAccent.withOpacity(value),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.3 * value),
                spreadRadius: 1 * scaleFactor,
                blurRadius: 2 * scaleFactor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserCount(double scaleFactor) {
    return TweenAnimationBuilder<int>(
      duration: Duration(seconds: 2),
      tween: IntTween(begin: 0, end: activeUserCount),
      builder: (context, value, child) {
        return Text(
          'Şu an $value kişi öğreniyor',
          style: GoogleFonts.indieFlower(
            fontSize: 14 * scaleFactor,
            fontWeight: FontWeight.w600,
            color: widget.isDarkMode ? Colors.grey[300] : Colors.brown[700],
          ),
        );
      },
    );
  }
}

class HandDrawnYearPainter extends CustomPainter {
  final bool isDarkMode;

  HandDrawnYearPainter(this.isDarkMode);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode ? Colors.purpleAccent : Colors.purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    _drawHandDrawnRect(canvas, rect, paint);

    canvas.drawLine(
      Offset(rect.left + 2, rect.top + 4),
      Offset(rect.right - 2, rect.top + 4),
      paint,
    );

    for (int i = 1; i < 3; i++) {
      double y = rect.top + 4 + (rect.height - 4) / 3 * i;
      _drawWavyLine(
          canvas, Offset(rect.left + 2, y), Offset(rect.right - 2, y), paint);
    }
  }

  void _drawHandDrawnRect(Canvas canvas, Rect rect, Paint paint) {
    Path path = Path();
    path.moveTo(rect.left, rect.top);
    _addWavyLine(path, rect.topLeft, rect.topRight);
    _addWavyLine(path, rect.topRight, rect.bottomRight);
    _addWavyLine(path, rect.bottomRight, rect.bottomLeft);
    _addWavyLine(path, rect.bottomLeft, rect.topLeft);
    canvas.drawPath(path, paint);
  }

  void _addWavyLine(Path path, Offset start, Offset end) {
    final rand = Random(start.dx.toInt() * 1000 + start.dy.toInt());
    final distance = (end - start).distance;
    final segments = (distance / 3).round();

    for (int i = 0; i < segments; i++) {
      final t = i / segments;
      final x = start.dx + (end.dx - start.dx) * t;
      final y = start.dy + (end.dy - start.dy) * t;
      final offset = rand.nextDouble() * 1.2 - 0.6;

      if (i == 0) {
        path.moveTo(x, y + offset);
      } else {
        path.lineTo(x, y + offset);
      }
    }
    path.lineTo(end.dx, end.dy);
  }

  void _drawWavyLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    Path path = Path();
    path.moveTo(start.dx, start.dy);
    _addWavyLine(path, start, end);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HandDrawnMonthPainter extends CustomPainter {
  final bool isDarkMode;

  HandDrawnMonthPainter(this.isDarkMode);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode ? Colors.greenAccent[700]! : Colors.green[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    Path path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.2,
        size.width * 0.5, size.height * 0.1);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.2,
        size.width * 0.8, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.8,
        size.width * 0.5, size.height * 0.9);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.8,
        size.width * 0.2, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HandDrawnDayPainter extends CustomPainter {
  final bool isDarkMode;

  HandDrawnDayPainter(this.isDarkMode);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode ? Colors.orangeAccent : Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width * 0.3, paint);

    for (int i = 0; i < 8; i++) {
      double angle = i * pi / 4;
      double startRadius = size.width * 0.35;
      double endRadius = size.width * 0.45;
      canvas.drawLine(
        Offset(size.width / 2 + cos(angle) * startRadius,
            size.height / 2 + sin(angle) * startRadius),
        Offset(size.width / 2 + cos(angle) * endRadius,
            size.height / 2 + sin(angle) * endRadius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TallyMarksPainter extends CustomPainter {
  final int count;
  final bool isWeek;
  final bool isDarkMode;

  TallyMarksPainter(this.count, this.isWeek, this.isDarkMode);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode ? Colors.white70 : Colors.brown[800]!
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final spacing = size.width / 6;

    for (int i = 0; i < count; i++) {
      if (i == 4) {
        canvas.drawLine(
          Offset(0, 0),
          Offset(size.width - spacing, size.height),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(i * spacing, 0),
          Offset(i * spacing, size.height),
          paint,
        );
      }
    }

    if (isWeek) {
      canvas.drawLine(
        Offset(size.width - spacing, 0),
        Offset(0, size.height),
        paint..color = isDarkMode ? Colors.redAccent : Colors.red,
      );
    }

    // Dekoratif noktalar
    for (int i = 0; i < 2; i++) {
      final startX = Random().nextDouble() * size.width;
      final startY = Random().nextDouble() * size.height;
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX + Random().nextDouble() * 1.5 - 0.75,
            startY + Random().nextDouble() * 1.5 - 0.75),
        paint..strokeWidth = 0.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
