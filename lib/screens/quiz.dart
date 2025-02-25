import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kelibu/Models/wordDetaik.dart';
import 'dart:math';
import 'dart:async';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/providers/language_provider.dart';
import 'package:kelibu/screens/home_screen_widgets/home_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:kelibu/screens/loadingIndicator.dart';
import 'package:kelibu/screens/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../globalDart/urls.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../providers/volume_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import '../variables.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:auto_size_text/auto_size_text.dart';


class ScoreDisplay extends StatefulWidget {
  final ValueNotifier<int> userPointsNotifier;

  const ScoreDisplay({Key? key, required this.userPointsNotifier}) : super(key: key);

  @override
  _ScoreDisplayState createState() => _ScoreDisplayState();
}

class _ScoreDisplayState extends State<ScoreDisplay> with TickerProviderStateMixin {
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _colorController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.green,
      end: Colors.transparent,
    ).animate(_colorController);

    widget.userPointsNotifier.addListener(_onScoreChanged);
  }

  void _onScoreChanged() {
    _colorController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _colorController.dispose();
    widget.userPointsNotifier.removeListener(_onScoreChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final borderColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];

    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _colorAnimation.value ?? Colors.transparent,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/trophy.svg',
                width: 40,
                height: 40,
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<int>(
                valueListenable: widget.userPointsNotifier,
                builder: (context, value, child) {
                  return Text(
                    "$value",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }}

class ExampleSentenceContent extends StatelessWidget {
  final QuizQuestion question;
  final Function(String) onListen;

  const ExampleSentenceContent({
    Key? key,
    required this.question,
    required this.onListen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Örnek Cümleler',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () => _showInfoDialog(context),
            ),
          ],
        ),
        SizedBox(height: 20),
        Container(
          height: 300,
          child: FutureBuilder<List<String>>(
            future: _fetchSentenceForTerm(question.term),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Colors.teal));
              } else if (snapshot.hasError) {
                return Text('Hata oluştu: ${snapshot.error}', style: TextStyle(color: Colors.red));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('Örnek cümle bulunamadı.', style: TextStyle(color: Colors.grey));
              } else {
                return PageView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return ExampleSentenceCard(
                      sentence: snapshot.data![index],
                      highlightWord: question.term,
                      onListen: () => onListen(snapshot.data![index]),
                    );
                  },
                );
              }
            },
          ),
        ),
        SizedBox(height: 20),
        Align(
          alignment: Alignment.bottomRight,
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Kapat',
              style: TextStyle(fontSize: 18, color: Colors.teal),
            ),
          ),
        ),
      ],
    );
  }

  Future<List<String>> _fetchSentenceForTerm(String term) async {
    try {
      var response = await ApiService().fetchExampleSentences(term);
      if (response.isNotEmpty) {
        return response.map<String>((item) => item['cumle'].toString()).toList();
      } else {
        return ["Cümle bulunamadı"];
      }
    } catch (e) {
      print('Hata: $e');
      return ["Cümle yüklenemedi"];
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: ContentBox(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Örnek Cümleler Hakkında',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 15),
                Text(
                  'Örnek cümleleri oluştururken karşılaşılabilecek durumlar:',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                bulletPoint('Kelimenin farklı anlamda kullanılması'),
                bulletPoint('Benzer kelimelerin karışması (tent/tenth)'),
                SizedBox(height: 15),
                Text(
                  'Bu durumlar, kelimelerin türemiş hallerini görebilmeniz için tercih edilmiştir.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  'Anlayışınız için teşekkür ederiz.',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 10),
                Text(
                  'PhD Akademi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Anladım',
                      style: TextStyle(fontSize: 18, color: Colors.teal),
                    ),
                  ),
                ),
              ],
            ),
            icon: Icons.info_outline,
          ),
        );
      },
    );
  }

  Widget bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('• ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class QuizCard extends StatefulWidget {
  final String question;
  final Duration duration;
  final int currentQuestionIndex; // Add this line

  const QuizCard({
    Key? key,
    required this.question,
    this.duration = const Duration(seconds: 1),
    required this.currentQuestionIndex, // Add this line
  }) : super(key: key);
  @override
  _QuizCardState createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  double _opacity = 0.0;
  final AudioPlayer audioPlayer = AudioPlayer();
  Future<void> playSound(String path) async {
    await audioPlayer.play(AssetSource(path));
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: widget.duration,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.question,
            style: TextStyle(
              fontSize: 2, // Dinamik font boyutu
            ),
          ),
        ),
      ),
    );
  }
}
class QuizScreen extends StatefulWidget {
  final int classroomId;
  final int studySetId;
  final List<WordDetail> words;
  final bool isStarredMode; // Yeni eklenen parametre

  const QuizScreen({
    Key? key,
    required this.words,
    required this.classroomId,
    required this.studySetId,
    this.isStarredMode = false, // Varsayılan değer false olarak ayarlandı
  }) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int jokerCount = 3;
  bool isFiftyFiftyUsed = false;
  bool isDoubleAnswerUsed = false;
  bool isTimeExtensionUsed = false;
  int currentQuestionIndex = 0;
  bool isWordSoundOn = true;
  bool isCorrectSoundOn = true;
  late VolumeProvider volumeProvider;
  PageController _pageController = PageController();
  final ScrollController _navBarScrollController = ScrollController();
  ValueNotifier<bool> isRefreshOn = ValueNotifier(true);
  ValueNotifier<bool> isMuteOn = ValueNotifier(true);
  ValueNotifier<bool> isSortOn = ValueNotifier(true);
  ValueNotifier<bool> refresh_off = ValueNotifier(true);
  ValueNotifier<bool> isTurkish = ValueNotifier(true);
  ValueNotifier<int> starredWordCountNotifier = ValueNotifier(0);
  bool _isDarkMode = false; // Dark mode durumu
  ValueNotifier<int> pointValueNotifier = ValueNotifier(0);
  bool isMenuVisible = true;


  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    _showExitConfirmationDialog();
    return true;
  }

  void _showExitConfirmationDialog() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çıkmak istediğinize emin misiniz?'),
        content: Text("Bu işlem geri alınamaz."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hayır'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Evet'),
          ),
        ],
      ),
    ).then((value) => value ?? false ? Navigator.of(context).pop(true) : null);
  }

  Map<int, bool?> questionStatuses = {};

  int _pausedTime = 0;
  int score = 0;
  ValueNotifier<Color> backgroundColorNotifier = ValueNotifier(Colors.blue);
  Widget _buildJokerButton() {
    return GestureDetector(
      onTap: _showJokerOptions,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  void _showJokerOptions() {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: colors['cardBackground'],
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 40,
                margin: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: colors['unselectedText'],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Text(
                'Joker Seçenekleri',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors['text'],
                ),
              ),
              SizedBox(height: 20),
              _buildJokerOption(
                icon: Icons.content_cut,
                title: '50/50',
                subtitle: 'İki yanlış şıkkı kaldır',
                color: Colors.blue,
                isEnabled: !isFiftyFiftyUsed,
                onTap: () {
                  _useFiftyFifty();
                  if (!isFiftyFiftyUsed) Navigator.pop(context);
                },
              ),
              _buildJokerOption(
                icon: Icons.replay,
                title: 'Çifte Cevap',
                subtitle: 'İki kez cevaplama hakkı',
                color: Colors.green,
                isEnabled: !isDoubleAnswerUsed,
                onTap: () {
                  _useDoubleAnswer();
                  if (!isDoubleAnswerUsed) Navigator.pop(context);
                },
              ),
              _buildJokerOption(
                icon: Icons.timer,
                title: 'Süre Uzatma',
                subtitle: '15 saniye ekle',
                color: Colors.orange,
                isEnabled: !isTimeExtensionUsed,
                onTap: () {
                  _useTimeExtension();
                  if (!isTimeExtensionUsed) Navigator.pop(context);
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJokerOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: ListTile(
        enabled: isEnabled,
        onTap: isEnabled ? onTap : null,
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: colors['text'],
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: colors['unselectedText'],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: isEnabled ? colors['iconColor'] : colors['unselectedText'],
          size: 16,
        ),
      ),
    );
  }

  void _useFiftyFifty() {
    if (!isFiftyFiftyUsed) {
      setState(() {
        isFiftyFiftyUsed = true;
        var currentQuestion = questions[currentQuestionIndex];
        var wrongOptions = currentQuestion.options.where((option) =>
        currentQuestion.options.indexOf(option) != currentQuestion.correctOptionIndex).toList();
        wrongOptions.shuffle();
        wrongOptions.take(2).forEach((wrongOption) {
          currentQuestion.options.remove(wrongOption);
        });
      });
      Navigator.pop(context); // Bottom sheet'i kapat
      showCustomFlushbar(context, "50/50 jokeri kullanıldı!");
    } else {
      showCustomFlushbar(context, "50/50 jokeri zaten kullanıldı!");
    }
  }
  void _useTimeExtension() {
    if (!isTimeExtensionUsed) {
      setState(() {
        isTimeExtensionUsed = true;
        _remainingTime += 15;
      });
      Navigator.pop(context); // Joker menüsünü kapat
      showCustomFlushbar(context, "Süre 15 saniye uzatıldı!");
    } else {
      showCustomFlushbar(context, "Süre uzatma jokeri zaten kullanıldı!");
    }
  }
  Future<void> playSoundCorrect(String path) async {
    final volumeProvider = Provider.of<VolumeProvider>(context, listen: false);
    if (volumeProvider.isVolumeOn && isCorrectSoundOn) { // Ana ses ve doğru/yanlış sesi kontrolü
      AudioPlayer audioPlayer = AudioPlayer();
      await audioPlayer.setVolume(0.1);

      if (!kIsWeb) {
        ByteData data = await rootBundle.load(path);
        Uint8List bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        String dir = (await getTemporaryDirectory()).path;
        File tempFile = File('$dir/tempSound.wav');
        await tempFile.writeAsBytes(bytes, flush: true);
        await audioPlayer.play(DeviceFileSource(tempFile.path));
      } else {
        ByteData data = await rootBundle.load(path);
        Uint8List bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await audioPlayer.play(BytesSource(bytes));
      }
    }
  }
  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
      colors = _isDarkMode ? darkModeColors : lightModeColors;
    });
  }
  bool showStarredOnly = false;

  void resetQuiz() {
    setState(() {
      for (var question in questions) {
        question.userAnswer = null;
        questionStatuses[question.id] = null;
      }
      currentQuestionIndex = 0;
      _timer?.cancel();
      startTimer();
    });
  }
  void _showSoundSettingsPanel() {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer<VolumeProvider>(
              builder: (context, volumeProvider, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: colors['cardBackground'],
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 5,
                        width: 40,
                        margin: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: colors['unselectedText'],
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      Text(
                        'Ses Ayarları',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colors['text'],
                        ),
                      ),
                      SizedBox(height: 20),
                      // Ana ses ayarı
                      _buildSoundToggle(
                        icon: Icons.volume_up,
                        title: 'Ana Ses',
                        isOn: volumeProvider.isVolumeOn,
                        onChanged: (value) {
                          volumeProvider.toggleVolume();
                          if (!volumeProvider.isVolumeOn) {
                            // Ana ses kapatıldığında diğer sesleri de kapat
                            setModalState(() {
                              isWordSoundOn = false;
                              isCorrectSoundOn = false;
                            });
                          }
                        },
                      ),
                      // Kelime sesi ayarı
                      _buildSoundToggle(
                        icon: Icons.record_voice_over,
                        title: 'Kelime Sesi',
                        isOn: volumeProvider.isVolumeOn && isWordSoundOn,
                        onChanged: (value) {
                          if (!volumeProvider.isVolumeOn) {
                            showCustomFlushbar(context, "Önce ana sesi açmanız gerekiyor");
                            return;
                          }
                          setModalState(() => isWordSoundOn = value);
                        },
                      ),
                      // Doğru/yanlış sesi ayarı
                      _buildSoundToggle(
                        icon: Icons.check_circle_outline,
                        title: 'Doğru/Yanlış Sesi',
                        isOn: volumeProvider.isVolumeOn && isCorrectSoundOn,
                        onChanged: (value) {
                          if (!volumeProvider.isVolumeOn) {
                            showCustomFlushbar(context, "Önce ana sesi açmanız gerekiyor");
                            return;
                          }
                          setModalState(() => isCorrectSoundOn = value);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  Widget _buildSoundToggle({
    required IconData icon,
    required String title,
    required bool isOn,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors['buttonBackground']!.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors['buttonBackground']),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colors['text'],
              ),
            ),
          ),
          Switch.adaptive(
            value: isOn,
            onChanged: onChanged,
            activeColor: colors['buttonBackground'],
          ),
        ],
      ),
    );
  }
  bool doubleAnswerActive = false;
  void _useDoubleAnswer() {
    setState(() {
      if (!isDoubleAnswerUsed) {
        isDoubleAnswerUsed = true;
        doubleAnswerActive = true;
        Navigator.pop(context); // Joker menüsünü kapat
        showCustomFlushbar(context, "Çifte cevap hakkı aktif!");
      } else {
        showCustomFlushbar(context, "Çifte cevap jokeri zaten kullanıldı!");
      }
    });
  }  void toggleStarredOnly() {
    setState(() {
      resetOptionColors();
      showStarredOnly = !showStarredOnly;
      backgroundColorNotifier.value = showStarredOnly ? Colors.green : Colors.blue;
      showCustomFlushbar(context, showStarredOnly ? "Yıldızlı kelimeler modu açıldı." : "Yıldızlı kelimeler modu kapandı");
      if (showStarredOnly) {
        var filteredQuestions = questions.where((q) => starredStatus[q.id] ?? false).toList();
        if (filteredQuestions.isNotEmpty) {
          questions = filteredQuestions;
          resetQuiz();
        }
      } else {
        _initializeQuiz();
        resetQuiz();
      }
      _pageController.jumpToPage(currentQuestionIndex);
    });
  }

  final AudioPlayer audioPlayer = AudioPlayer();
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;

  Future<void> playSound(String path) async {
    await audioPlayer.play(AssetSource(path));
  }

  late List<QuizQuestion> questions = [];

  Map<int, bool> starredWords = {};
  ValueNotifier<int> starredWordCount = ValueNotifier(0);
  bool isStarred = false;
  bool _isBottomSheetOpen = false;
  Map<int, ValueNotifier<bool>> starredNotifiers = {};
  Map<int, bool> starredStatus = {};
  int userID = 2;
  bool isShuffled = false;

  ValueNotifier<int> animatedStarredCount = ValueNotifier(0);
  Map<int, Color> optionColors = {};
  QuizQuestion get currentQuestion => questions[currentQuestionIndex];
  ValueNotifier<bool> isVisibilityOn = ValueNotifier(true);
  Timer? _timer;
  int _remainingTime = 15;
  bool isStarredMode = false;

  ValueNotifier<bool> get isStarredNotifier {
    if (questions.isEmpty) {
      return ValueNotifier(false);
    }
    int questionId = questions[currentQuestionIndex].id;
    return starredNotifiers[questionId] ?? ValueNotifier(false);
  }
  Future<void> _speakWord(String word) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(word);
  }
// _speak fonksiyonunu tamamen güncelleyin
  _speak() async {
    final volumeProvider = Provider.of<VolumeProvider>(context, listen: false);

    if (!isSpeaking && volumeProvider.isVolumeOn && isTurkish.value && isWordSoundOn) {
      isSpeaking = true;
      String wordToSpeak = questions[currentQuestionIndex].term;
      print(wordToSpeak);
      await flutterTts.setLanguage("en-US");
      await flutterTts.awaitSpeakCompletion(true);
      await flutterTts.speak(wordToSpeak);
      isSpeaking = false;
    }
  }
  Widget _buildTimerWidget() {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors["background"],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              value: _remainingTime / 15,
              strokeWidth: 5,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _remainingTime > 5 ? Colors.green : Colors.red,
              ),
            ),
          ),
          Text(
            '$_remainingTime',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors["text"],
            ),
          ),
        ],
      ),
    );
  }
  void _scrollToSelectedQuestion() {
    if (_navBarScrollController.hasClients) {
      double selectedQuestionOffset = currentQuestionIndex * 50.0;
      _navBarScrollController.animateTo(
        selectedQuestionOffset,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }


  void startTimer({bool resumeFromPausedTime = false}) {
    _timer?.cancel();
    if (resumeFromPausedTime) {
      _remainingTime = _pausedTime;
    } else {
      _remainingTime = 15;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_remainingTime == 0) {
        _timer?.cancel();
        if (!isReviewingQuestion) {
          _showCorrectAnswerAndGoToNextQuestion();
        }
      } else {
        setState(() {
          _remainingTime--;
        });
      }
    });
  }

  void _shuffleOrSortWords() {
    setState(() {
      if (isShuffled) {
        questions.shuffle();
      } else {
        questions.sort((a, b) => a.id.compareTo(b.id));
      }
      currentQuestionIndex = 0;
      _pageController.jumpToPage(0);
    });
  }

  void _changeLang() {
    setState(() {
      isTurkish.value = !isTurkish.value;
      _initializeQuiz();
    });
  }
  late Map<String, Color> colors;

  void _initializeQuiz() async {
    var sortedWords = List<WordDetail>.from(widget.words)..shuffle();
    var generatedQuestions = await generateQuizQuestions(sortedWords, isTurkish);

    if (mounted) {
      setState(() {
        questions = generatedQuestions;
        currentQuestionIndex = 0;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }
  }
  Future<void> _updateUserScore(int newScore) async {
    try {
      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      int currentPoints = userProvider.point;

      print("Updating score - UserID: $userID, Current Points: $currentPoints, New Score: $newScore");

      // Yeni puan 1 veya daha azsa, mevcut puanı koru
      if (newScore <= 1) {
        print("New score is <= 1. Keeping current points.");
        newScore = currentPoints;
      }

      // Puan düşüşü kontrolü
      if (newScore < currentPoints) {
        print("Warning: New score ($newScore) is less than current points ($currentPoints).");
      }

      // API çağrısı ve local state güncellemesi
      await Future.wait([
        ApiService().updateUserPointTimePeriod(userID, newScore, newScore - currentPoints),
        userProvider.addPoint(newScore),
      ]);

      setState(() {
        score = newScore;
        pointValueNotifier.value = newScore;
      });

      print("Score updated successfully. New score: $newScore");
    } catch (e) {
      print("Error updating user score: $e");
    }
  }
  @override
  void initState() {
    super.initState();
    ApiService().logSetEntry('Öğren modu', 'Öğren moduna ', '');

    _loadStarredStatusAsync();
    _loadDarkModePreference().then((_) {
      setState(() {
        colors = _isDarkMode ? darkModeColors : lightModeColors;
      });
    });
    isStarredMode = widget.isStarredMode;

    pointValueNotifier.value = score;
    Future.microtask(() {
      UserProvider userProviderPoint = Provider.of<UserProvider>(context, listen: false);
      setState(() {
        score = userProviderPoint.point;
        pointValueNotifier.value = score;
      });
    });
    Future.microtask(() {
      volumeProvider = Provider.of<VolumeProvider>(context, listen: false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      setState(() {
        userID = userProvider.userId;
      });
      _pageController = PageController(initialPage: 0);
      _pageController.addListener(() {
        if (_pageController.page?.round() == _pageController.page) {
          _speak();
        }
      });

        UserProvider userProviderPoint = Provider.of<UserProvider>(context, listen: false);
      print(userProviderPoint.point);
      score = (userProviderPoint.point);
      _initializeQuiz();
      resetOptionColors();
      startTimer();

      _loadStarredStatusAsync();
    });
  }

  void finishQuiz() async {
    int finalScore = score;
    try {
      await _updateUserScore(finalScore);
      print('Quiz finished. Final score: $finalScore');
    } catch (e) {
      print('Error updating final score: $e');
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => QuizResultsScreen(questions: questions),
    ));
    _timer?.cancel();
  }
  void _updateStarredWordCount(ValueNotifier<bool> isStarredNotifier) {
    int newCount = starredWordCountNotifier.value;
    if (isStarredNotifier.value) {
      newCount = starredWordCountNotifier.value + 1;
    } else {
      if (newCount > 0) {
        newCount = starredWordCountNotifier.value - 1;
      }
    }
    starredWordCountNotifier.value = newCount;
  }
  int _currentHighlightIndex = -1;
  bool _isReading = false;

  Widget _buildControlPanel(Map<String, Color> colors, BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: isMenuVisible ? 80 : 0,
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colors["borderColor"],
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _buildControlButton(
                  isVisibilityOn.value ? Icons.visibility : Icons.visibility_off,
                  colors["inputBackground"]!,
                      () {
                    setState(() {
                      isVisibilityOn.value = !isVisibilityOn.value;
                    });
                    showCustomFlushbar(
                      context,
                      isVisibilityOn.value ? "Resim açıldı" : "Resim kapandı",
                    );
                  }
              ),
              _buildControlButton(
                  isShuffled ? Icons.sort : Icons.shuffle,
                  colors["inputBackground"]!,
                      () {
                    setState(() {
                      isShuffled = !isShuffled;
                      _shuffleOrSortWords();
                    });
                  }
              ),
              Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  return _buildControlButton(
                    languageProvider.isEnglish ? Icons.language : Icons.translate,
                    colors["inputBackground"]!,
                        () {
                      setState(() {
                        languageProvider.toggleLanguage();
                        _changeLang();
                      });
                    },
                  );
                },
              ),
              // Ses kontrolü için Consumer ekliyoruz
              Consumer<VolumeProvider>(
                builder: (context, volumeProvider, child) {
                  return _buildControlButton(
                      volumeProvider.isVolumeOn ? Icons.volume_up : Icons.volume_off,
                      colors["inputBackground"]!,
                      _showSoundSettingsPanel
                  );
                },
              ),
              _buildControlButton(
                  Icons.hearing,
                  colors["inputBackground"]!,
                  _speak
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildControlButton(IconData icon, Color color, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: onPressed,
    );
  }

  void _toggleMenu() {
    setState(() {
      isMenuVisible = !isMenuVisible;
    });
  }

  Widget _buildStarredWordsButton() {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    return GestureDetector(
      onTap: toggleStarredOnly,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              showStarredOnly ? Icons.star : Icons.star_border,
              color: showStarredOnly ? Colors.amber : colors["text"],
              size: 20,
            ),
            const SizedBox(width: 4),
            ValueListenableBuilder<int>(
              valueListenable: starredWordCountNotifier,
              builder: (context, count, child) {
                return Text(
                  '$count',
                  style: GoogleFonts.lato(
                    color: colors["text"],
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

  Future<List<String>> _fetchSentenceForTerm(String term) async {
    try {
      var response = await ApiService().fetchExampleSentences(term);
      if (response.isNotEmpty) {
        return response.map<String>((item) => item['cumle'].toString()).toList();
      } else {
        return ["Cümle bulunamadı"];
      }
    } catch (e) {
      print('Hata: $e');
      return ["Cümle yüklenemedi"];
    }
  }

  void _showCorrectAnswerAndGoToNextQuestion() {
    var correctIndex = questions[currentQuestionIndex].correctOptionIndex;
    setState(() {
      optionColors[correctIndex] = const Color(0xFF4CA64C);
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          resetOptionColors();
          startTimer();
        });
        _pageController.animateToPage(
          currentQuestionIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        finishQuiz();
      }
    });
  }

  void _toggleStar(int wordId, ValueNotifier<bool> isStarredNotifier) async {
    final service = StarredWordsService();
    final newStatus = !isStarredNotifier.value;

    await service.toggleWordStarStatus(wordId, newStatus, widget.classroomId, widget.studySetId);

    setState(() {
      isStarredNotifier.value = newStatus;
      starredStatus[wordId] = newStatus;
      _recalculateStarredWordCount();
    });
  }

  void _recalculateStarredWordCount() {
    int count = starredStatus.values.where((isStarred) => isStarred).length;
    starredWordCountNotifier.value = count;
  }

  @override
  void dispose() async {
    _timer?.cancel();
    audioPlayer.dispose(); // AudioPlayer'ı temizle

    // FlutterTts'i durdur
    if (isSpeaking) {
      await flutterTts.stop();
    }

    _navBarScrollController.dispose();
    super.dispose();
  }
  void resetOptionColors() {
    optionColors = {for (var item in List.generate(4, (index) => index)) item: Colors.white};
  }

  void _answerQuestion(int selectedIndex) {
    var correctIndex = questions[currentQuestionIndex].correctOptionIndex;
    bool isCorrect = selectedIndex == correctIndex;

    if (!isCorrect && doubleAnswerActive) {
      doubleAnswerActive = false;
      showCustomFlushbar(context, "Yanlış cevap! İkinci şansınızı kullanın.");
      return;
    }

    questions[currentQuestionIndex].userAnswer = selectedIndex;
    int timeTaken = 15 - _remainingTime;
    int pointChange = isCorrect ? 5 + (15 - timeTaken) : -2;
    int newScore = score + pointChange;

    questionStatuses[currentQuestionIndex] = isCorrect;
    _updateUserScore(newScore);

    setState(() {
      optionColors[selectedIndex] = isCorrect ? const Color(0xFF4CA64C) : const Color(0xFFFF4C4C);
      if (!isCorrect) {
        optionColors[correctIndex] = const Color(0xFF4CA64C);
      }
    });

    if (isCorrect) {
      playSoundCorrect('assets/correct.wav');
    } else {
      playSoundCorrect('assets/wrong.wav');
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          resetOptionColors();
          startTimer();
        });
        _pageController.animateToPage(
          currentQuestionIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        finishQuiz();
      }
    });
  }
  Widget _buildAnswerPanel() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          final isAnswered = question.userAnswer != null;
          final isCorrect = question.isAnsweredCorrectly;

          return GestureDetector(
            onTap: () => _showQuestionReview(index),
            child: Container(
              width: 50,
              margin: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: isAnswered
                    ? (isCorrect ? Colors.green : Colors.red)
                    : Colors.grey,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool isReviewingQuestion = false;

  Widget _buildAnswerHistoryButton() {
    return IconButton(
      icon: Icon(Icons.history, color: colors["text"]),
      onPressed: _showAnswerHistory,
    );
  }

  void _showAnswerHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.2,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: colors["background"],
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    height: 5,
                    width: 40,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: colors["text"]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      "Cevap Geçmişim",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colors["text"],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: currentQuestionIndex + 1,
                      itemBuilder: (context, index) {
                        final question = questions[index];
                        final isAnswered = question.userAnswer != null;
                        final isCorrect = question.isAnsweredCorrectly;
                        final isCurrent = index == currentQuestionIndex;

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: isCurrent ? BorderSide(color: colors["text"]!, width: 2) : BorderSide.none,
                          ),
                          color: isCurrent ? colors["buttonBackground"]!.withOpacity(0.3) : colors["buttonBackground"],
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: () {
                              Navigator.pop(context);
                              _showQuestionReview(index);
                            },
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor: isAnswered
                                        ? (isCorrect ? Colors.green : Colors.red)
                                        : Colors.grey,
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          question.term,
                                          style: GoogleFonts.poppins(
                                            color: colors["text"],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (isAnswered)
                                          Text(
                                            isCorrect ? "Doğru" : "Yanlış",
                                            style: GoogleFonts.poppins(
                                              color: isCorrect ? Colors.green : Colors.red,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: colors["text"],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showQuestionReview(int index) {
    if (index > currentQuestionIndex) return; // Gelecek soruları gösterme

    isReviewingQuestion = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        return Container(
          height: size.height * 0.9,
          decoration: BoxDecoration(
            color: colors["background"],
            borderRadius: BorderRadius.vertical(top: Radius.circular(size.width * 0.05)),
          ),
          child: Column(
            children: [
              Container(
                height: size.height * 0.005,
                width: size.width * 0.1,
                margin: EdgeInsets.symmetric(vertical: size.height * 0.015),
                decoration: BoxDecoration(
                  color: colors["text"]!.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(size.height * 0.0025),
                ),
              ),
              Expanded(
                child: _buildQuestionContent(questions[index], size),
              ),
              Padding(
                  padding: EdgeInsets.all(size.width * 0.05),
                  child: ElevatedButton(
                    child: Text(
                      'Quize Dön',
                      style: GoogleFonts.poppins(
                        fontSize: size.width * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors["buttonBackground"],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(size.width * 0.08),
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.08,
                          vertical: size.height * 0.02
                      ),
                    ),
                    onPressed: () {
                      isReviewingQuestion = false;
                      Navigator.pop(context);
                    },
                  )
              ),
            ],
          ),
        );
      },
    );
  }
  void _loadStarredStatusAsync() async {
    final service = StarredWordsService();
    final starredWordIds = await service.loadStarredWords(widget.classroomId, widget.studySetId);
    print('Yüklenen yıldızlı kelimeler: $starredWordIds');
    int newStarredCount = 0;

    setState(() {
      for (var word in widget.words) {
        bool isStarred = starredWordIds.contains(word.id);
        starredNotifiers[word.id] = ValueNotifier<bool>(isStarred);
        starredStatus[word.id] = isStarred;
        if (isStarred) {
          newStarredCount++;
        }
      }
      _updateStarredWordCount(isStarredNotifier);
    });
    starredWordCountNotifier.value = newStarredCount;
  }


  Widget _buildQuestionContent(QuizQuestion question, Size size) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildQuestionHeader(question, size),
            SizedBox(height: size.height * 0.02),
            _buildImage(question.image, size),
            SizedBox(height: size.height * 0.02),
            ...List.generate(
              question.options.length,
                  (index) => Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.01),
                child: _buildOption(
                  question.options[index],
                  index,
                  question.correctOptionIndex,
                  question.userAnswer,
                  size,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }  Widget _buildQuestionHeader(QuizQuestion question, Size size) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.015,
            ),
            decoration: BoxDecoration(
              color: colors["buttonBackground"],
              borderRadius: BorderRadius.circular(size.width * 0.03),
            ),
            child: AutoSizeText(
              question.term,
              style: GoogleFonts.poppins(
                fontSize: size.width * 0.04,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              minFontSize: 10,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(width: size.width * 0.02),
        isStarredMode
            ? const SizedBox.shrink()
            : _buildStarIcon(question.id),
      ],
    );
  }
  Widget _buildStarIcon(int wordId) {
    return ValueListenableBuilder<bool>(
      valueListenable: starredNotifiers[wordId]!,
      builder: (context, isStarred, _) {
        return IconButton(
          icon: Icon(
            isStarred ? Icons.star : Icons.star_border,
            color: isStarred ? Colors.amber : Colors.grey,
            size: 30,
          ),
          onPressed: () {
            _toggleStar(wordId, starredNotifiers[wordId]!);
          },
        );
      },
    );
  }
  void _showExampleSentence() {
    if (questions.isNotEmpty) {
      final currentQuestion = questions[currentQuestionIndex];
      _showExampleSentenceDialog(currentQuestion);
    }
  }  void _speakAndHighlight(String sentence, String highlightWord, StateSetter setStateModal) async {


    await _speakSentence(sentence);  // Tüm cümleyi oku

  }

  void _showExampleSentenceDialog(QuizQuestion question) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: ContentBox(
            content: ExampleSentenceContent(
              question: question,
              onListen: (sentence) => _speakSentence(sentence),
            ),
            icon: Icons.menu_book,
          ),
        );
      },
    );
  }


  Future<void> _speakSentence(String sentence) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(sentence);
  }



  Widget _buildImage(String? imageUrl, Size size) {
    if (imageUrl == null) {
      return SizedBox();
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: isVisibilityOn.value ? 1.0 : 0.0,
      child: Container(
        height: size.height * 0.25,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size.width * 0.03),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size.width * 0.03),
          child: Image.network(
            'https://cloud.phdakademi.com/uploads/kelibu.net/$imageUrl',
            fit: BoxFit.fill,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(child: LogoLoadingIndicator());
            },
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildOption(String option, int index, int correctIndex, int? userAnswer, Size size) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    bool isSelected = userAnswer == index;
    bool isCorrect = index == correctIndex;
    Color bgColor = colors["buttonBackground"]!;
    Color textColor = colors["inputBackground"]!;

    if (userAnswer != null) {
      if (isSelected) {
        bgColor = isCorrect ? Colors.green : Colors.red;
        textColor = Colors.white;
      } else if (isCorrect) {
        bgColor = Colors.green;
        textColor = Colors.white;
      }
    }

    return GestureDetector(
      onTap: () {
        if (userAnswer == null) {
          _answerQuestion(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.015,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(size.width * 0.03),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              String.fromCharCode(65 + index),
              style: GoogleFonts.poppins(
                fontSize: size.width * 0.04,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: size.width * 0.03),
            Expanded(
              child: AutoSizeText(
                option,
                style: GoogleFonts.poppins(
                  fontSize: size.width * 0.035,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                minFontSize: 10,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int get totalCorrectAnswers {
    return questions.where((q) => q.isAnsweredCorrectly).length;
  }

  int get totalIncorrectAnswers {
    return questions.where((q) => q.userAnswer != null && !q.isAnsweredCorrectly).length;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: colors["background"],
        appBar: AppBar(
          title: Text('Öğren Modu'),
          backgroundColor: colors["buttonBackground"],
        ),
        body: _buildWarningWidget(),
      );
    }

    if (!hasEnoughWords()) {
      return Scaffold(
        backgroundColor: colors["background"],
        appBar: AppBar(
          title: Text('Öğren Modu'),
          backgroundColor: colors["buttonBackground"],
        ),
        body: Center(
          child: _buildWarningWidget(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: colors["background"],
      floatingActionButton: _buildJokerButton(),
      appBar: _buildAppBar(colors),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildInfoBar(colors),
            _buildControlPanel(colors, context),
            Expanded(
              child: _buildWordCards(size),
            ),
          ],
        ),
      ),
    );
  }
  PreferredSizeWidget _buildAppBar(Map<String, Color> colors) {
    return AppBar(
      backgroundColor: colors["background"],
      elevation: 0,
      title: Text(
        "Öğren Modu",
        style: GoogleFonts.poppins(
          color: colors["text"],
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.format_quote, color: colors["text"]),
          onPressed: () => _showExampleSentence(),
        ),
        _buildRoundedIconButton(Icons.slow_motion_video_sharp, Colors.green, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: AppUrls.learn)),
          );
        }),      ],
    );
  }
  Widget _buildRoundedIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: onPressed,
        child: Image.asset(
          'assets/videoplayer.png',
          width: 40.sp,
          height: 40.sp,
        ),
      ),
    );
  }
  Widget _buildInfoBar(Map<String, Color> colors) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: colors["background"],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStarredWordsButton(),
          Text(
            "${currentQuestionIndex + 1}/${questions.length}",
            style: GoogleFonts.poppins(
              color: colors["text"],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          _buildTimerWidget(),
          ScoreDisplay(userPointsNotifier: pointValueNotifier),
          _buildAnswerHistoryButton(),
          IconButton(
            icon: Icon(
              isMenuVisible ? Icons.menu_open : Icons.menu,
              color: colors["text"],
            ),
            onPressed: _toggleMenu,
          ),
        ],
      ),
    );
  }


  bool hasEnoughWords() {
    return questions.length >= 5;
  }
  Widget _buildWarningWidget() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 100,
            color: Colors.amber[800],
          ),
          SizedBox(height: 20),
          Text(
            'Ups! Kelimelerimiz Kaçmış!',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.amber[800],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Öğren modundan en yüksek verimi almanız için en az 5 yıldızlı kelime gerekiyor. Haydi, biraz daha kelime yıldızlayalım!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.amber[900],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildWordCards(Size size) {
    return PageView.builder(
      itemCount: questions.length,
      controller: _pageController,
      physics: NeverScrollableScrollPhysics(), // Kullanıcının kaydırmasını engelle
      onPageChanged: (index) {
        setState(() {
          currentQuestionIndex = index;
        });
        startTimer(); // Yeni soru için timer'ı başlat
        _speak(); // Burada çağrılıyor

        if (currentQuestionIndex == questions.length - 1) {
         // _showCompletionDialog();
        }
      },
      itemBuilder: (context, index) {
        return _buildQuestionContent(questions[index], size);
      },
    );
  }  Widget _buildQuestionNavigationBar() {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return SizedBox(
      height: 50,
      child: ListView.builder(
        controller: _navBarScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: questions.length,
        itemBuilder: (context, index) {
          Color? bgColor =colors["buttonBackground"];

          if (questionStatuses[index] != null) {
            bgColor = questionStatuses[index]! ? Colors.green : Colors.red;
          }

          if (index == currentQuestionIndex) {
            bgColor = Colors.pink;
          }

          Color textColor = bgColor == Colors.white ? Colors.black : Colors.white;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: textColor),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void showCustomFlushbar(BuildContext context, String message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Flushbar(
      messageText: Text(
        message,
        style: GoogleFonts.poppins(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Container(
        margin: const EdgeInsets.only(left: 8, right: 8),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          radius: 20,
          child: ClipOval(
            child: Image.asset(
              'assets/logo.png',
              width: 30,
              height: 30,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      duration: const Duration(seconds: 2),
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: isDarkMode ? Colors.grey[800]! : Colors.white,
      boxShadows: [
        BoxShadow(
          color: Colors.black12,
          offset: Offset(0, 3),
          blurRadius: 6,
        ),
      ],
      borderRadius: BorderRadius.circular(12),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      animationDuration: Duration(milliseconds: 400),
      forwardAnimationCurve: Curves.easeOutCirc,
      reverseAnimationCurve: Curves.easeInCirc,
      leftBarIndicatorColor: Colors.green,
    ).show(context);
  }
}

class QuizQuestion {
  int id;
  String term;
  List<String> options;
  int correctOptionIndex;
  String? image;
  WordDetail wordDetail;
  int? userAnswer;
  bool get isCorrect => userAnswer == correctOptionIndex;
  String correctAnswer;
  QuizQuestion({
    required this.id,
    required this.term,
    required this.options,
    required this.correctOptionIndex,
    required this.image,
    this.userAnswer,
    required this.wordDetail,
    required this.correctAnswer,
  });
  bool get isAnsweredCorrectly => userAnswer == correctOptionIndex;
}

Future<List<QuizQuestion>> generateQuizQuestions(List<WordDetail> words, ValueNotifier<bool> isLanguageTurkish) async {
  var random = Random();
  var questions = <QuizQuestion>[];

  if (words.length < 4) {
    // Yeterli kelime yoksa boş liste dön
    return questions;
  }

  for (var word in words) {
    Set<String> options = isLanguageTurkish.value ? {word.meaning} : {word.word};
    while (options.length < 4 && options.length < words.length) {
      var randomWord = words[random.nextInt(words.length)];
      options.add(isLanguageTurkish.value ? randomWord.meaning : randomWord.word);
    }

    if (options.length < 4) {
      // Yeterli şık oluşturulamadıysa bu soruyu atla
      continue;
    }

    var shuffledOptions = options.toList()..shuffle();
    int correctIndex = isLanguageTurkish.value ? shuffledOptions.indexOf(word.meaning) : shuffledOptions.indexOf(word.word);

    questions.add(QuizQuestion(
      id: word.id,
      term: isLanguageTurkish.value ? word.word : word.meaning,
      options: shuffledOptions,
      correctOptionIndex: correctIndex,
      image: word.image,
      wordDetail: word,
      correctAnswer: isLanguageTurkish.value ? word.meaning : word.word,
    ));
  }

  return questions;
}
class QuizResultsScreen extends StatefulWidget {
  final List<QuizQuestion> questions;

  const QuizResultsScreen({Key? key, required this.questions}) : super(key: key);

  @override
  _QuizResultsScreenState createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  bool showOnlyIncorrect = false;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    int correctAnswers = widget.questions.where((q) => q.isAnsweredCorrectly).length;
    int totalQuestions = widget.questions.length;
    double successRate = correctAnswers / totalQuestions;

    List<QuizQuestion> displayedQuestions = showOnlyIncorrect
        ? widget.questions.where((q) => !q.isAnsweredCorrectly).toList()
        : widget.questions;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Quiz Sonuçları',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: isDarkMode ? Colors.white : Colors.black),
            onPressed: _toggleDarkMode,
          ),
          IconButton(
            icon: Icon(Icons.home, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [Colors.blue.shade800, Colors.purple.shade800],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSuccessRateIndicator(successRate),
                const SizedBox(height: 32),
                _buildResultsSummary(correctAnswers, totalQuestions - correctAnswers),
                const SizedBox(height: 32),
                _buildResultsChart(correctAnswers, totalQuestions - correctAnswers),
                const SizedBox(height: 32),
                _buildIncorrectOnlySwitch(),
                const SizedBox(height: 16),
                Text('Soru Detayları',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                const SizedBox(height: 16),
                _buildQuestionsList(displayedQuestions),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessRateIndicator(double successRate) {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: CircularPercentIndicator(
          radius: 80.0,
          lineWidth: 15.0,
          percent: successRate,
          center: Text(
            '${(successRate * 100).toStringAsFixed(1)}%',
            style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
          ),
          progressColor: Colors.greenAccent,
          backgroundColor: isDarkMode ? Colors.white24 : Colors.black12,
          circularStrokeCap: CircularStrokeCap.round,
          animation: true,
          animationDuration: 1500,
        ),
      ),
    );
  }

  Widget _buildResultsSummary(int correct, int incorrect) {
    return Column(
      children: [
        _buildResultBar('Doğru', correct, widget.questions.length, Colors.greenAccent),
        const SizedBox(height: 16),
        _buildResultBar('Yanlış', incorrect, widget.questions.length, Colors.redAccent),
      ],
    );
  }

  Widget _buildResultBar(String label, int count, int total, Color color) {
    double percentage = count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.black54)),
        const SizedBox(height: 8),
        Container(
          height: 24,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white24 : Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '$count',
                      style: GoogleFonts.poppins(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsChart(int correct, int incorrect) {
    return Container(
      height: 150,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 30,
          sections: [
            PieChartSectionData(
              color: Colors.greenAccent,
              value: correct.toDouble(),
              title: 'Doğru',
              radius: 60,
              titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
            ),
            PieChartSectionData(
              color: Colors.redAccent,
              value: incorrect.toDouble(),
              title: 'Yanlış',
              radius: 60,
              titleStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncorrectOnlySwitch() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Sadece Yanlış Soruları Göster',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Switch.adaptive(
            value: showOnlyIncorrect,
            onChanged: (value) {
              setState(() {
                showOnlyIncorrect = value;
              });
            },
            activeColor: Colors.redAccent,
            activeTrackColor: Colors.redAccent.withOpacity(0.5),
            inactiveThumbColor: isDarkMode ? Colors.grey : Colors.blue,
            inactiveTrackColor: isDarkMode ? Colors.grey.withOpacity(0.5) : Colors.blue.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: ContentBox(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Örnek Cümleler Hakkında',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 15),
                Text(
                  'Örnek cümleleri oluştururken karşılaşılabilecek durumlar:',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                bulletPoint('Kelimenin farklı anlamda kullanılması'),
                bulletPoint('Benzer kelimelerin karışması (tent/tenth)'),
                SizedBox(height: 15),
                Text(
                  'Bu durumlar, kelimelerin türemiş hallerini görebilmeniz için tercih edilmiştir.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  'Anlayışınız için teşekkür ederiz.',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 10),
                Text(
                  'PhD Akademi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Anladım',
                      style: TextStyle(fontSize: 18, color: Colors.teal),
                    ),
                  ),
                ),
              ],
            ),
            icon: Icons.info_outline,
          ),
        );
      },
    );
  }

  Widget bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('• ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
  Widget _buildQuestionsList(List<QuizQuestion> questions) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: questions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final question = questions[index];
        return _buildQuestionItem(question, index);
      },
    );
  }

  Widget _buildQuestionItem(QuizQuestion question, int index) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: question.isAnsweredCorrectly ? Colors.greenAccent : Colors.redAccent,
          child: Text('${index + 1}',
              style: GoogleFonts.poppins(color: isDarkMode ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(question.term,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black)),
        subtitle: Text(
          question.isAnsweredCorrectly ? 'Doğru' : 'Yanlış',
          style: GoogleFonts.poppins(
              color: question.isAnsweredCorrectly ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.w500
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doğru Cevap:',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white70 : Colors.black54),
                ),
                SizedBox(height: 4),
                Text(
                  question.options[question.correctOptionIndex],
                  style: GoogleFonts.poppins(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = !isDarkMode;
      prefs.setBool('darkMode', isDarkMode);
    });
  }
}
class ExampleSentenceCard extends StatelessWidget {
  final String sentence;
  final String highlightWord;
  final VoidCallback onListen;

  const ExampleSentenceCard({
    Key? key,
    required this.sentence,
    required this.highlightWord,
    required this.onListen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: HighlightedText(
                  text: sentence,
                  highlightedWord: highlightWord,
                  baseStyle: GoogleFonts.nunito(
                    fontSize: 20,
                    color: Color(0xFF4B4B4B),
                  ),
                  highlightStyle: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1CB0F6),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.volume_up, color: Colors.white),
              label: Text('Dinle', style: GoogleFonts.nunito(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              onPressed: onListen,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HighlightedText extends StatelessWidget {
  final String text;
  final String highlightedWord;
  final TextStyle baseStyle;
  final TextStyle highlightStyle;

  const HighlightedText({
    Key? key,
    required this.text,
    required this.highlightedWord,
    required this.baseStyle,
    required this.highlightStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: baseStyle,
        children: words.map((word) {
          if (word.toLowerCase().contains(highlightedWord.toLowerCase())) {
            return TextSpan(text: '$word ', style: highlightStyle);
          }
          return TextSpan(text: '$word ');
        }).toList(),
      ),
    );
  }
}
class ContentBox extends StatelessWidget {
  final Widget content;
  final IconData icon;

  const ContentBox({
    Key? key,
    required this.content,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(
            left: 20,
            top: 65 + 20,
            right: 20,
            bottom: 20,
          ),
          margin: EdgeInsets.only(top: 45),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 10),
                blurRadius: 10,
              ),
            ],
          ),
          child: content,
        ),
        Positioned(
          left: 20,
          right: 20,
          child: CircleAvatar(
            backgroundColor: Colors.teal,
            radius: 45,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(45)),
              child: Icon(icon, color: Colors.white, size: 50),
            ),
          ),
        ),
      ],
    );
  }
}