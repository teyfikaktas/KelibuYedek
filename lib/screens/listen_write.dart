import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/Models/wordDetaik.dart';
import 'package:kelibu/screens/home_screen_widgets/score_display.dart';
import 'package:kelibu/screens/video_player.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';
import '../globalDart/urls.dart';
import '../providers/user_provider.dart';
import '../shared_preferences/shared_preferences.dart';
import '../variables.dart';

class ListenAndWriteScreen extends ConsumerStatefulWidget {
  final List<WordDetail> words;
  final int classroomId;
  final int studySetId;

  ListenAndWriteScreen({
    Key? key,
    required this.words,
    required this.classroomId,
    required this.studySetId,
  }) : super(key: key);

  @override
  _ListenAndWriteScreenState createState() => _ListenAndWriteScreenState();
}

class _ListenAndWriteScreenState extends ConsumerState<ListenAndWriteScreen>
    with SingleTickerProviderStateMixin {
  int currentWordIndex = 0;
  final FlutterTts flutterTts = FlutterTts();
  String correctWord = '';
  String correctWordMeaning = '';
  late List<WordDetail> originalWords;
  late List<WordDetail> currentWords;

  TextEditingController textEditingController = TextEditingController();
  bool _isDarkMode = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool isVirtualKeyboardVisible = false;
  bool isMenuVisible = false;
  ValueNotifier<int> starredWordCountNotifier = ValueNotifier(0);
  Map<int, ValueNotifier<bool>> starredNotifiers = {};
  Map<int, bool> starredStatus = {};
  bool showStarredOnly = false;
  List<String> enteredLetters = [];

  @override
  void initState() {
    super.initState();
    ApiService().logSetEntry('Dinle yaz', 'Dinle ve Yaz moduna ', '');

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakCurrentWord();
      _loadStarredStatusAsync();
    });

    originalWords = List.from(widget.words);
    _shuffleAndInitializeWords();
    _initializeEnteredLetters();
    _loadDarkModePreference();
  }

  void _shuffleAndInitializeWords() {
    currentWords = List.from(originalWords);
    currentWords.shuffle();
    currentWordIndex = 0;
  }

  void _initializeEnteredLetters() {
    enteredLetters = List.filled(correctWord.length, '');
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
    _animationController.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  Future<void> _speak(String word) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.speak(word);
  }

  Future<void> _speakCurrentWord() async {
    setState(() {
      correctWord = widget.words[currentWordIndex].word.toLowerCase();
      correctWordMeaning = widget.words[currentWordIndex].meaning.toLowerCase();
      enteredLetters = List.filled(correctWord.length, '');
    });

    await _speak(correctWord);
    textEditingController.clear();
    _animationController.forward(from: 0.0);
  }

  void _checkAnswer() async {
    String enteredWord = textEditingController.text.trim().toLowerCase();
    bool correct = enteredWord == correctWord;

    if (correct) {
      int bonusPoints = correctWord.length -
          enteredLetters.where((letter) => letter.isNotEmpty).length;
      int pointsEarned = 3 + bonusPoints;

      ApiService().addPoints(
        points: pointsEarned,
        type: 'listen_write_correct',
        metadata: {
          'classroomId': widget.classroomId,
          'studySetId': widget.studySetId,
          'word': correctWord,
          'bonusPoints': bonusPoints,
        },
      );

      ref.read(pointsProvider.notifier).addPoints(pointsEarned);
      _showSuccessDialog(bonusPoints);
    } else {
      _showErrorDialog("Yanlış cevap! Doğru kelime: $correctWord");
    }
  }

  void _showSuccessDialog(int bonusPoints) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: 'Doğru!',
      text: 'Tebrikler! Kelimenin anlamı: $correctWordMeaning\nBonus Puan: $bonusPoints',
      onConfirmBtnTap: () {
        Navigator.of(context).pop();
        _proceedToNextWord();
      },
      barrierDismissible: false,
      confirmBtnText: 'Tamam',
    );
  }

  void _showErrorDialog(String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Yanlış!',
      text: message,
      barrierDismissible: false,
      confirmBtnText: 'Tamam',
    );
  }

  void _proceedToNextWord() {
    if (currentWordIndex < widget.words.length - 1) {
      setState(() {
        currentWordIndex++;
        textEditingController.clear();
      });
      _speakCurrentWord();
    } else {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Tebrikler!',
        text: 'Tüm kelimeleri tamamladınız.',
        barrierDismissible: false,
        confirmBtnText: 'Tamam',
      );
    }
  }

  void _getHint() {
    final currentPoints = ref.read(pointsProvider);
    if (currentPoints >= 1) {
      setState(() {
        List<int> emptyIndexes = [];
        for (int i = 0; i < correctWord.length; i++) {
          if (enteredLetters[i].isEmpty) {
            emptyIndexes.add(i);
          }
        }
        if (emptyIndexes.isNotEmpty) {
          int randomIndex = emptyIndexes[Random().nextInt(emptyIndexes.length)];
          enteredLetters[randomIndex] = correctWord[randomIndex];

          ApiService().addPoints(
            points: -1,
            type: 'listen_write_hint',
            metadata: {
              'classroomId': widget.classroomId,
              'studySetId': widget.studySetId,
              'word': correctWord,
            },
          );
          ref.read(pointsProvider.notifier).addPoints(-1);
        }
      });
    } else {
      _showErrorDialog("Yeterli puanınız yok. En az 1 puan gerekiyor.");
    }
  }

  void _toggleVirtualKeyboard() {
    setState(() {
      isVirtualKeyboardVisible = !isVirtualKeyboardVisible;
    });
  }

  void toggleStarredOnly() {
    setState(() {
      showStarredOnly = !showStarredOnly;
      if (showStarredOnly) {
        var filteredWords = originalWords
            .where((word) => starredStatus[word.id] ?? false)
            .toList();
        if (filteredWords.isNotEmpty) {
          currentWords = filteredWords;
          currentWords.shuffle();
          currentWordIndex = 0;
          _speakCurrentWord();
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Uyarı'),
              content: Text('Yıldızlı kelime bulunmamaktadır.'),
              actions: [
                TextButton(
                  child: Text('Tamam'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
          showStarredOnly = false;
        }
      } else {
        _shuffleAndInitializeWords();
        _speakCurrentWord();
      }
    });
  }

  void _shuffleWords() {
    setState(() {
      currentWords.shuffle();
      currentWordIndex = 0;
      _speakCurrentWord();
    });
  }

  void _loadStarredStatusAsync() async {
    final service = StarredWordsService();
    final starredWordIds =
    await service.loadStarredWords(widget.classroomId, widget.studySetId);
    int newStarredCount = 0;

    setState(() {
      for (var word in widget.words) {
        bool isStarred = starredWordIds.contains(word.id);
        starredNotifiers[word.id] = ValueNotifier<bool>(isStarred);
        starredStatus[word.id] = isStarred;
        if (isStarred) newStarredCount++;
      }
    });
    starredWordCountNotifier.value = newStarredCount;
  }

  void _toggleStar(int wordId) {
    setState(() {
      final newStatus = !(starredStatus[wordId] ?? false);
      starredStatus[wordId] = newStatus;
      starredNotifiers[wordId]?.value = newStatus;
      if (newStatus) {
        starredWordCountNotifier.value++;
      } else {
        starredWordCountNotifier.value--;
      }
    });
    StarredWordsService().toggleWordStarStatus(
        wordId, starredStatus[wordId]!, widget.classroomId, widget.studySetId);
  }

  @override
  Widget build(BuildContext context) {
    String fullImageUrl = widget.words[currentWordIndex].image != null
        ? "https://cloud.phdakademi.com/uploads/kelibu.net/${widget.words[currentWordIndex].image}"
        : "https://kelibu.net/images/defaultimage.png";

    return Scaffold(
      backgroundColor:
      _isDarkMode ? darkModeColors["background"] : Colors.grey[100],
      appBar: AppBar(
        backgroundColor:
        _isDarkMode ? darkModeColors["cardBackground"] : Colors.white,
        elevation: 0,
        title: Text(
          'Dinle',
          style: GoogleFonts.poppins(
            color: _isDarkMode ? darkModeColors["text"] : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          _buildStarredWordsButton(),
          IconButton(
            icon: Icon(isVirtualKeyboardVisible
                ? Icons.keyboard_hide
                : Icons.keyboard),
            onPressed: _toggleVirtualKeyboard,
          ),
          IconButton(
            icon: Icon(isMenuVisible ? Icons.menu_open : Icons.menu),
            onPressed: () => setState(() => isMenuVisible = !isMenuVisible),
          ),
          _buildRoundedIconButton(Icons.slow_motion_video_sharp, Colors.green, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      VideoPlayerScreen(videoUrl: AppUrls.listenandwrite)),
            );
          }),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (isMenuVisible) _buildControlPanel(),
              _buildProgressAndPoints(),
              SizedBox(height: 20),
              _buildWordCard(fullImageUrl),
              SizedBox(height: 20),
              _buildLetterBoxes(),
              SizedBox(height: 20),
              _buildInputField(),
              SizedBox(height: 20),
              _buildSubmitButton(),
              SizedBox(height: 20),
              if (isVirtualKeyboardVisible) _buildKeyboard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundedIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: onPressed,
        child: Image.asset('assets/videoplayer.png', width: 40.sp, height: 40.sp),
      ),
    );
  }

  Widget _buildLetterBoxes() {
    if (correctWord.isEmpty) return SizedBox();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: List.generate(correctWord.length, (index) {
        if (enteredLetters.length != correctWord.length) {
          enteredLetters = List.filled(correctWord.length, '');
        }
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            border: Border.all(
                color: _isDarkMode ? darkModeColors["text"]! : Colors.grey),
            borderRadius: BorderRadius.circular(5),
            color: enteredLetters[index].isNotEmpty
                ? (_isDarkMode
                ? darkModeColors["buttonBackground"]
                : Colors.blue.shade100)
                : Colors.transparent,
          ),
          child: Center(
            child: Text(
              enteredLetters[index],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? darkModeColors["text"] : Colors.black,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInputField() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? [Color(0xFF34495E), Color(0xFF2C3E50)]
              : [Color(0xFFCFDEF3), Color(0xFFE0EAFC)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 5),
        ],
      ),
      child: TextField(
        controller: textEditingController,
        decoration: InputDecoration(
          labelText: 'Kelimeyi yazın',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.lightbulb_outline,
                color: _isDarkMode ? Colors.tealAccent[700] : Colors.indigo),
            onPressed: _getHint,
          ),
          labelStyle: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.indigo[800]),
          fillColor: _isDarkMode ? Color(0xFF2C3E50) : Colors.white,
          filled: true,
        ),
        style: TextStyle(color: _isDarkMode ? Colors.white : Colors.indigo[800]),
      ),
    );
  }

  Widget _buildStarredWordsButton() {
    return GestureDetector(
      onTap: toggleStarredOnly,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              showStarredOnly ? Icons.star : Icons.star_border,
              color: showStarredOnly
                  ? Colors.amber
                  : _isDarkMode ? darkModeColors["text"] : Colors.black,
              size: 20,
            ),
            const SizedBox(width: 4),
            ValueListenableBuilder<int>(
              valueListenable: starredWordCountNotifier,
              builder: (context, count, child) {
                return Text(
                  '$count',
                  style: GoogleFonts.lato(
                    color: _isDarkMode ? darkModeColors["text"] : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProgressAndPoints() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? [Color(0xFF34495E), Color(0xFF2C3E50)]
              : [Color(0xFFCFDEF3), Color(0xFFE0EAFC)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 5),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İlerleme',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                LinearProgressIndicator(
                  value: (currentWordIndex + 1) / widget.words.length,
                  backgroundColor: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _isDarkMode ? Colors.tealAccent[700]! : Colors.indigo),
                ),
                SizedBox(height: 5),
                Text(
                  '${currentWordIndex + 1} / ${widget.words.length}',
                  style: TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
                ),
              ],
            ),
          ),
          SizedBox(width: 20),
          // ✅ Riverpod ScoreDisplay - parametre almıyor, pointsProvider'dan okuyor
          ScoreDisplay(),
        ],
      ),
    );
  }

  Widget _buildWordCard(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? [Color(0xFF2C3E50), Color(0xFF34495E)]
              : [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 5),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 5),
                ],
              ),
              child: ClipOval(
                child: FadeTransition(
                  opacity: _animation,
                  child: Image.network(
                    imageUrl,
                    width: 180,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, exception, stackTrace) {
                      return Image.asset('assets/logo.png', width: 180, height: 180, fit: BoxFit.cover);
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 25),
            Text(
              'Dinlediğiniz Kelimeyi Yazınız',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.indigo[800],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.volume_up, size: 24),
                  label: Text("Tekrar Dinle",
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  onPressed: () => _speak(correctWord),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _isDarkMode ? Colors.tealAccent[700] : Colors.indigo,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                  ),
                ),
                SizedBox(width: 20),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  child: IconButton(
                    icon: Icon(
                      starredStatus[widget.words[currentWordIndex].id] ?? false
                          ? Icons.star
                          : Icons.star_border,
                      color: starredStatus[widget.words[currentWordIndex].id] ?? false
                          ? Colors.amber
                          : Colors.grey[400],
                      size: 36,
                    ),
                    onPressed: () => _toggleStar(widget.words[currentWordIndex].id),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _checkAnswer,
      icon: Icon(Icons.check),
      label: Text('Kontrol Et'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _isDarkMode ? Colors.tealAccent[700] : Colors.indigo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        elevation: 5,
      ),
    );
  }

  Widget _buildKeyboard() {
    const List<String> letters = [
      'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P',
      'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L',
      'Z', 'X', 'C', 'V', 'B', 'N', 'M', ' '
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 5,
      runSpacing: 5,
      children: letters.map((letter) => _buildKeyboardButton(letter)).toList(),
    );
  }

  Widget _buildKeyboardButton(String letter) {
    return ElevatedButton(
      child: Text(letter == ' ' ? 'Space' : letter),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _isDarkMode ? darkModeColors["buttonBackground"] : Colors.blue,
        padding: EdgeInsets.all(10),
        minimumSize: Size(40, 40),
      ),
      onPressed: () {
        setState(() {
          textEditingController.text += letter == ' ' ? ' ' : letter;
        });
      },
    );
  }

  Widget _buildControlPanel() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _isDarkMode ? darkModeColors["cardBackground"] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(icon: Icon(Icons.shuffle), onPressed: _shuffleWords),
          IconButton(icon: Icon(Icons.skip_next), onPressed: _proceedToNextWord),
        ],
      ),
    );
  }
}