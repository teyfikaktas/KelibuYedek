import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../advantages/books_pro.dart';

class LogoColorTheme {
  static const Color primaryBlue = Color(0xFF0066CC); // Daha canlı mavi
  static const Color accentPurple = Color(0xFF5E35B1); // Daha zengin mor
  static const Color accentYellow = Color(0xFFFFAB00); // Sıcak amber sarısı
  static const Color accentRed = Color(0xFFD50000); // Daha canlı kırmızı

  // Yeni eklenen renkler
  static const Color lemonYellow = Color(0xFFFFF176); // Limon sarısı
  static const Color mutedYellow = Color(0xFFFFECB3); // Sönük sarı

  // Tamamlayıcı renkler
  static const Color neutralGray = Color(0xFF455A64); // Koyu slate gri
  static const Color lightGray = Color(0xFFECEFF1); // Çok açık gri
  static const Color successGreen = Color(0xFF00C853); // Başarı yeşili

  // Gradient renkler
  static const List<Color> blueGradient = [
    Color(0xFF2979FF),
    Color(0xFF0D47A1),
  ];
  static const List<Color> purpleGradient = [
    Color(0xFF7C4DFF),
    Color(0xFF4527A0),
  ];
  static const List<Color> warmGradient = [
    Color(0xFFFFAB00),
    Color(0xFFD50000),
  ];

  // Koyu tema için arka plan renkleri
  static const Color darkBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);

  // Açık tema için renk şeması
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: primaryBlue,
      secondary: accentPurple,
      tertiary: accentYellow,
      error: accentRed,
      background: Colors.white,
      surface: lightGray,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: neutralGray,
      onSurface: Colors.grey[800]!,
    ),
  );

  // Koyu tema için renk şeması
  static final ThemeData darkTheme = ThemeData(
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: darkBg,
    colorScheme: ColorScheme.dark(
      primary: primaryBlue,
      secondary: accentPurple,
      tertiary: accentYellow,
      error: accentRed,
      background: darkBg,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.grey[300]!,
      onSurface: Colors.grey[300]!,
    ),
  );
}

class KelibuDoodlePromo extends StatefulWidget {
  final Color color;

  const KelibuDoodlePromo({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  State<KelibuDoodlePromo> createState() => _KelibuDoodlePromoState();
}

class _KelibuDoodlePromoState extends State<KelibuDoodlePromo>
    with SingleTickerProviderStateMixin {
  bool _isDarkMode = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<BookCategory> bookCategories = [
    BookCategory(
      title: 'Genel İngilizce',
      books: [
        Book(title: 'L1', color: LogoColorTheme.primaryBlue),
        Book(title: 'L2', color: LogoColorTheme.primaryBlue),
        Book(title: 'L3', color: LogoColorTheme.primaryBlue),
      ],
    ),
    BookCategory(
      title: 'Sağlık Serisi',
      books: [
        Book(title: 'S0', color: LogoColorTheme.accentPurple),
        Book(title: 'S1', color: LogoColorTheme.accentPurple),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();

    // Animasyon için controller oluştur
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  // Kitap kartı oluşturan method
  Widget _buildBookCard(Book book) {
    final isHealthSeries = book.title.startsWith('S');
    final levelNum = isHealthSeries
        ? (int.parse(book.title.substring(1)) + 1).toString()
        : book.title.substring(1);

    final List<Color> gradientColors = isHealthSeries
        ? [LogoColorTheme.purpleGradient[0], LogoColorTheme.purpleGradient[1]]
        : [LogoColorTheme.blueGradient[0], LogoColorTheme.blueGradient[1]];

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          width: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Arka plan desenli efektler
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // İçerik
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isHealthSeries
                              ? Icons.medical_services_rounded
                              : Icons.school_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isHealthSeries
                            ? 'Sağlık ${levelNum}'
                            : 'Level ${levelNum}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isHealthSeries
                            ? 'Sağlık İngilizcesi'
                            : 'Genel İngilizce',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.book_rounded,
                              color: Colors.white.withOpacity(0.9),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              book.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Buton widget'ı oluşturan method
  Widget _buildActionButton(String text, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: LogoColorTheme.warmGradient,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: LogoColorTheme.accentRed.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Başlık kısmını oluşturan method
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo ve başlık
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    // "Kelibu" kısmı
                    const TextSpan(
                      text: 'Kelibu ',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    // "Doo" kısmı: limon sarısı
                    TextSpan(
                      text: 'Doo',
                      style: TextStyle(
                        fontSize: 32,
                        color: LogoColorTheme.lemonYellow,
                        fontFamily: 'Indie Flower',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // "dle" kısmı: sönük sarı
                    TextSpan(
                      text: 'dle',
                      style: TextStyle(
                        fontSize: 32,
                        color: LogoColorTheme.mutedYellow,
                        fontFamily: 'Indie Flower',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.book,
                color: LogoColorTheme.lemonYellow,
                size: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Tanıtım metni
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Text(
            'Kelibu\'nun yeni PDF uygulaması KelibuDoodle\'ı PhD Akademi Kitapları ile deneyin!',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Aksiyon butonu
        _buildActionButton(
          'Hemen Dene',
          Icons.arrow_forward_rounded,
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const KelibuProListWidget(),
              ),
            );
          },
        ),
      ],
    );
  }

  // Kitaplar bölümünü oluşturan method
  Widget _buildBookSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),

        // Bölüm başlığı
        Row(
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: LogoColorTheme.accentYellow,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
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

        // Kategoriler
        ...bookCategories
            .map((category) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 4),
                      child: Text(
                        category.title,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 240,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: category.books.length,
                        itemBuilder: (context, index) {
                          return _buildBookCard(category.books[index]);
                        },
                      ),
                    ),
                  ],
                ))
            .toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Arka plan rengi
    final backgroundColor = _isDarkMode
        ? LogoColorTheme.darkTheme.colorScheme.background
        : LogoColorTheme.primaryBlue;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? [LogoColorTheme.darkBg, Color(0xFF1D2B3A)]
              : [LogoColorTheme.primaryBlue, Color(0xFF003D82)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Arka plan desenleri
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Ana içerik
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildBookSection(),
                const SizedBox(height: 20),
              ],
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
