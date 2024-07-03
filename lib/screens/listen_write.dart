import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/Models/wordDetaik.dart'; // Adjust this import according to your project.
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../providers/user_provider.dart'; // Adjust the path to your UserProvider
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../variables.dart';

class ListenAndWriteScreen extends StatefulWidget {
  final List<WordDetail> words;

  ListenAndWriteScreen({Key? key, required this.words}) : super(key: key);

  @override
  _ListenAndWriteScreenState createState() => _ListenAndWriteScreenState();
}

class _ListenAndWriteScreenState extends State<ListenAndWriteScreen> {
  int currentWordIndex = 0;
  final FlutterTts flutterTts = FlutterTts();
  String correctWord = '';
  String correctWordMeaning = '';
  int correctWordLength = 0;
  TextEditingController textEditingController = TextEditingController();
  bool _isListening = false;
  String revealedLetters = ''; // To store revealed letters
  bool isButtonClicked = false; // Butona tıklanma durumunu takip eder.
  Color buttonColor = Colors.pink; // Butonun varsayılan rengi
  late UserProvider userProvider;
  bool _isDarkMode = false; // Dark mode durumu

  late ValueNotifier<int> _userPoints; // Kullanıcı puanı için ValueNotifier

  @override
  void initState() {
    super.initState();
    _userPoints = ValueNotifier<int>(Provider.of<UserProvider>(context, listen: false).point);

    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrentWord());
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String word) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.speak(word);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Since context is available, initialize userProvider here.
    userProvider = Provider.of<UserProvider>(context);
    _userPoints = ValueNotifier<int>(userProvider.point); // Adjusted the initialization to this point.
  }

  Future<void> _speakCurrentWord() async {
    correctWord = widget.words[currentWordIndex].word.toLowerCase();
    correctWordMeaning = widget.words[currentWordIndex].meaning.toLowerCase();
    correctWordLength = correctWord.length;

    await _speak(correctWord);
    setState(() {}); // This will trigger a UI update to display the correctWord and its length.
  }

  void _checkAnswer() async {
    bool correct = textEditingController.text.trim().toLowerCase() == correctWord;
    setState(() {
      buttonColor = correct ? Colors.green : Colors.red;
    });

    Timer(Duration(seconds: 2), () {
      setState(() {
        buttonColor = Colors.pink; // 2 saniye sonra butonun rengini eski haline döndür
      });
    });

    if (correct) {
      int newPoint = userProvider.point;
      newPoint = newPoint + 3;
      userProvider.addPoint(3); // UserProvider üzerinden puanı artır
      _userPoints.value = userProvider.point; // UserProvider'daki güncel puanı ValueNotifier ile eşitle
      await ApiService().updateUserPointTimePeriod(userProvider.userId, newPoint, 3); // API üzerinden puanı güncelleyin
      userProvider.addPoint(newPoint); // UserProvider'daki puanı güncelleyin
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        title: 'Doğru!',
        desc: 'Tebrikler! Kelimenin anlamı: $correctWordMeaning',
        btnOkOnPress: _proceedToNextWord,
        dismissOnTouchOutside: false,
      )..show();
    } else {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.scale,
        title: 'Yanlış!',
        desc: 'Tekrar dener misin? Anlam: $correctWordMeaning',
        btnOkOnPress: () {},
        dismissOnTouchOutside: false,
      )..show();
    }

    textEditingController.clear();
  }

  void _proceedToNextWord() {
    if (currentWordIndex < widget.words.length - 1) {
      setState(() {
        currentWordIndex++;
      });
      _speakCurrentWord();
    } else {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        title: 'Tebrikler!',
        desc: 'Tüm kelimeleri tamamladınız.',
        btnOkOnPress: () {},
        dismissOnTouchOutside: false,
      )..show();
    }
  }

  @override
  Widget build(BuildContext context) {
    String fullImageUrl = widget.words[currentWordIndex].image != null
        ? "https://cloud.phdakademi.com/uploads/kelibu.net/${widget.words[currentWordIndex].image}"
        : "https://kelibu.net/images/defaultimage.png";
    UserProvider userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isDarkMode ? darkModeColors["background"] : Colors.white,
        title: Text(
          'Dinle ve Yaz',
          style: GoogleFonts.poppins(
            color: _isDarkMode ? darkModeColors["text"] : Colors.pink,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: _isDarkMode ? darkModeColors["text"] : Colors.pink,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ValueListenableBuilder<int>(
              valueListenable: _userPoints,
              builder: (_, value, __) => Chip(
                label: Text(
                  'Puan: $value',
                  style: TextStyle(
                    color: _isDarkMode ? darkModeColors["text"] : lightModeColors["text"],
                  ),
                ),
                backgroundColor: _isDarkMode ? darkModeColors["cardBackground"] : Colors.white54,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: _isDarkMode ? darkModeColors["cardBackground"] : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Image.network(
                  fullImageUrl,
                  width: 100,
                  height: 100,
                  errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                    // Burada resim yüklenemediğinde gösterilecek alternatif bir resmi belirleyebilirsiniz.
                    return Image.asset('assets/logo.png', width: 100, height: 100);
                  },
                ),
                SizedBox(height: 20),
                Text(
                  'Dinlediğiniz kelimeyi yazınız.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? darkModeColors["text"] : Colors.pink,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textEditingController,
                        decoration: InputDecoration(
                          labelText: 'Cevabınız.',
                          labelStyle: TextStyle(color: _isDarkMode ? darkModeColors["text"] : Colors.pink),
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _isDarkMode ? darkModeColors["text"]! : Colors.pink)),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: _isDarkMode ? darkModeColors["inputBackground"] : Colors.pink.shade50,
                        ),
                        style: TextStyle(color: _isDarkMode ? darkModeColors["text"] : Colors.black),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.volume_up, color: _isDarkMode ? darkModeColors["iconColor"] : Colors.pink),
                      onPressed: () => _speak(correctWord),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _checkAnswer,
                  icon: Icon(Icons.check),
                  label: Text('Kontrol Et'),
                  style: ElevatedButton.styleFrom(
                    primary: buttonColor, // Animasyon için rengi değişken kullanıyoruz
                    onPrimary: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}