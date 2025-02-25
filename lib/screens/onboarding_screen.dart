import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class SlideData {
  final IconData icon;
  final String title;
  final String description;

  SlideData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// Güncellenmiş slide listesi (son maddeye "Demo Seti" ekledik)
  final List<SlideData> slides = [
    SlideData(
      icon: Icons.videogame_asset_outlined,
      title: "Oyun Modları",
      description:
      "5 farklı oyun modu ile öğrenmenize güç katın! Bilmediğiniz kelimeleri işaretleyerek, sadece onlara çalışarak zaman kazanın.",
    ),
    SlideData(
      icon: Icons.flash_on_outlined,
      title: "Flash Kart Modu",
      description:
      "Flash kartlarla kelime bilginizi sistemli bir şekilde artırın!",
    ),
    SlideData(
      icon: Icons.class_outlined,
      title: "Klasik Kelibu",
      description: "Öğrenme garantili, meşhur klasik Kelibu modu ile tanışın.",
    ),
    SlideData(
      icon: Icons.headphones_outlined,
      title: "Dinle Modu",
      description:
      "Kelimenin telaffuzunu dinleyerek kalıcı bir öğrenme deneyimi edinin.",
    ),
    SlideData(
      icon: Icons.quiz_outlined,
      title: "Öğren Modu",
      description: "Geleneksel quiz formatını kullanarak bilgilerinizi test edin.",
    ),
    SlideData(
      icon: Icons.menu_book_outlined,
      title: "Çalış Modu",
      description:
      "Eş anlamlar, örnek cümleler ve türemelerle kelimeleri derinlemesine inceleyin.",
    ),
    // 7) Bilinmeyen kelimeleri işaretleme
    SlideData(
      icon: Icons.star_border_purple500_outlined,
      title: "Bilinmeyen Kelimeleri İşaretle",
      description:
      "Her sette karşılaştığınız ve zorlandığınız kelimeleri ‘yıldız’ işareti ile etiketleyerek, daha sonra tekrar gözden geçirmeye yönelik kişiselleştirilmiş bir öğrenme deneyimi oluşturun.",
    ),
    // 8) Yıldızlı kelimelere odaklanma
    SlideData(
      icon: Icons.star_rate_rounded,
      title: "Yıldızlı Kelimelere Odaklanın",
      description:
      "Yıldızladığınız kelimelere özel ayrı bir çalışma programı oluşturarak, öğrenme sürecinizi ihtiyaçlarınıza göre yönlendirin ve unutma riskini minimuma indirin.",
    ),
    // 9) Demo Seti
    SlideData(
      icon: Icons.card_giftcard,
      title: "Ücretsiz Demo Seti",
      description:
      "Üyelik oluşturduğunuz anda hesabınıza otomatik olarak bir demo seti tanımlanır. Böylece uygulamayı tamamen ücretsiz biçimde hemen deneyimlemeye başlayabilirsiniz.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: slides.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                return buildSlide(slides[index]);
              },
            ),

            /// Sağ üst köşede "Geç" (Skip) butonu
            Positioned(
              top: 20,
              right: 20,
              child: TextButton(
                onPressed: _onBoardingComplete,
                child: Text(
                  "Geç",
                  style: TextStyle(
                    color: Color(0xFF58CC02),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            /// Alttaki noktalar (indicator) ve buton
            Positioned(
              bottom: 20.0,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                          (index) => buildDot(index),
                    ),
                  ),
                  SizedBox(height: 20),
                  buildButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSlide(SlideData slideData) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            slideData.icon,
            size: 120,
            color: Color(0xFF58CC02),
          ),
          SizedBox(height: 40),
          Text(
            slideData.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF58CC02),
            ),
          ),
          SizedBox(height: 10),
          Text(
            slideData.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.only(right: 6),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Color(0xFF58CC02) : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget buildButton() {
    final isLastPage = _currentPage == slides.length - 1;

    return GestureDetector(
      onTap: () {
        if (isLastPage) {
          _onBoardingComplete();
        } else {
          _pageController.nextPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Color(0xFF58CC02),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF58CC02).withOpacity(0.4),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            isLastPage ? 'Maceraya Başla!' : 'Devam Et',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _onBoardingComplete() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }
}
