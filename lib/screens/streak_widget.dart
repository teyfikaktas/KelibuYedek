import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

class StreakWidget extends StatelessWidget {
  final int streakCount;
  final int? dailyRank;
  final int? weeklyRank;
  final int? monthlyRank;
  final int? allTimeRank;

  const StreakWidget({
    Key? key,
    required this.streakCount,
    this.dailyRank,
    this.weeklyRank,
    this.monthlyRank,
    this.allTimeRank,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFFFF9C4),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStreakDisplay(),  // Yeni eklenen metod
            SizedBox(height: 12),
            _buildTallyMarks(),
            SizedBox(height: 12),
            _buildRankings(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(duration: 400.ms, curve: Curves.elasticOut);
  }

  Widget _buildStreakDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Seri: ",
          style: GoogleFonts.indieFlower(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.brown[800],
          ),
        ),
        _buildYearMonthDayDisplay(),
      ],
    ).animate().slideY(begin: -0.5, end: 0, duration: 500.ms, curve: Curves.elasticOut);
  }
  Widget _buildYearMonthDayDisplay() {
    int years = streakCount ~/ 365;
    int months = (streakCount % 365) ~/ 30;
    int days = streakCount % 30;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (years > 0) _buildTimeUnit(years, "Yıl", Colors.purple, HandDrawnYearPainter()),
        if (years > 0 && (months > 0 || days > 0)) SizedBox(width: 4),
        if (months > 0) _buildTimeUnit(months, "Ay", Colors.green[700]!, HandDrawnMonthPainter()),
        if (months > 0 && days > 0) SizedBox(width: 4),
        if (days > 0 || (years == 0 && months == 0)) _buildTimeUnit(days, "Gün", Colors.orange, HandDrawnDayPainter()),
      ],
    );
  }

  Widget _buildTimeUnit(int count, String unit, Color color, CustomPainter iconPainter) {
    return Row(
      children: [
        CustomPaint(
          size: Size(20, 20),
          painter: iconPainter,
        ),
        SizedBox(width: 2),
        Text(
          '$count',
          style: GoogleFonts.indieFlower(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(width: 2),
        Text(
          unit,
          style: GoogleFonts.indieFlower(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ).animate().scale(duration: 300.ms, curve: Curves.elasticOut);
  }

  Widget _buildTallyMarks() {
    int remainingDays = streakCount % 30;
    int groupCount = (remainingDays / 5).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final baseSize = maxWidth / 12;
        final size = max(15.0, min(baseSize, 30.0));

        return Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: List.generate(groupCount, (index) {
            int marksInGroup = index == groupCount - 1 ? remainingDays % 5 : 5;
            if (marksInGroup == 0) marksInGroup = 5;
            return CustomPaint(
              size: Size(size, size * 1.25),
              painter: TallyMarksPainter(marksInGroup, (index + 1) % 7 == 0),
            ).animate(delay: (50 * index).ms).scale(duration: 300.ms, curve: Curves.elasticOut);
          }),
        );
      },
    );
  }

  Widget _buildRankings() {
    return Column(
      children: [
        Text(
          "Sıralamalarımız",
          style: GoogleFonts.indieFlower(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.brown[800],
          ),
        ),
        SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            if (dailyRank != null) _buildRankingItem("Günlük", dailyRank!),
            if (weeklyRank != null) _buildRankingItem("Haftalık", weeklyRank!),
            if (monthlyRank != null) _buildRankingItem("Aylık", monthlyRank!),
            if (allTimeRank != null) _buildRankingItem("Tüm Zaman", allTimeRank!),
          ],
        ),
      ],
    );
  }

  Widget _buildRankingItem(String label, dynamic rank) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.brown[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.brown[300]!, width: 1),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.indieFlower(fontSize: 14, color: Colors.brown[800]),
          children: [
            TextSpan(text: "$label: ", style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
              text: rank == 'not_ranked' ? "Sıralamada Yok" : "#$rank",
              style: GoogleFonts.permanentMarker(fontSize: 16),
            ),
          ],
        ),
      ),
    ).animate().slideX(begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
  Widget _buildMotivationalMessage() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.brown[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown[300]!, width: 1),
      ),
      child: Text(
        _getRandomMotivationalMessage(),
        textAlign: TextAlign.center,
        style: GoogleFonts.comicNeue(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.brown[800],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  String _getRandomMotivationalMessage() {
    final messages = [
      "Harika gidiyorsun! Devam et!",
      "Her gün yeni bir fırsat!",
      "Başarı, tutarlılığın ödülüdür!",
      "Kendini her gün biraz daha geliştiriyorsun!",
      "Bu seriyi bozmak yok!",
      "Öğrenme yolculuğunda emin adımlarla ilerliyorsun!",
      "Bugün de hedefine bir adım daha yaklaştın!",
      "Tutarlılığın gücünü hisset!",
      "Her gün yeni bir kelime, yeni bir dünya!",
      "Dil öğrenme serüveninde kararlılıkla ilerliyorsun!",
    ];
    return messages[Random().nextInt(messages.length)];
  }
}

class HandDrawnYearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);

    _drawHandDrawnRect(canvas, rect, paint);

    canvas.drawLine(
      Offset(rect.left + 3, rect.top + 5),
      Offset(rect.right - 3, rect.top + 5),
      paint,
    );

    for (int i = 1; i < 3; i++) {
      double y = rect.top + 5 + (rect.height - 5) / 3 * i;
      _drawWavyLine(canvas, Offset(rect.left + 3, y), Offset(rect.right - 3, y), paint);
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
      final offset = rand.nextDouble() * 1.5 - 0.75;

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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    Path path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.2, size.width * 0.5, size.height * 0.1);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.2, size.width * 0.8, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.8, size.width * 0.5, size.height * 0.9);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.8, size.width * 0.2, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HandDrawnDayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.35, paint);

    for (int i = 0; i < 8; i++) {
      double angle = i * pi / 4;
      double startRadius = size.width * 0.4;
      double endRadius = size.width * 0.5;
      canvas.drawLine(
        Offset(size.width / 2 + cos(angle) * startRadius, size.height / 2 + sin(angle) * startRadius),
        Offset(size.width / 2 + cos(angle) * endRadius, size.height / 2 + sin(angle) * endRadius),
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

  TallyMarksPainter(this.count, this.isWeek);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown[800]!
      ..strokeWidth = 1.5
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
        paint..color = Colors.red,
      );
    }

    for (int i = 0; i < 3; i++) {
      final startX = Random().nextDouble() * size.width;
      final startY = Random().nextDouble() * size.height;
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX + Random().nextDouble() * 2 - 1, startY + Random().nextDouble() * 2 - 1),
        paint..strokeWidth = 0.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}