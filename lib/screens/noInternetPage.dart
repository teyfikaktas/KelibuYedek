import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import 'package:kelibu/main.dart';

class NoInternetPage extends StatefulWidget {
  @override
  _NoInternetPageState createState() => _NoInternetPageState();
}

class _NoInternetPageState extends State<NoInternetPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _gameController;
  late AnimationController _successController;
  bool _showGame = false;
  Timer? _timer;
  int _score = 0;
  int _round = 0;
  final int _totalRounds = 5;
  bool _isConnected = false;

  List<String> _englishWords = [];
  List<String> _turkishMeanings = [];
  List<bool> _matched = [];
  int? _selectedEnglishIndex;

  final Map<String, String> _wordPairs = {
    'Brave': 'Cesur',
    'Calm': 'Sakin',
    'Cheerful': 'Neşeli',
    'Confident': 'Kendine güvenen',
    'Curious': 'Meraklı',
    'Delightful': 'Hoş',
    'Determined': 'Kararlı',
    'Diligent': 'Çalışkan',
    'Elegant': 'Zarif',
    'Energetic': 'Enerjik',
    'Enthusiastic': 'Hevesli',
    'Fair': 'Adil',
    'Faithful': 'Sadık',
    'Famous': 'Ünlü',
    'Generous': 'Cömert',
    'Gentle': 'Nazik',
    'Grateful': 'Minnettar',
    'Helpful': 'Yardımsever',
    'Honest': 'Dürüst',
    'Hopeful': 'Umutlu',
    'Humble': 'Mütevazı',
    'Intelligent': 'Zeki',
    'Joyful': 'Sevinçli',
    'Kind': 'Nazik',
    'Lively': 'Canlı',
    'Loyal': 'Sadık',
    'Lucky': 'Şanslı',
    'Mature': 'Olgun',
    'Modest': 'Mütevazı',
    'Optimistic': 'İyimser',
    'Organized': 'Düzenli',
    'Patient': 'Sabırlı',
    'Peaceful': 'Barışçıl',
    'Polite': 'Kibar',
    'Positive': 'Pozitif',
    'Powerful': 'Güçlü',
    'Punctual': 'Dakik',
    'Quiet': 'Sessiz',
    'Reliable': 'Güvenilir',
    'Respectful': 'Saygılı',
    'Responsible': 'Sorumlu',
    'Sensible': 'Mantıklı',
    'Sincere': 'Samimi',
    'Smart': 'Akıllı',
    'Strong': 'Güçlü',
    'Successful': 'Başarılı',
    'Supportive': 'Destekleyici',
    'Thoughtful': 'Düşünceli',
    'Trustworthy': 'Güvenilir',
    'Understanding': 'Anlayışlı',
    'Warm': 'Sıcak',
    'Wise': 'Bilge',
    'Active': 'Aktif',
    'Adventurous': 'Maceracı',
    'Ambitious': 'Hırslı',
    'Artistic': 'Sanatçı ruhlu',
    'Brilliant': 'Parlak',
    'Charming': 'Cazibeli',
    'Creative': 'Yaratıcı',
    'Dynamic': 'Dinamik',
    'Eager': 'Hevesli',
    'Friendly': 'Arkadaş canlısı',
    'Funny': 'Komik',
    'Hardworking': 'Çalışkan',
    'Healthy': 'Sağlıklı',
    'Imaginative': 'Hayal gücü yüksek',
    'Independent': 'Bağımsız',
    'Innovative': 'Yenilikçi',
    'Motivated': 'Motivasyonlu',
    'Passionate': 'Tutkulu',
    'Persistent': 'Israrcı',
    'Practical': 'Pratik',
    'Proactive': 'Proaktif',
    'Resourceful': 'Becerikli',
    'Sociable': 'Sosyal',
    'Talented': 'Yetenekli',
    'Versatile': 'Çok yönlü',
    'Vibrant': 'Canlı',
    'Witty': 'Esprili',
    'Youthful': 'Genç',
    'Zealous': 'Azimli',
    'Adaptable': 'Uyumlu',
    'Affectionate': 'Sevecen',
    'Courageous': 'Cesur',
    'Determined': 'Kararlı',
    'Empathetic': 'Empatik',
    'Focused': 'Odaklanmış',
    'Gracious': 'Nazik',
    'Hilarious': 'Çok komik',
    'Innovative': 'Yenilikçi',
    'Joyful': 'Neşeli',
    'Knowledgeable': 'Bilgili',
    'Logical': 'Mantıklı',
    'Observant': 'Dikkatli',
    'Perseverant': 'Azimli',
    'Philosophical': 'Felsefi',
    'Pioneering': 'Öncü'
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
    _startInternetCheck();

    _gameController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _successController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

  }
  void _startInternetCheck() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      _checkInternetConnection();
    });
  }

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    bool newConnectionStatus = connectivityResult != ConnectivityResult.none;

    if (newConnectionStatus != _isConnected) {
      setState(() {
        _isConnected = newConnectionStatus;
      });

      if (_isConnected) {
        _navigateBack();
      }
    }
  }
  void _showConnectionRestoredDialog() {
    if (_showGame) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('İnternet Bağlantısı Geri Geldi'),
            content: Text('Ana sayfaya dönmek istiyor musunuz? Mevcut oyun ilerlemesi kaydedilmeyecek.'),
            actions: <Widget>[
              TextButton(
                child: Text('Oyuna Devam Et'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Ana Sayfaya Dön'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Ana sayfaya dön
                },
              ),
            ],
          );
        },
      );
    } else {
      // Oyun başlamadıysa direkt olarak geri dön
      Navigator.of(context).pop();
    }
  }
  void _navigateBack() {
    // Oyun modunu kapatmadan direkt olarak ana sayfaya dön
    Navigator.of(context).pop();
  }


  void _startNewRound() {
    if (_round < _totalRounds) {
      setState(() {
        _round++;
        _englishWords.clear();
        _turkishMeanings.clear();
        _matched = List.generate(5, (_) => false);
        _selectedEnglishIndex = null;

        var words = _wordPairs.keys.toList()..shuffle();
        _englishWords = words.sublist(0, 5);
        _turkishMeanings = _englishWords.map((word) => _wordPairs[word]!).toList()..shuffle();

        _gameController.reset();
        _gameController.forward();
      });
    } else {
      _showGameOverDialog();
    }
  }

  void _checkMatch(int englishIndex, int turkishIndex) {
    if (_wordPairs[_englishWords[englishIndex]] == _turkishMeanings[turkishIndex]) {
      setState(() {
        _matched[englishIndex] = true;
        _score++;
        _selectedEnglishIndex = null;
      });

      _successController.forward(from: 0.0).then((_) {
        if (_matched.every((match) => match)) {
          _startNewRound();
        }
      });
    } else {
      // Yanlış eşleşme animasyonu
      _gameController.reverse().then((_) => _gameController.forward());
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Oyun Bitti!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Toplam Skorunuz: $_score / ${_totalRounds * 5}'),
              SizedBox(height: 20),
              Text(
                'Hala internet bağlantına ulaşamamak bizi üzdü. Belki de sorun bizdedir? 🤔\n\n'
                    'Destek için kelibu.net adresine bir e-posta gönderebilirsin. Belki de internet '
                    'bağlantımızı çalan uzaylıları birlikte yakalayabiliriz! 👽🕵️‍♀️',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Yeniden Oyna'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _score = 0;
                  _round = 0;
                });
                _startNewRound();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _gameController.dispose();
    _successController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFF58CC02),
        body: SafeArea(
          child: _showGame ? _buildGameWidget() : _buildNoInternetWidget(),
        ),
      ),
    );
  }

  Widget _buildNoInternetWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            return Transform.translate(
              offset: Offset(0, 10 * _controller.value),
              child: child,
            );
          },
          child: Icon(
            Icons.cloud_off,
            size: 150,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 30),
        Text(
          'Hay aksi! İnternet uçtu gitti! 🚀',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Üzgünüz, eğer oyun oyun modlarında iseniz kaldığınız yerden devam etmeyecek!  İnternetin geldiğinde kaldığın sayfaya otomatik olarak yönlendirileceksin. Sorunun bizden kaynaklı olduğunu düşünüyorsan lütfen bize ulaşmayı unutma. Destekleriniz bizim için çok önemli!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
        SizedBox(height: 20),
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ],
    );
  }

  Widget _buildGameWidget() {
    return AnimatedBuilder(
      animation: _gameController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (_gameController.value * 0.1),
          child: child,
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Kelime Eşleştirme Oyunu',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  'Tur: $_round / $_totalRounds',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
                Text(
                  'Skor: $_score',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ..._englishWords.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String word = entry.value;
                  return AnimatedBuilder(
                    animation: _successController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _matched[idx] ? 1 + (_successController.value * 0.2) : 1.0,
                        child: child,
                      );
                    },
                    child: ElevatedButton(
                      child: Text(word, style: TextStyle(fontSize: 18)),
                      onPressed: _matched[idx] ? null : () {
                        setState(() {
                          _selectedEnglishIndex = idx;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        primary: _selectedEnglishIndex == idx ? Colors.yellow : Colors.white,
                        onPrimary: Color(0xFF58CC02),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  );
                }).toList(),
                ..._turkishMeanings.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String meaning = entry.value;
                  return ElevatedButton(
                    child: Text(meaning, style: TextStyle(fontSize: 18)),
                    onPressed: _selectedEnglishIndex == null ? null : () {
                      _checkMatch(_selectedEnglishIndex!, idx);
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.white,
                      onPrimary: Color(0xFF58CC02),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}