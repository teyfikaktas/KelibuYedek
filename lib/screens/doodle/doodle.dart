import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../advantages/books_pro.dart';
import '../race/core/main.dart';
import '../race/screens/listrooms.dart';



class KelibuDoodlePromo extends StatefulWidget {
  final Color color;

  const KelibuDoodlePromo({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  State<KelibuDoodlePromo> createState() => _KelibuDoodlePromoState();
}

class _KelibuDoodlePromoState extends State<KelibuDoodlePromo> {
  bool _isDarkMode = false;

  final List<BookCategory> bookCategories = [
    BookCategory(
      title: 'Genel İngilizce',
      books: [
        Book(title: 'L1', color: Colors.blue.shade400),
        Book(title: 'L2', color: Colors.blue.shade500),
        Book(title: 'L3', color: Colors.blue.shade600),
      ],
    ),
    BookCategory(
      title: 'Sağlık Serisi',
      books: [
        Book(title: 'S0', color: Colors.teal.shade400),
        Book(title: 'S1', color: Colors.teal.shade600),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  Widget _buildBookSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.purpleAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Kitaplarımız',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Hemen Dene butonunu buraya taşıyoruz
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const KelibuProListWidget(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.purpleAccent,
                      Color(0xFF9C27B0),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Hemen Dene',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ...bookCategories.map((category) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                category.title,
                style: TextStyle(
                  fontSize: 18,
                  color: _isDarkMode ? Colors.grey[300] : Colors.white,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: category.books.map((book) {
                  final isHealthSeries = book.title.startsWith('S');
                  final levelNum = isHealthSeries
                      ? (int.parse(book.title.substring(1)) + 1).toString()
                      : book.title.substring(1);

                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Container(
                      width: 160,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            book.color.withOpacity(0.3),
                            book.color.withOpacity(0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: book.color.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: book.color.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: book.color.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isHealthSeries ? Icons.medical_services_rounded : Icons.school_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isHealthSeries ? 'Sağlık ${levelNum}' : 'Level ${levelNum}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isHealthSeries ? 'Sağlık İngilizcesi' : 'Genel İngilizce',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: book.color.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.book_rounded,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  book.title,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        )).toList(),
        const SizedBox(height: 30),
      ],
    );
  }  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[900] : widget.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(_isDarkMode ? 50 : 25, 0, 0, 0),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Kelibu ',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            TextSpan(
                              text: 'Doo',
                              style: TextStyle(
                                fontSize: 32,
                                color: Colors.purpleAccent,
                                fontFamily: 'Indie Flower',
                              ),
                            ),
                            TextSpan(
                              text: 'dle',
                              style: TextStyle(
                                fontSize: 32,
                                color: Colors.tealAccent,
                                fontFamily: 'Indie Flower',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Kelibu\'nun yeni PDF uygulaması KelibuDoodle\'ı PhD Akademi Kitapları ile deneyin!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: _isDarkMode ? Colors.grey[300] : Colors.white,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  _buildBookSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookCategory {
  final String title;
  final List<Book> books;

  BookCategory({
    required this.title,
    required this.books,
  });
}

class Book {
  final String title;
  final Color color;

  Book({
    required this.title,
    required this.color,
  });
}

abstract class Shape {
  final Color color;

  Shape({required this.color});
}

class OvalShape extends Shape {
  final Rect rect;

  OvalShape({required this.rect, required Color color}) : super(color: color);
}

class LineShape extends Shape {
  final Offset start;
  final Offset end;
  final double strokeWidth;

  LineShape({
    required this.start,
    required this.end,
    required this.strokeWidth,
    required Color color,
  }) : super(color: color);
}

class DoodleBackgroundPainter extends CustomPainter {
  final List<Shape> shapes;

  DoodleBackgroundPainter({required this.shapes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var shape in shapes) {
      paint.color = shape.color;
      if (shape is OvalShape) {
        paint.style = PaintingStyle.fill;
        canvas.drawOval(shape.rect, paint);
      } else if (shape is LineShape) {
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = shape.strokeWidth;
        canvas.drawLine(shape.start, shape.end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DuolingoStyleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Duolingo tarzı dalgalı arka plan
    final path = Path();
    path.moveTo(0, size.height * 0.75);

    for (int i = 0; i < 5; i++) {
      path.quadraticBezierTo(
        size.width * (0.2 + 0.2 * i),
        size.height * (0.7 + (i % 2 == 0 ? 0.1 : -0.1)),
        size.width * (0.4 + 0.2 * i),
        size.height * 0.75,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Doodle ikonları
    drawDoodleIcon(canvas, size, Icons.brush, 0.1, 0.1);
    drawDoodleIcon(canvas, size, Icons.edit, 0.9, 0.2);
    drawDoodleIcon(canvas, size, Icons.color_lens, 0.2, 0.8);
    drawDoodleIcon(canvas, size, Icons.format_paint, 0.8, 0.7);
  }

  void drawDoodleIcon(
      Canvas canvas, Size size, IconData icon, double dx, double dy) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 24,
          fontFamily: icon.fontFamily,
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * dx, size.height * dy));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
