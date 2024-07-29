import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<Map<String, String>> slides = [
    {
      "image": "assets/gamemod.png",
      "title": "Oyun Modları",
      "description": "5 Farklı oyun modu ile öğrenmenize güç katın! Bilmediğiniz Kelimeleri yıldızlayın ve sadece o kelimelere çalışarak zamandan tasarruf edin!"
    },
    {
      "image": "assets/flash.png",
      "title": "Flash Kart Modu",
      "description": "Flash kartlarla kelime haznenizi genişletin!"
    },
    {
      "image": "assets/klasik.png",
      "title": "Klasik Kelibu",
      "description": "Öğrenme garantili meşhur klasik kelibu modu ile tanışın"
    },
    {
      "image": "assets/dinle.png",
      "title": "Dinle Modu",
      "description": "Kelimelerin telaffuzunu dinleyerek öğrenin!"
    },
    {
      "image": "assets/ogren.png",
      "title": "Öğren Modu",
      "description": "Geleneksel quiz modu ile öğrenmenizi çeşitlendirin!"
    },
    {
      "image": "assets/calis.png",
      "title": "Çalış Modu",
      "description": "Kelimelerin eş anlamlıları, örnek cümleleri, collacations ve türemeleri ile kelimeyi derinlemesine öğrenin!"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
    );
  }

  Widget buildSlide(Map<String, String> slideData) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            slideData["image"]!,
            height: MediaQuery.of(context).size.height * 0.4,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 40),
          Text(
            slideData["title"]!,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF58CC02), // Duolingo yeşili
            ),
          ),
          SizedBox(height: 10),
          Text(
            slideData["description"]!,
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
      margin: EdgeInsets.only(right: 5),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Color(0xFF58CC02) : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget buildButton() {
    return GestureDetector(
      onTap: () {
        if (_currentPage == slides.length - 1) {
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
          color: Color(0xFF58CC02), // Duolingo yeşili
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
            _currentPage == slides.length - 1 ? 'Maceraya Başla!' : 'Devam Et',
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