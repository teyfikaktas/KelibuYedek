import 'dart:async';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kelibu/Models/wordDetaik.dart'; // WordDetail modelinizin importu
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/flash_card.dart'; // FlashCardScreen sayfasının importu
import 'package:kelibu/providers/user_provider.dart'; // UserProvider importu
import 'package:kelibu/screens/video_player.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/screens/quiz.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../Models/sqlite/dbhelper.dart';
import '../globalDart/urls.dart';
import '../shared_preferences/shared_preferences.dart';
import '../variables.dart';
import '../widgets/gifplayer.dart';
import 'loadingIndicator.dart';
import 'package:collection/collection.dart';

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
                width: 30,
                height: 30,
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
class CustomLoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitChasingDots( // Circle türündeki yükleme göstergesi
        color: Theme.of(context).primaryColor, // Yükleme göstergesi rengi
        size: 50.0, // Yükleme göstergesi boyutu
      ),
    );
  }
}

class StudyScreen extends StatefulWidget {
  final List<WordDetail> words;
  final int classroomId;
  final int studySetId;
  final bool isStarred;

  StudyScreen({required this.words, required this.classroomId, required this.studySetId,    this.isStarred = false,  // Varsayılan değer false olarak ayarlandı
  });

  @override
  _StudyScreenState createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  Map<int, ValueNotifier<bool>> starredNotifiers = {};
  late TabController _tabController;
  bool _isMenuExpanded = false;
  late ScaffoldMessengerState _scaffoldMessenger;
  @override
  late UserProvider userProvider;
  ValueNotifier<int> pointValueNotifier = ValueNotifier(0);
  bool get wantKeepAlive => true;
  late PageController _sentencePageController;
  bool isLoading = true; // Yeni durum değişkeni
  bool _showOnlyStarred = false; // Yıldızlı kelimeleri göstermek için eklediğimiz kontrol değişkeni
  bool _shouldSpeak = true;  // Sayfa değiştirildiğinde seslendirme yapılması gerekip gerekmediğini kontrol eder
  int _targetPageIndex = -1;  // Hedef kelimenin indeksini saklamak için bir değişken
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ValueNotifier<int> _currentSentenceIndex = ValueNotifier<int>(0);
  late PageController _pageController;
  ValueNotifier<int> _selectedPageIndex = ValueNotifier<int>(0);
  TextEditingController _searchController = TextEditingController(); // Kelime arama için kontrolcü
  List<WordDetail> filteredWords = []; // Filtrelenmiş kelimeleri içerecek liste
  int currentWordIndex = 0; // Geçerli kelimenin indeksi
  int userID = 2;
  ValueNotifier<int> animatedStarredCount = ValueNotifier(0);
  Map<int, bool> starredStatus = {};
  FlutterTts flutterTts = FlutterTts();
  Map<int, PageController> _sentencePageControllers = {};
  Map<int, Future<List<String>>> exampleSentences = {};
  ValueNotifier<bool> _isAtBottom = ValueNotifier<bool>(false);
  int score = 0;
  String? _selectedType;
  String? _selectedLevel;
  int _maxSentencesToShow = 0; // Varsayılan olarak maksimum 10 cümle
  Map<int, ValueNotifier<int>> _currentSentenceIndices = {};
  bool _isDarkMode = false; // Dark mode durumu
  late ScrollController _scrollController;

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    _showExitConfirmationDialog();
    return true;
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }
  Map<String, double> sectionOffsets = {
    'Synonyms': -1,
    'Örnek Cümleler': -1,
    'Türemeler': -1,
    'Collocations': -1,
  };

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
  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }
  bool _showScrollButton = false;
  late AnimationController _filterPanelController;
  late Animation<double> _filterPanelAnimation;
  bool _isFilterPanelVisible = false;
  @override
  void initState() {
    super.initState();
    ApiService().logSetEntry('Çalış Modu', 'Çalış moduna ', '');
    _initializeTts();

    // Kontrolcülerin başlatılması
    _scrollController = ScrollController();
    _tabController = TabController(length: 4, vsync: this);
    _pageController = PageController(initialPage: 0);
    _sentencePageController = PageController(initialPage: 0);

    // Dinleyicilerin eklenmesi
    _scrollController.addListener(_scrollListener);
    _filterPanelController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _filterPanelAnimation = CurvedAnimation(
      parent: _filterPanelController,
      curve: Curves.easeInOut,
    );
    // Başlangıç değerlerinin ayarlanması
    _loadDarkModePreference();
    filteredWords = widget.words;

    // UserProvider'dan bilgilerin alınması
    var userProvider = Provider.of<UserProvider>(context, listen: false);
    userID = userProvider.userId;
    int currentPoints = userProvider.point;

    // Kullanıcı puanının güncellenmesi
    userProvider.addPoint(currentPoints + 1);
    ApiService().updateUserPointTimePeriod(userProvider.userId, currentPoints, 1);

    // Kelime kontrolcülerinin oluşturulması
    for (var word in widget.words) {
      _sentencePageControllers[word.id] = PageController(initialPage: 0);
    }

    // Yıldızlı kelimelerin yüklenmesi
    _loadStarredStatusAsync();

    // Örnek cümlelerin yüklenmesi
    loadExampleSentences();

    // Puan değerinin ayarlanması
    pointValueNotifier.value = score;

    // Widget ağacı oluştuktan sonra yapılacak işlemler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      userProvider = Provider.of<UserProvider>(context, listen: false);
      pointValueNotifier.value = userProvider.point;
    });
  }
  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      _isAtBottom.value = true;
    } else if (_scrollController.offset <= _scrollController.position.minScrollExtent &&
        !_scrollController.position.outOfRange) {
      _isAtBottom.value = false;
    }
  }
  int itemsPerPage = 5; // Her seferinde yüklenecek kelime sayısı
  int currentPage = 0; // Başlangıçta yüklenecek sayfa numarası
  List<WordDetail> getDisplayedWords() {
    // Eğer yıldızlı kelimeleri göster seçeneği aktifse, yalnızca yıldızlı kelimelerin listesini döndür
    if (_showOnlyStarred) {
      return widget.words.where((word) => starredNotifiers[word.id]?.value ?? false).toList();
    }
    // Değilse, tüm kelimeleri döndür
    return widget.words;
  }
  Future<void> loadExampleSentences() async {
    try {
      for (var word in widget.words) {
        // Her kelime için bir Future oluştur
        exampleSentences[word.id] = _fetchExampleSentencesForWord(word.word);
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Hata: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<String>> _fetchExampleSentencesForWord(String word) async {
    try {
      var sentences = await ApiService().fetchExampleSentencesBulk([word]);
      return sentences[word] ?? ["Cümle bulunamadı"];
    } catch (e) {
      print('Hata: $e');
      return ["Cümle yüklenirken hata oluştu"];
    }
  }
  Future<void> _updateUserScore(int newScore, int pointChange) async {
    try {
      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      int currentPoints = userProvider.point;

      print("Updating score - UserID: ${userProvider.userId}, Current Points: $currentPoints, New Score: $newScore, Point Change: $pointChange");

      if (newScore <= 1) {
        print("New score is <= 1. Keeping current points.");
        newScore = currentPoints;
      }

      if (newScore < currentPoints) {
        print("Warning: New score ($newScore) is less than current points ($currentPoints).");
      }

      await Future.wait([
        ApiService().updateUserPointTimePeriod(userProvider.userId, newScore, pointChange),
        userProvider.addPoint(newScore),
      ]);

      setState(() {
        pointValueNotifier.value = newScore;
      });

      print("Score updated successfully. New score: $newScore");
    } catch (e) {
      print("Error updating user score: $e");
      throw e;
    }
  }
// Var olan _toggleFilterPanel fonksiyonunu değiştirin
  void _toggleFilterPanel() {
    WordDetail currentWord = getDisplayedWords()[_selectedPageIndex.value];
    _showFilterPanel(currentWord, _filteredSentences);
  }
  @override
  void dispose() {
    _pageController.dispose();
    _selectedPageIndex.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _sentencePageController.dispose();
    _filterPanelController.dispose();
    _sentencePageControllers.forEach((_, controller) => controller.dispose());
    for (var controller in _sentencePageControllers.values) {
      controller.dispose();
    }
    for (var controller in _sentencePageControllers.values) {
      controller.dispose();
    }
    _flutterTts.stop();

    // Tüm Notifier'ları temizle
    for (var notifier in _isPlayingNotifiers.values) {
      notifier.dispose();
    }
    for (var notifier in _currentWordIndexNotifiers.values) {
      notifier.dispose();
    }
    super.dispose();
  }
  void speak(String text) async {
    print(text);
    await flutterTts.setLanguage("en-US");
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(text);
  }




  @override
  Widget build(BuildContext context) {
    super.build(context);  // AutomaticKeepAliveClientMixin için gerekli

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _isDarkMode ? darkModeColors["background"] : lightModeColors["background"],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.teal.shade700, Colors.teal.shade500],
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: ValueListenableBuilder<int>(
          valueListenable: _selectedPageIndex,
          builder: (_, currentPageIndex, __) {
            int wordCount = _showOnlyStarred ? getDisplayedWords().length : widget.words.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentPageIndex + 1}/$wordCount',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            );
          },
        ),
        actions: <Widget>[
          _buildStarredModeButton(),
          IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          ScoreDisplay(userPointsNotifier: pointValueNotifier),

          _buildRoundedIconButton(
            Icons.slow_motion_video_sharp,
            Colors.green,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: AppUrls.study)),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          isLoading
              ? Center(child: LogoLoadingIndicator())
              : AnimatedPadding(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.only(left: _isMenuExpanded ? 200 : 60),
            child: isLoading
                ? Center(child: LogoLoadingIndicator())
                : buildPageView(),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SideMenu(
              onSectionSelected: (section) => _scrollToSection(section),
              isExpanded: _isMenuExpanded,
              onExpandChanged: (isExpanded) {
                setState(() {
                  _isMenuExpanded = isExpanded;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRoundedIconButton(
      IconData icon, Color color, VoidCallback onPressed) {
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


  Widget _buildStarredModeButton() {
    if (widget.isStarred) {
      return SizedBox.shrink(); // Boş bir widget döndür
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _showOnlyStarred ? Colors.yellow.withOpacity(0.2) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _toggleStarredMode,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showOnlyStarred ? Icons.star : Icons.star_border,
                    color: _showOnlyStarred ? Colors.yellow : Colors.white,
                  ),
                  SizedBox(width: 1),
                  Text(
                    _showOnlyStarred ? 'Yıldızlı' : 'Tümü',
                    style: GoogleFonts.poppins(
                      color: _showOnlyStarred ? Colors.yellow : Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleStarredMode() {
    setState(() {
      _showOnlyStarred = !_showOnlyStarred;
      if (_showOnlyStarred) {
        List<WordDetail> starredWords = widget.words.where((word) => starredNotifiers[word.id]?.value ?? false).toList();
        if (starredWords.isNotEmpty) {
          int firstStarredWordIndex = widget.words.indexWhere((word) => starredWords.contains(word));
          if (firstStarredWordIndex != -1) {
            _pageController.jumpToPage(firstStarredWordIndex);
            _selectedPageIndex.value = firstStarredWordIndex;
            speak(starredWords.first.word);
          }
        }
      } else {
        _pageController.jumpToPage(0);
        _selectedPageIndex.value = 0;
        if (widget.words.isNotEmpty) {
          speak(widget.words.first.word);
        }
      }
    });
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: _isDarkMode ? darkModeColors["background"] : lightModeColors["background"],
        child: Column(
          children: [
            _buildDrawerHeader(),
            _buildSearchBar(),
            Expanded(child: _buildWordList()),

          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Colors.teal,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Kelime Listesi',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Kelime Ara',
            prefixIcon: Icon(Icons.search, color: Colors.teal),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                filterWords('');
              },
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          onChanged: filterWords,
        ),
      ),
    );
  }

  Widget _buildWordList() {
    return ListView.builder(
      itemCount: getDisplayedWords().length,
      itemBuilder: (context, index) {
        WordDetail word = filteredWords[index];
        bool isCurrentWord = widget.words.indexOf(word) == _selectedPageIndex.value;
        return _buildWordListItem(word, isCurrentWord, index);
      },
    );
  }

  Widget _buildWordListItem(WordDetail word, bool isCurrentWord, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCurrentWord
              ? [Colors.teal.shade300, Colors.teal.shade500]
              : [Colors.white, Colors.grey.shade100],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _onWordTap(word, index),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        word.word,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isCurrentWord ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        minFontSize: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      AutoSizeText(
                        word.meaning,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: isCurrentWord ? Colors.white70 : Colors.black54,
                        ),
                        maxLines: 1,
                        minFontSize: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStarIcon(word, isCurrentWord),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStarIcon(WordDetail word, bool isCurrentWord) {
    if (widget.isStarred) {
      return SizedBox.shrink(); // Eğer isStarred true ise, boş bir widget döndür
    }

    return ValueListenableBuilder<bool>(
      valueListenable: starredNotifiers[word.id] ?? ValueNotifier(false),
      builder: (_, isStarred, __) => AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isStarred ? Colors.yellow : Colors.transparent,
        ),
        child: Icon(
          isStarred ? Icons.star : Icons.star_border,
          color: isStarred ? Colors.white : (isCurrentWord ? Colors.white : Colors.grey),
          size: 28,
        ),
      ),
    );
  }

  void _onWordTap(WordDetail word, int index) async {
    Navigator.of(context).pop(); // Drawer'ı kapat
    int originalIndex = widget.words.indexOf(word);
    _targetPageIndex = index;  // Hedef kelimenin indeksini ayarla

    _pageController.jumpToPage(originalIndex);
    setState(() {
      currentWordIndex = originalIndex;
      _selectedPageIndex.value = originalIndex;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int currentPoints = userProvider.point;
    int newPoints = currentPoints + 1;

    try {
      await _updateUserScore(newPoints, 1);
      print('Puan güncellendi: $newPoints');
    } catch (e) {
      print('Puan güncelleme hatası: $e');
    }
  }
  Widget buildPageView() {
    List<WordDetail> displayedWords = getDisplayedWords();
    return PageView.builder(
      key: PageStorageKey<String>('pageView'),
      controller: _pageController,
      itemCount: displayedWords.length,
      onPageChanged: (index) async {
        if (index > currentWordIndex) {
          // Sağa kaydırıldı, puanı artır
          int newPoints = pointValueNotifier.value + 1;
          await _updateUserScore(newPoints, 1);
        }

        // Önceki kelimeyi al
        WordDetail? previousWord = currentWordIndex < displayedWords.length ?
        displayedWords[currentWordIndex] : null;

        // Yeni kelimeyi al
        WordDetail currentWord = displayedWords[index];

        setState(() {
          _selectedPageIndex.value = index;
          currentWordIndex = index;
          _scrollToTop(); // Sayfayı yukarı kaydır
          _isAtBottom.value = false; // "Aşağı İn" durumuna geri dön

          // Filtreleri sıfırla
          _selectedLevel = null;
          _selectedType = null;
          _maxSentencesToShow = 0; // 0 tüm cümleleri göster demek

          // ÖNEMLİ: Yeni kelimenin cümle PageController'ını sıfırla
          if (_sentencePageControllers.containsKey(currentWord.id) &&
              _sentencePageControllers[currentWord.id]!.hasClients) {
            _sentencePageControllers[currentWord.id]!.jumpToPage(0);
            print("Kelime ID: ${currentWord.id} için PageController sıfırlandı");
          }

          // Tüm TTS okumalarını durdur
          _flutterTts.stop();

          // Kelimeye ait çalma durumlarını sıfırla
          for (var key in List.from(_isPlayingNotifiers.keys)) {
            if (key.startsWith('${currentWord.id}_')) {
              _isPlayingNotifiers[key]?.value = false;
            }
          }

          // Kelimeye ait vurgulama durumlarını sıfırla
          for (var key in List.from(_currentWordIndexNotifiers.keys)) {
            if (key.startsWith('${currentWord.id}_')) {
              _currentWordIndexNotifiers[key]?.value = -1;
            }
          }
        });

        // Eğer kelime için zaten yüklenmiş veritabanı cümleleri yoksa, yüklenmelerini sağla
        if (!_wordFilteredSentences.containsKey(currentWord.id)) {
          var sentencesData = await _loadSentencesFromDatabase(currentWord.word ?? '');
          if (sentencesData.isNotEmpty) {
            setState(() {
              _wordFilteredSentences[currentWord.id] = sentencesData;
            });
          }
        }

        // Yeni kelimeyi seslendir
        if (displayedWords.isNotEmpty && index < displayedWords.length) {
          speak(displayedWords[index].word);
        }
      },
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double value = 1.0;
            if (_pageController.position.haveDimensions) {
              value = _pageController.page! - index;
              value = (1 - (value.abs() * 0.5)).clamp(0.0, 1.0);
            }
            return Center(
              child: SizedBox(
                child: child,
              ),
            );
          },
          child: buildWordDetail(displayedWords[index]),
        );
      },
    );
  }  void _resetSentenceStates(WordDetail word) {
    // Tüm TTS okumalarını durdur
    _flutterTts.stop();

    // Mevcut cümle PageController'ını sıfırla
    if (_sentencePageControllers.containsKey(word.id) &&
        _sentencePageControllers[word.id]!.hasClients) {
      // Önce son sayfayı kaydet (eğer düzgün sayfayı göstermek için gerekirse)
      int lastPage = _sentencePageControllers[word.id]!.page?.round() ?? 0;

      // Controller'ı sıfırla
      _sentencePageControllers[word.id]!.jumpToPage(0);

      print("Kelime ID: ${word.id} için PageController sıfırlandı");
    }

    // Cümle çalma durumlarını sıfırla
    for (var key in _isPlayingNotifiers.keys) {
      if (key.startsWith('${word.id}_')) {
        _isPlayingNotifiers[key]?.value = false;
      }
    }

    // Kelime vurgulama durumlarını sıfırla
    for (var key in _currentWordIndexNotifiers.keys) {
      if (key.startsWith('${word.id}_')) {
        _currentWordIndexNotifiers[key]?.value = -1;
      }
    }
  }

// Tüm kelimelerin cümle durumlarını sıfırla
  void _resetAllSentenceStates() {
    // Tüm TTS okumalarını durdur
    _flutterTts.stop();

    // Tüm PageController'ları sıfırla
    for (var controller in _sentencePageControllers.values) {
      if (controller.hasClients) {
        controller.jumpToPage(0);
      }
    }

    // Tüm çalma durumlarını sıfırla
    for (var notifier in _isPlayingNotifiers.values) {
      notifier.value = false;
    }

    // Tüm kelime vurgulama durumlarını sıfırla
    for (var notifier in _currentWordIndexNotifiers.values) {
      notifier.value = -1;
    }

    print("Tüm cümle durumları sıfırlandı");
  }
  List<TextSpan> _getHighlightedText(String text, String wordToHighlight) {
    if (wordToHighlight.isEmpty) return [TextSpan(text: text)];

    // Büyük/küçük harf duyarsız arama için
    String pattern = wordToHighlight.toLowerCase();
    String textLower = text.toLowerCase();

    List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch;

    while (true) {
      indexOfMatch = textLower.indexOf(pattern, start);
      if (indexOfMatch == -1) {
        // Kalan metni ekle
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        break;
      }

      // Eşleşmeden önceki metni ekle
      if (indexOfMatch > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfMatch)));
      }

      // Eşleşen kelimeyi vurgulayarak ekle
      spans.add(TextSpan(
        text: text.substring(indexOfMatch, indexOfMatch + wordToHighlight.length),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: Colors.teal,
          backgroundColor: Colors.teal.withOpacity(0.1),
        ),
      ));

      // İlerleme
      start = indexOfMatch + wordToHighlight.length;
    }

    return spans;
  }
  List<Map<String, dynamic>> _filteredSentences = [];
// Açılır filtre paneli oluşturmak için _buildSentencesSection fonksiyonu
// Eklenmesi gereken sınıf değişkenleri
  final FlutterTts _flutterTts = FlutterTts();
  Map<String, List<String>> _sentenceWordsMap = {}; // Cümleleri kelimelere bölmek için (kelimeId_cümleIndeksi şeklinde anahtarlanır)

// Ayrıca, eğer diğer değişkenler de benzer şekilde String anahtar kullanıyorsa, onları da aynı şekilde güncellemelisiniz:
  Map<String, ValueNotifier<bool>> _isPlayingNotifiers = {}; // Cümle çalınma durumu
  Map<String, ValueNotifier<int>> _currentWordIndexNotifiers = {};

  Widget _buildSentencesSection(WordDetail word) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadSentencesFromDatabase(word.word ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
          );
        } else if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Cümleler yüklenirken bir hata oluştu: ${snapshot.error}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        } else {
          final sentencesData = snapshot.data;
          if (sentencesData == null || sentencesData.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sentiment_dissatisfied,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Bu kelime için örnek cümle bulunamadı.",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Her kelime için benzersiz bir filtrelenmiş cümleler listesi oluştur
          List<Map<String, dynamic>> currentWordFilteredSentences;

          // Kelimeye özgü filtrelenmiş cümleler zaten varsa onları kullan
          // Yoksa sentencesData'yı kullan ve kelimeye özgü olarak sakla
          if (_wordFilteredSentences.containsKey(word.id)) {
            currentWordFilteredSentences = _wordFilteredSentences[word.id]!;
          } else {
            currentWordFilteredSentences = List.from(sentencesData);
            _wordFilteredSentences[word.id] = currentWordFilteredSentences;
          }

          // PageController oluştur veya mevcut olanı kullan
          if (!_sentencePageControllers.containsKey(word.id)) {
            _sentencePageControllers[word.id] = PageController();
          }

          // Mevcut tüm seviye ve tipleri al
          Set<String> availableLevels = {};
          Set<String> availableTypes = {};

          for (var sentence in sentencesData) {
            if (sentence['level'] != null && sentence['level'].toString().isNotEmpty) {
              availableLevels.add(sentence['level']);
            }
            if (sentence['type'] != null && sentence['type'].toString().isNotEmpty) {
              availableTypes.add(sentence['type']);
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header ve aktif filtreleri gösteren widget
              _buildHeaderWithFilters(sentencesData, word),

              // PageView ve cümleler
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    key: ValueKey<String>('sentenceContainer_${word.id}_${currentWordFilteredSentences.length}_${_selectedLevel ?? "all"}_${_selectedType ?? "all"}_${_maxSentencesToShow}_${DateTime.now().millisecondsSinceEpoch}'),
                    constraints: BoxConstraints(
                      minHeight: 200,
                      maxHeight: 350,
                    ),
                    child: currentWordFilteredSentences.isEmpty
                        ? Center(
                      child: Text(
                        "Seçilen filtrelere uygun cümle bulunamadı.",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                        : Stack(
                      children: [
                        PageView.builder(
                          key: ValueKey<String>('sentences_pageview_${word.id}_${currentWordFilteredSentences.length}_${_selectedLevel ?? "all"}_${_selectedType ?? "all"}_${_maxSentencesToShow}_${DateTime.now().millisecondsSinceEpoch}'),
                          physics: const BouncingScrollPhysics(),
                          controller: _sentencePageControllers[word.id]!,
                          itemCount: currentWordFilteredSentences.length,
                          itemBuilder: (context, index) {
                            final data = currentWordFilteredSentences[index];
                            final sentence = data['sentence'] ?? '';
                            final wordToHighlight = word.word ?? '';

                            // Cümleyi kelimelere ayır ve her zaman yeniden oluştur
                            // Benzersiz bir anahtar kullanarak her kelime-cümle kombinasyonu için ayrı sakla
                            final sentenceKey = '${word.id}_${index}';
                            if (!_sentenceWordsMap.containsKey(sentenceKey)) {
                              _sentenceWordsMap[sentenceKey] = _splitSentenceToWords(sentence);
                            }

                            // Her cümle için bir kelime indeksi izleyicisi oluştur (her zaman)
                            if (!_currentWordIndexNotifiers.containsKey(sentenceKey)) {
                              _currentWordIndexNotifiers[sentenceKey] = ValueNotifier<int>(-1);
                            } else {
                              _currentWordIndexNotifiers[sentenceKey]?.value = -1; // Mevcut değeri sıfırla
                            }

                            // Çalma durumu izleyicisi
                            if (!_isPlayingNotifiers.containsKey(sentenceKey)) {
                              _isPlayingNotifiers[sentenceKey] = ValueNotifier<bool>(false);
                            } else {
                              _isPlayingNotifiers[sentenceKey]?.value = false; // Mevcut değeri sıfırla
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: [Colors.white, Colors.teal.shade50],
                                  ),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Ana cümle - okunan kelime vurgulaması ile
                                      InkWell(
                                        onTap: () {
                                          _speakSentence(sentence, sentenceKey);
                                        },
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: ValueListenableBuilder<int>(
                                                valueListenable: _currentWordIndexNotifiers[sentenceKey]!,
                                                builder: (context, currentWordIndex, child) {
                                                  return _buildHighlightedText(
                                                    _sentenceWordsMap[sentenceKey]!,
                                                    wordToHighlight,
                                                    currentWordIndex,
                                                  );
                                                },
                                              ),
                                            ),
                                            // Dinleme butonu
                                            ValueListenableBuilder<bool>(
                                              valueListenable: _isPlayingNotifiers[sentenceKey]!,
                                              builder: (context, isPlaying, child) {
                                                return IconButton(
                                                  icon: Icon(
                                                    isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
                                                    color: isPlaying ? Colors.teal : Colors.grey,
                                                  ),
                                                  onPressed: () {
                                                    _speakSentence(sentence, sentenceKey);
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Türkçe çeviri
                                      Text(
                                        data['translate'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                          fontStyle: FontStyle.italic,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // type ve level bilgilerini gösteren satır
                                      Row(
                                        children: [
                                          if (data['level'] != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade400,
                                                borderRadius: BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.orange.withOpacity(0.2),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                data['level'],
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Sayfa göstergesi
              if (currentWordFilteredSentences.isNotEmpty) _buildPaginationIndicator(word),
            ],
          );
        }
      },
    );
  }
// Cümleyi kelimelere ayıran yardımcı fonksiyon
  List<String> _splitSentenceToWords(String sentence) {
    // Daha basit bir yaklaşım kullanarak cümleyi kelimelere bölelim
    // Önce boşluklara göre böl
    List<String> words = sentence.split(' ');
    List<String> result = [];

    // Her bir öğeyi noktalama işaretlerinden temizle ve ekle
    for (var word in words) {
      if (word.isNotEmpty) {
        // Noktalama işaretlerini korumak istiyorsak doğrudan ekleyebiliriz
        result.add(word);
      }
    }

    return result;
  }// Okunan kelimeyi vurgulayan widget
// Okunan kelimeyi vurgulayan widget
  Widget _buildHighlightedText(List<String> words, String wordToHighlight, int currentWordIndex) {
    final wordToHighlightLower = wordToHighlight.toLowerCase();

    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.black87,
          height: 1.5,
        ),
        children: List.generate(words.length, (index) {
          final word = words[index];
          final isWordHighlighted = word.toLowerCase().contains(wordToHighlightLower);
          final isCurrentlyBeingRead = index == currentWordIndex;

          // Okuma vurgulaması (okunan kelime)
          if (isCurrentlyBeingRead) {
            return TextSpan(
              text: word + (index < words.length - 1 ? ' ' : ''),
              style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: Colors.teal,
                decorationThickness: 2,
                letterSpacing: 0.3,
              ),
            );
          }

          // Aranan kelime vurgulaması
          if (isWordHighlighted) {
            return TextSpan(
              text: word + (index < words.length - 1 ? ' ' : ''),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            );
          }

          // Normal kelime
          return TextSpan(
            text: word + (index < words.length - 1 ? ' ' : ''),
          );
        }),
      ),
    );
  }
  Map<int, List<Map<String, dynamic>>> _wordFilteredSentences = {};
  Future<void> _speakSentence(String sentence, String sentenceKey) async {
    // Eğer zaten çalıyorsa durdur
    if (_isPlayingNotifiers[sentenceKey]?.value == true) {
      await _flutterTts.stop();
      _isPlayingNotifiers[sentenceKey]?.value = false;
      _currentWordIndexNotifiers[sentenceKey]?.value = -1; // Vurgulamayı sıfırla
      return;
    }

    // TTS ayarları
    await _flutterTts.setLanguage("en-US"); // İngilizce için
    await _flutterTts.setSpeechRate(0.5); // Konuşma hızı (yavaş: 0.5)
    await _flutterTts.setVolume(1.0); // Ses seviyesi
    await _flutterTts.setPitch(1.0); // Ses tonu

    // Kelime başı olayını dinle
    _flutterTts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      if (word.isNotEmpty) {
        final words = _sentenceWordsMap[sentenceKey] ?? [];

        // Şu anki pozisyona kadar olan kelimelerin sayısını bul
        String textUpToNow = text.substring(0, startOffset);
        int wordCount = textUpToNow.split(' ').where((s) => s.isNotEmpty).length;

        // Cümledeki toplam kelime sayısıyla karşılaştır ve sınırları kontrol et
        if (wordCount >= 0 && wordCount < words.length) {
          _currentWordIndexNotifiers[sentenceKey]?.value = wordCount;
        }
      }
    });

    // Çalma/durma durumunu takip etmek için dinleyicileri ekle
    _flutterTts.setCompletionHandler(() {
      _isPlayingNotifiers[sentenceKey]?.value = false;
      _currentWordIndexNotifiers[sentenceKey]?.value = -1; // Vurgulamayı sıfırla
    });

    _flutterTts.setErrorHandler((error) {
      _isPlayingNotifiers[sentenceKey]?.value = false;
      _currentWordIndexNotifiers[sentenceKey]?.value = -1; // Vurgulamayı sıfırla
    });

    // Ses simgesini aktif hale getir
    _isPlayingNotifiers[sentenceKey]?.value = true;
    _currentWordIndexNotifiers[sentenceKey]?.value = -1; // Vurgulamayı başlangıçta sıfırla

    // Cümleyi okut
    await _flutterTts.speak(sentence);
  }

// TTS'i başlat
  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    _wordFilteredSentences = {};  // Her kelime için filtrelenmiş cümleler

    // TTS'in özelliklerini kontrol et - bu metod hataya sebep oluyordu
    try {
      bool hasProgressFeature = await _flutterTts.isLanguageAvailable("en-US");

      if (hasProgressFeature) {
        print("TTS başarıyla başlatıldı ve İngilizce destekleniyor!");
      } else {
        print("Bu dil desteklenmiyor, başka bir dil seçin");
      }
    } catch (e) {
      print("TTS başlatılırken hata oluştu: $e");
    }
  }



  Widget _buildHeaderWithFilters(List<Map<String, dynamic>> sentencesData, WordDetail word) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(  // Row yerine Column kullanın
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sayfa bilgisi
          AnimatedBuilder(
            animation: _sentencePageControllers[word.id]!,
            builder: (context, _) {
              int currentPage = _sentencePageControllers[word.id]!.hasClients
                  ? (_sentencePageControllers[word.id]!.page?.round() ?? 0)
                  : 0;

              // Doğru cümle listesini kullan: kelimeye özgü filtrelenmiş cümleler
              List<Map<String, dynamic>> currentWordFilteredSentences =
                  _wordFilteredSentences[word.id] ?? [];

              return RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  children: [
                    TextSpan(
                      text: "Cümle ",
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    TextSpan(
                      text: "${currentPage + 1}/${currentWordFilteredSentences.length}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: 8), // Biraz boşluk ekleyin

          // Filtre chips ve ayarlar butonu (ayrı bir satırda)
          Row(
            children: [
              // Seviye bilgisi (Seçili değilse "Tüm Seviyeler" göster)
              _buildFilterChip(
                label: _selectedLevel != null ? _selectedLevel! : "Tüm Seviyeler",
                color: Colors.orange.shade400,
                onTap: () => _showFilterPanel(word, sentencesData),
              ),

              SizedBox(width: 6), // Biraz boşluk ekleyin

              Spacer(), // Sağa doğru itme

              // Filtre butonu
              GestureDetector(
                onTap: () => _showFilterModal(word, sentencesData),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _isDarkMode ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: _isDarkMode ? Colors.teal.shade300.withOpacity(0.5) : Colors.teal.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 18,
                        color: _isDarkMode ? Colors.teal.shade300 : Colors.teal.shade700,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Filtrele",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _isDarkMode ? Colors.teal.shade300 : Colors.teal.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildFilterChip({
    required String label,
    required Color color,
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _filterSentences(List<Map<String, dynamic>> allSentences, WordDetail word) {
    setState(() {
      // Filtreleri uygula ve sonuçları kelimeye özgü olarak sakla
      _wordFilteredSentences[word.id] = allSentences.where((sentence) {
        bool levelMatch = _selectedLevel == null || sentence['level'] == _selectedLevel;
        bool typeMatch = _selectedType == null || sentence['type'] == _selectedType;
        return levelMatch && typeMatch;
      }).toList();

      // Ayrıca global _filteredSentences'i de güncelle (geriye dönük uyumluluk için)
      _filteredSentences = _wordFilteredSentences[word.id] ?? [];

      // Maksimum cümle sayısı sınırlama
      if (_maxSentencesToShow > 0 && _wordFilteredSentences[word.id]!.length > _maxSentencesToShow) {
        _wordFilteredSentences[word.id] = _wordFilteredSentences[word.id]!.sublist(0, _maxSentencesToShow);
        _filteredSentences = _filteredSentences.sublist(0, _maxSentencesToShow);
      }

      // Önce TTS'i durdur
      _flutterTts.stop();

      // Kelime haritalarını temizle (sadece bu kelimeye ait olanları)
      for (var key in List.from(_sentenceWordsMap.keys)) {
        if (key.startsWith('${word.id}_')) {
          _sentenceWordsMap.remove(key);
        }
      }

      for (var key in List.from(_currentWordIndexNotifiers.keys)) {
        if (key.startsWith('${word.id}_')) {
          _currentWordIndexNotifiers[key]?.dispose();
          _currentWordIndexNotifiers.remove(key);
        }
      }

      for (var key in List.from(_isPlayingNotifiers.keys)) {
        if (key.startsWith('${word.id}_')) {
          _isPlayingNotifiers[key]?.dispose();
          _isPlayingNotifiers.remove(key);
        }
      }

      // PageController'ı sıfırla
      if (_sentencePageControllers.containsKey(word.id)) {
        if (_sentencePageControllers[word.id]?.hasClients == true) {
          // Mevcut controller'ı dispose et
          //_sentencePageControllers[word.id]!.dispose();

          // Yeni controller oluşturmak yerine, mevcut controller'ı sıfırla
          _sentencePageControllers[word.id]!.jumpToPage(0);

          // Kısa gecikme ile PageController'ın reset'lendiğinden emin olalım
          Future.delayed(Duration(milliseconds: 100), () {
            if (_sentencePageControllers[word.id]?.hasClients == true) {
              _sentencePageControllers[word.id]!.jumpToPage(0);
            }
          });
        }
      }

      // Boş filtre durumunda geri bildirim
      if (_wordFilteredSentences[word.id]!.isEmpty && allSentences.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seçilen filtrelere uygun cümle bulunamadı')),
        );
      }
    });
  }// Filtre panelini açmak için bu fonksiyonu çağırın
  void _showFilterPanel(WordDetail word, List<Map<String, dynamic>> sentencesData) {
    // Mevcut değerleri geçici olarak saklayalım
    String? tempSelectedLevel = _selectedLevel;
    String? tempSelectedType = _selectedType;
    int tempMaxSentences = _maxSentencesToShow;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Mevcut filtrelerin durumunu alın
            Set<String> availableLevels = {};
            Set<String> availableTypes = {};

            for (var sentence in sentencesData) {
              if (sentence['level'] != null && sentence['level'].toString().isNotEmpty) {
                availableLevels.add(sentence['level']);
              }
              if (sentence['type'] != null && sentence['type'].toString().isNotEmpty) {
                availableTypes.add(sentence['type']);
              }
            }

            // Burada filtrelenen cümle sayısını hesaplıyoruz
            List<Map<String, dynamic>> tempFilteredSentences = sentencesData.where((sentence) {
              bool levelMatch = tempSelectedLevel == null || sentence['level'] == tempSelectedLevel;
              bool typeMatch = tempSelectedType == null || sentence['type'] == tempSelectedType;
              return levelMatch && typeMatch;
            }).toList();

            int totalFilteredCount = tempFilteredSentences.length;
            int displayCount = tempMaxSentences == 0 ? totalFilteredCount :
            (tempMaxSentences < totalFilteredCount ? tempMaxSentences : totalFilteredCount);

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Panel Başlığı
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade700, Colors.teal.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Cümle Filtreleri",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Panel İçeriği
                    Flexible(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bilgi Satırı
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.teal.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.teal.shade700, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Filtreleme Bilgisi",
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.teal.shade700,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            "Toplam $totalFilteredCount cümle içinden $displayCount tanesi gösterilecek",
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.teal.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 24),

                              // Tümünü Göster Butonu
                              Container(
                                width: double.infinity,
                                margin: EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade600,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.15),
                                      offset: Offset(0, 3),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  icon: Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Icon(
                                      Icons.visibility_outlined,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  label: Text(
                                    "Tüm Cümleleri Göster",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    disabledBackgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    shadowColor: Colors.transparent,
                                  ),
                                  onPressed: () {
                                    setDialogState(() {
                                      tempSelectedLevel = null;
                                      tempSelectedType = null;
                                      tempMaxSentences = 0;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(height: 24),

                              // Seviye Filtresi
                              Text(
                                "Seviye",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _buildDialogFilterOption(
                                    label: "Tümü",
                                    isSelected: tempSelectedLevel == null,
                                    color: Colors.orange.shade400,
                                    onTap: () {
                                      setDialogState(() {
                                        tempSelectedLevel = null;
                                      });
                                    },
                                  ),
                                  ...availableLevels.map((level) => _buildDialogFilterOption(
                                    label: level,
                                    isSelected: tempSelectedLevel == level,
                                    color: Colors.orange.shade400,
                                    onTap: () {
                                      setDialogState(() {
                                        tempSelectedLevel = level;
                                      });
                                    },
                                  )).toList(),
                                ],
                              ),

                              SizedBox(height: 24),

                              // Tür Filtresi
                              Text(
                                "Cümle Tipi",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.teal.shade700,
                                ),
                              ),
                              SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _buildDialogFilterOption(
                                    label: "Tümü",
                                    isSelected: tempSelectedType == null,
                                    color: Colors.teal.shade400,
                                    onTap: () {
                                      setDialogState(() {
                                        tempSelectedType = null;
                                      });
                                    },
                                  ),
                                  ...availableTypes.map((type) => _buildDialogFilterOption(
                                    label: type,
                                    isSelected: tempSelectedType == type,
                                    color: Colors.teal.shade400,
                                    onTap: () {
                                      setDialogState(() {
                                        tempSelectedType = type;
                                      });
                                    },
                                  )).toList(),
                                ],
                              ),

                              SizedBox(height: 24),

                              // Gösterilecek Cümle Sayısı
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Gösterilecek Cümle Sayısı",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: tempMaxSentences == 0 ? Colors.teal.shade100 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: tempMaxSentences == 0 ? Colors.teal : Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      tempMaxSentences == 0 ? "Tümü" : tempMaxSentences.toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: tempMaxSentences == 0 ? Colors.teal : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),

                              // Sayı Seçenekleri
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildDialogNumberOption(0, "Tümü", tempMaxSentences, (value) {
                                      setDialogState(() {
                                        tempMaxSentences = value;
                                      });
                                    }),
                                    _buildDialogNumberOption(5, "5", tempMaxSentences, (value) {
                                      setDialogState(() {
                                        tempMaxSentences = value;
                                      });
                                    }),
                                    _buildDialogNumberOption(10, "10", tempMaxSentences, (value) {
                                      setDialogState(() {
                                        tempMaxSentences = value;
                                      });
                                    }),
                                    _buildDialogNumberOption(20, "20", tempMaxSentences, (value) {
                                      setDialogState(() {
                                        tempMaxSentences = value;
                                      });
                                    }),
                                    _buildDialogNumberOption(30, "30", tempMaxSentences, (value) {
                                      setDialogState(() {
                                        tempMaxSentences = value;
                                      });
                                    }),
                                    _buildDialogNumberOption(50, "50", tempMaxSentences, (value) {
                                      setDialogState(() {
                                        tempMaxSentences = value;
                                      });
                                    }),
                                    _buildDialogNumberOption(100, "100", tempMaxSentences, (value) {
                                      setDialogState(() {
                                        tempMaxSentences = value;
                                      });
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Panel Alt Butonları
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // İptal Butonu
                          Expanded(
                            child: OutlinedButton(
                              child: Text(
                                "İptal",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade800,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                          SizedBox(width: 12),

                          // Uygula Butonu
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              child: Text(
                                "Filtreleri Uygula",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                // Değişiklikleri kaydet ve uygula
                                setState(() {
                                  _selectedLevel = tempSelectedLevel;
                                  _selectedType = tempSelectedType;
                                  _maxSentencesToShow = tempMaxSentences;
                                  _filterSentences(sentencesData, word);
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Filtre seçenekleri için buton (Dialog için)
  Widget _buildDialogFilterOption({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

// Sayı seçimi için buton (Dialog için)
  Widget _buildDialogNumberOption(
      int value,
      String label,
      int currentValue,
      Function(int) onSelected,
      ) {
    bool isSelected = currentValue == value;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.teal.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }


// Floating filtre butonu da yeni modal dialog'u açacak
  void _showFilterModal(WordDetail word, List<Map<String, dynamic>> sentencesData) {
    // Mevcut değerleri geçici olarak saklayalım
    String? tempSelectedLevel = _selectedLevel;
    String? tempSelectedType = _selectedType;
    int tempMaxSentences = _maxSentencesToShow;

    // Mevcut tüm seviye ve tipleri al
    Set<String> availableLevels = {};
    Set<String> availableTypes = {};

    for (var sentence in sentencesData) {
      if (sentence['level'] != null && sentence['level'].toString().isNotEmpty) {
        availableLevels.add(sentence['level']);
      }
      if (sentence['type'] != null && sentence['type'].toString().isNotEmpty) {
        availableTypes.add(sentence['type']);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Burada filtrelenen cümle sayısını hesaplıyoruz
            List<Map<String, dynamic>> tempFilteredSentences = sentencesData.where((sentence) {
              bool levelMatch = tempSelectedLevel == null || sentence['level'] == tempSelectedLevel;
              bool typeMatch = tempSelectedType == null || sentence['type'] == tempSelectedType;
              return levelMatch && typeMatch;
            }).toList();

            int totalFilteredCount = tempFilteredSentences.length;
            int displayCount = tempMaxSentences == 0 ? totalFilteredCount :
            (tempMaxSentences < totalFilteredCount ? tempMaxSentences : totalFilteredCount);

            return DraggableScrollableSheet(
              initialChildSize: 0.8, // Sayfanın %80'ini kaplar
              minChildSize: 0.5,     // En az %50'sini kaplar
              maxChildSize: 0.95,    // En fazla %95'ini kaplar
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10.0,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Tutamak çizgisi
                      Container(
                        margin: EdgeInsets.only(top: 12),
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Panel Başlığı
                      Container(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.filter_list_rounded,
                                color: Colors.teal.shade700,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Cümle Filtreleri",
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Görmek istediğiniz cümleleri filtreleyin",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bilgi Paneli
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 24),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.teal.shade700),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Toplam $totalFilteredCount cümle içinden $displayCount tanesi gösterilecek",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Filtre İçeriği
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
                          children: [
                            // Tümünü Göster Butonu
                            Container(
                              margin: EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.teal.shade700, Colors.teal.shade500],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.teal.withOpacity(0.25),
                                    offset: Offset(0, 4),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                icon: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.visibility_outlined,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                label: Text(
                                  "Tüm Cümleleri Göster",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    tempSelectedLevel = null;
                                    tempSelectedType = null;
                                    tempMaxSentences = 0; // 0 değeri tüm cümleleri gösterir
                                  });
                                },
                              ),
                            ),
                            // Seviye Seçimi
                            Container(
                              margin: EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.signal_cellular_alt,
                                          color: Colors.orange.shade700,
                                          size: 18,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "Seviye Seçimi",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _buildModalFilterOption(
                                        label: "Tümü",
                                        isSelected: tempSelectedLevel == null,
                                        color: Colors.orange.shade400,
                                        onTap: () {
                                          setModalState(() {
                                            tempSelectedLevel = null;
                                          });
                                        },
                                      ),
                                      ...availableLevels.map((level) => _buildModalFilterOption(
                                        label: level,
                                        isSelected: tempSelectedLevel == level,
                                        color: Colors.orange.shade400,
                                        onTap: () {
                                          setModalState(() {
                                            tempSelectedLevel = level;
                                          });
                                        },
                                      )).toList(),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Cümle Tipi Seçimi
                            Container(
                              margin: EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.category,
                                          color: Colors.teal.shade700,
                                          size: 18,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "Cümle Tipi",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.teal.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _buildModalFilterOption(
                                        label: "Tümü",
                                        isSelected: tempSelectedType == null,
                                        color: Colors.teal.shade400,
                                        onTap: () {
                                          setModalState(() {
                                            tempSelectedType = null;
                                          });
                                        },
                                      ),
                                      ...availableTypes.map((type) => _buildModalFilterOption(
                                        label: type,
                                        isSelected: tempSelectedType == type,
                                        color: Colors.teal.shade400,
                                        onTap: () {
                                          setModalState(() {
                                            tempSelectedType = type;
                                          });
                                        },
                                      )).toList(),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Cümle Sayısı Seçimi
                            Container(
                              margin: EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.format_list_numbered,
                                          color: Colors.blue.shade700,
                                          size: 18,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "Gösterilecek Cümle Sayısı",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Şu an: ${tempMaxSentences == 0 ? 'Tümü' : tempMaxSentences.toString()}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _buildModalNumberOption(0, "Tümü", tempMaxSentences, (value) {
                                        setModalState(() {
                                          tempMaxSentences = value;
                                        });
                                      }),
                                      _buildModalNumberOption(5, "5", tempMaxSentences, (value) {
                                        setModalState(() {
                                          tempMaxSentences = value;
                                        });
                                      }),
                                      _buildModalNumberOption(10, "10", tempMaxSentences, (value) {
                                        setModalState(() {
                                          tempMaxSentences = value;
                                        });
                                      }),
                                      _buildModalNumberOption(20, "20", tempMaxSentences, (value) {
                                        setModalState(() {
                                          tempMaxSentences = value;
                                        });
                                      }),
                                      _buildModalNumberOption(30, "30", tempMaxSentences, (value) {
                                        setModalState(() {
                                          tempMaxSentences = value;
                                        });
                                      }),
                                      _buildModalNumberOption(50, "50", tempMaxSentences, (value) {
                                        setModalState(() {
                                          tempMaxSentences = value;
                                        });
                                      }),
                                      _buildModalNumberOption(100, "100", tempMaxSentences, (value) {
                                        setModalState(() {
                                          tempMaxSentences = value;
                                        });
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Alt Butonlar
                      Container(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              offset: Offset(0, -4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // İptal Butonu
                            Expanded(
                              child: OutlinedButton(
                                child: Text(
                                  "İptal",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                            SizedBox(width: 12),

                            // Uygula Butonu
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                child: Text(
                                  "Filtreleri Uygula",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade700,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  // Değişiklikleri kaydet ve uygula
                                  setState(() {
                                    _selectedLevel = tempSelectedLevel;
                                    _selectedType = tempSelectedType;
                                    _maxSentencesToShow = tempMaxSentences;
                                    _filterSentences(sentencesData, word);
                                  });
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        ),
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
  Widget _buildModalFilterOption({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

// Sayı seçimi için buton (Modal için)
  Widget _buildModalNumberOption(
      int value,
      String label,
      int currentValue,
      Function(int) onSelected,
      ) {
    bool isSelected = currentValue == value;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade500 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue.shade500 : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
  // Sayı seçimlerini buton şeklinde göstermek için yeni bir widget
  Widget _buildNumberOption(int value, String label, List<Map<String, dynamic>> sentencesData, WordDetail word) {
    bool isSelected = _maxSentencesToShow == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _maxSentencesToShow = value;
          _filterSentences(sentencesData, word);
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // Filtreleme seçeneği (radio button benzeri)
  Widget _buildFilterOption({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // Aksiyon butonu
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPaginationIndicator(WordDetail word) {
    return AnimatedBuilder(
      animation: _sentencePageControllers[word.id]!,
      builder: (context, _) {
        int currentPage = _sentencePageControllers[word.id]!.hasClients
            ? (_sentencePageControllers[word.id]!.page?.round() ?? 0)
            : 0;

        // Kelimeye özgü filtrelenmiş cümleleri kullan
        List<Map<String, dynamic>> currentWordFilteredSentences =
            _wordFilteredSentences[word.id] ?? [];

        // Nokta göstergelerini içeren kaydırılabilir konteyner
        return Container(
          height: 24,
          child: currentWordFilteredSentences.length > 10
              ? _buildScrollablePaginationDots(currentPage, word)
              : _buildFixedPaginationDots(currentPage, currentWordFilteredSentences.length),
        );
      },
    );
  }

// 10'dan az sayfa için statik pagination dots
  Widget _buildFixedPaginationDots(int currentPage, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
            (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == currentPage ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == currentPage ? Colors.teal : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

// 10'dan fazla sayfa için kaydırılabilir pagination dots
  Widget _buildScrollablePaginationDots(int currentPage, WordDetail word) {
    List<Map<String, dynamic>> currentWordFilteredSentences =
        _wordFilteredSentences[word.id] ?? [];

    return LayoutBuilder(
        builder: (context, constraints) {
          // Kaydırılabilir genişlik için mevcut genişlik
          final availableWidth = constraints.maxWidth;

          // Her bir noktanın genişliği (margin dahil)
          const dotWidth = 16.0; // 8 dot + 8 margin
          const activeDotWidth = 32.0; // 24 dot + 8 margin

          // Ekranda gösterilebilecek maksimum nokta sayısı
          final maxVisibleDots = (availableWidth - activeDotWidth) ~/ dotWidth;

          // Başlangıç ve bitiş indeksi
          int startIdx = 0;
          int endIdx = currentWordFilteredSentences.length - 1;

          // Eğer nokta sayısı ekran sığacağından fazlaysa, aktif sayfaya göre aralık belirle
          if (currentWordFilteredSentences.length > maxVisibleDots) {
            // Aktif nokta mümkün olduğunca ortada görünsün
            final halfVisible = (maxVisibleDots - 1) ~/ 2;

            // Başlangıç indeksi hesapla
            startIdx = currentPage - halfVisible;

            // Sınırları ayarla
            if (startIdx < 0) {
              startIdx = 0;
            }

            // Bitiş indeksi hesapla
            endIdx = startIdx + maxVisibleDots - 1;

            // Bitiş indeksi toplam sayıyı aşmasın
            if (endIdx >= currentWordFilteredSentences.length) {
              endIdx = currentWordFilteredSentences.length - 1;
              // Başlangıç indeksini tekrar ayarla
              startIdx = endIdx - maxVisibleDots + 1;
              if (startIdx < 0) startIdx = 0;
            }
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Sol ok göstergesi (gerekirse)
                if (startIdx > 0)
                  GestureDetector(
                    onTap: () {
                      _sentencePageControllers[word.id]!.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),

                // Görünür noktalar
                ...List.generate(
                  endIdx - startIdx + 1,
                      (i) {
                    final index = i + startIdx;
                    return GestureDetector(
                      onTap: () {
                        _sentencePageControllers[word.id]!.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == currentPage
                              ? Colors.teal
                              : (_isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),

                // Sağ ok göstergesi (gerekirse)
                if (endIdx < currentWordFilteredSentences.length - 1)
                  GestureDetector(
                    onTap: () {
                      _sentencePageControllers[word.id]!.animateToPage(
                        currentWordFilteredSentences.length - 1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
              ],
            ),
          );
        });
  }

  // 10'dan fazla sayfa için kaydırılabilir pagination dots


  void _loadStarredStatusAsync() async {
    final service = StarredWordsService();
    final starredWordIds = await service.loadStarredWords(widget.classroomId, widget.studySetId);
    print('Yüklenen yıldızlı kelimeler: $starredWordIds');

    setState(() {
      for (var word in widget.words) {
        bool isStarred = starredWordIds.contains(word.id);
        starredNotifiers[word.id] = ValueNotifier<bool>(isStarred); // Bu satır değişti
        starredStatus[word.id] = isStarred;
      }
      _updateStarredWordCount();
    });
  }

  Widget buildWordDetail(WordDetail word) {
    String fullImageUrl = word.image != null
        ? "https://cloud.phdakademi.com/uploads/kelibu.net/${word.image}"
        : "https://kelibu.net/images/defaultimage.png";

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kelime başlığı, gif ve yıldız
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  word.word ?? '', // Null check for word
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade700,
                                  ),
                                  minFontSize: 18, // Minimum font size
                                  maxLines: 1, // Text appears in a single line
                                  overflow: TextOverflow.ellipsis, // Shows ellipsis when text overflows
                                ),
                              ],
                            ),
                          ),
                          // GIF animasyonu
                          SizedBox(
                            width: 70.w, // Responsive genişlik
                            height: 70.h, // Responsive yükseklik
                            child: GifPlayer(videoName: word.word),
                          ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: starredNotifiers[word.id] ?? ValueNotifier(false),
                      builder: (_, isStarred, __) => AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        child: widget.isStarred
                            ? SizedBox.shrink()
                            : IconButton(
                          icon: Icon(
                            isStarred ? Icons.star : Icons.star_border,
                            color: isStarred ? Colors.amber : Colors.grey,
                            size: 32,
                          ),
                          onPressed: () => _toggleStar(word, starredNotifiers[word.id]!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      if (word.defination != null && word.defination != 'NULL' && word.defination!.isNotEmpty) {
                        speak(word.defination!);
                      }
                    },
                    child: Text(
                      (word.defination == 'NULL' || word.defination == null)
                          ? 'Tanım bulunamadı'
                          : word.defination!,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w400,
                        height: 1.6,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 2,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.teal.shade200,
                        Colors.teal.shade50,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                FutureBuilder<String?>(
                  future: getReminderNote(word.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    String currentNote = snapshot.data ?? '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hatırlatma Notu',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal.shade700,
                          ),
                        ),
                        SizedBox(height: 8),
                        InkWell(
                          onTap: () => _editReminderNote(word.id, currentNote),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              currentNote.isEmpty ? 'Not eklemek için tıklayın' : currentNote,
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                color: Colors.black87,
                                fontStyle: currentNote.isEmpty ? FontStyle.italic : FontStyle.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 24),
                // Kelime türü ve ses
                Row(
                  children: [
                    Text(
                      word.type ?? 'Bilinmiyor',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.volume_up, color: Colors.teal.shade500),
                      onPressed: () => speak(word.word),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Kelime resmi
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    fullImageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/logo.png',
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
                SizedBox(height: 24),

                // Kelime anlamı
                Text(
                  'Anlam',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade700,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    word.meaning,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Örnek cümleler
                Text(
                  'Örnek Cümleler',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade700,
                  ),
                ),
                SizedBox(height: 8),
                _buildSentencesSection(word),
                SizedBox(height: 24),
                buildAudioNoteWidget(),

                // Synonyms
                if (word.synonyms.isNotEmpty) ...[
                  buildSynonymsSection(word.synonyms),
                  SizedBox(height: 24),
                ],

                // Türemeler
                if (word.derivations.isNotEmpty) ...[
                  buildDerivationsSection(word.derivations),
                  SizedBox(height: 24),
                ],

                // Collocations
                if (word.collocations.isNotEmpty) ...[
                  buildCollocationsSection(word.collocations),
                ],

                // FloatingActionButton için ekstra boşluk
                SizedBox(height: 80),
              ],
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 200),
            child: ValueListenableBuilder<bool>(
              valueListenable: _isAtBottom,
              builder: (context, isAtBottom, child) {
                return FloatingActionButton.extended(
                  backgroundColor: Colors.teal.shade700,
                  icon: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return RotationTransition(
                        turns: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      isAtBottom ? Icons.arrow_upward : Icons.arrow_downward,
                      key: ValueKey<bool>(isAtBottom),
                      color: Colors.white,
                    ),
                  ),
                  label: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: Text(
                      isAtBottom ? 'Yukarı Çık' : 'Aşağı İn',
                      key: ValueKey<bool>(isAtBottom),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (isAtBottom) {
                      _scrollToTop();
                    } else {
                      _scrollToBottom();
                    }
                    HapticFeedback.lightImpact();
                  },
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  Future<List<Map<String, dynamic>>> _loadSentencesFromDatabase(String word) async {
    final dbHelper = DatabaseHelper();
    try {
      final db = await dbHelper.database;

      // Temel kelime formları oluştur
      List<String> wordForms = [];

      // Tırnak işaretleri olmadan kelime formlarını ekle
      wordForms.add(word);
      wordForms.add("${word}ing");
      wordForms.add("${word}s");

      if (word.endsWith('y')) {
        String base = word.substring(0, word.length - 1);
        wordForms.add("${base}ies");
      } else if (word.endsWith('e')) {
        String base = word.substring(0, word.length - 1);
        wordForms.add("${base}ing");
      }

      // Basit bir test sorgusu ile deneyelim
      print("Aranan kelimeler: $wordForms");

      // FTS4 için optimize edilmiş sorgu - tüm terimleri tek bir MATCH içinde OR ile birleştir
      String queryTerms = wordForms.join(" OR ");

      final List<Map<String, dynamic>> results = await db.rawQuery(
          "SELECT * FROM sentences WHERE sentences MATCH ?",
          [word + "*"] // kelime kökü araması için yıldız kullanın
      );

      print("Bulunan sonuç sayısı: ${results.length}");

      return results;
    } catch (e) {
      print("Error getting sentences for word '$word': $e");
      return [];
    }
  }
  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }
  void _scrollToSection(String sectionName) {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      bool sectionFound = false;
      double targetOffset = 0;

      void searchForSection(Element element) {
        if (element.widget is Text) {
          Text textWidget = element.widget as Text;
          if (textWidget.data == sectionName) {
            final RenderBox renderBox = element.renderObject as RenderBox;
            final position = renderBox.localToGlobal(Offset.zero);
            targetOffset = position.dy;
            sectionFound = true;
          }
        }
        if (!sectionFound) {
          element.visitChildren(searchForSection);
        }
      }

      (context as Element).visitChildElements(searchForSection);

      if (sectionFound) {
        // Ekranın yüksekliğini al
        final screenHeight = MediaQuery.of(context).size.height;
        // AppBar'ın yüksekliğini al (varsa)
        final appBarHeight = AppBar().preferredSize.height;
        // Status bar'ın yüksekliğini al
        final statusBarHeight = MediaQuery.of(context).padding.top;

        // Hedef offseti ayarla
        targetOffset = max(0, targetOffset - (screenHeight / 4) + appBarHeight + statusBarHeight);

        _scrollController.animateTo(
          targetOffset,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        showNotFoundMessage();
      }
    });
  }
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOut,
    ).then((_) {
      _isAtBottom.value = false; // Yukarı çıktıktan sonra "Aşağı İn" durumuna geri dön
    });
  }
  void _scrollToOffset(double offset) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    final adjustedOffset = max(0.0, offset - (screenHeight / 3) + appBarHeight + statusBarHeight);

    _scrollController.animateTo(
      adjustedOffset,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }
  void _editReminderNote(int wordId, String currentNote) {
    TextEditingController _noteController = TextEditingController(text: currentNote);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.teal, width: 3),
        ),
        title: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Beyin Fırtınası Zamanı!',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kelimeyi nasıl hatırlayacağını yaz, ama sakın unutma! 😉',
              style: GoogleFonts.indieFlower(fontSize: 16),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Fikirlerini buraya dök...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.amber, width: 2),
                ),
                filled: true,
                fillColor: Colors.yellow[50],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            icon: Icon(Icons.cancel, color: Colors.white),
            label: Text(
              'Vazgeçtim',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.save, color: Colors.white),
            label: Text(
              'Dâhice!',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await saveReminderNote(wordId, _noteController.text);
              Navigator.of(dialogContext).pop();

              // SnackBar'ı göster
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Notun kaydedildi, unutma sakın! 🧠💡',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.teal,
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );

              setState(() {});
            },
          ),
        ],
      ),
    );
  }
  void _findAndScrollToSection(String sectionName) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      void searchForSection(Element element) {
        if (element.widget is Text) {
          Text textWidget = element.widget as Text;
          if (textWidget.data == sectionName) {
            final RenderBox renderBox = element.renderObject as RenderBox;
            final position = renderBox.localToGlobal(Offset.zero);
            sectionOffsets[sectionName] = position.dy;
            _scrollToOffset(position.dy);
          }
        }
        element.visitChildren(searchForSection);
      }

      (context as Element).visitChildElements(searchForSection);

      if (sectionOffsets[sectionName] == -1) {
        showNotFoundMessage();
      }
    });
  }
  void showNotFoundMessage() {
    if (!mounted) return;

    final messages = [
      "Oops! Bu bölüm henüz keşfedilmemiş. Belki de siz keşfedeceksiniz?",
      "Bu bölüm şu an tatilde. Daha sonra tekrar uğrayın!",
      "Bu bölüm henüz keşfedilmemiş, eğer varsa Veysel Hoca elbet bulup ekleyecektir.",
      "Veysel Hoca bu bölümü aramaya çıktı. Dönüşünde muhteşem bir içerikle gelecek!",
      "Bu bölüm, Veysel Hoca'nın gizli laboratuvarında geliştiriliyor. Sabırlı olun!",
      "Veysel Hoca bu bölümü bulmak için Indiana Jones ile birlikte maceraya çıktı.",
      "Bu bölüm, Veysel Hoca'nın beyninin derinliklerinde. Çıkarma operasyonu planlanıyor.",
      "Veysel Hoca bu bölümü Mariana Çukuru'nda arıyor. Derinlere daldıkça, içerik zenginleşiyor!",
      "Bu bölüm, Veysel Hoca'nın rüyalarında şekilleniyor. Uyanınca hemen ekleyecek!",
      "Veysel Hoca, bu bölümü bulmak için zamanı ve mekanı aşıyor. Einstein bile şaşkın!",
      "Bu bölüm, Veysel Hoca'nın sakal tellerinin arasında saklanıyor. Bulunması an meselesi!",
      "Veysel Hoca, bu bölümü yazmak için ilham perileriyle pazarlık yapıyor. Sonuç yakında!",
      "Bu bölüm saklambaç oynuyor. Bulursanız bize de haber verin!",
      "Bu bölüm quantum fiziği kullanarak başka bir boyuta geçmiş olabilir.",
      "Bu bölüm henüz yazılmamış. Belki de geleceğin bestseller'ı?",
      "Bu bölüm, UFO'lar tarafından kaçırılmış olabilir. Araştırıyoruz!",
      "Bu bölüm, Bermuda Üçgeni'nde kaybolmuş. Arama çalışmaları sürüyor.",
      "Bu bölüm, zaman yolculuğuna çıktı. Gelecekten bilgilerle dönecek!",
      "Bu bölüm, dijital detoksa girdi. Biraz offline takılıyor.",
      "Bu bölüm, Matrix'e giriş yaptı. Kırmızı hap mı, mavi hap mı?",
      "Bu bölüm, şu anda bir Escape Room'da. Çıkış yolunu bulmaya çalışıyor.",
      "Bu bölüm, evrim geçiriyor. Gelişmiş haliyle yakında döner!",
      "Bu bölüm, Hogwarts'a kabul edildi. Büyücülük eğitimi alıyor.",
      "Bu bölüm, süper kahraman olmak için eğitimde. Yakında kurtarmaya gelecek!",
      "Bu bölüm, şu anda bir zamanlar makinesinde. Hangi yüzyılda olduğunu bilmiyoruz!",
      "Bu bölüm, uzayda bir galaksi turu yapıyor. Dönüşte fotoğrafları göstereceğiz.",
      "Bu bölüm, sanal gerçeklikte kayboldu. Gerçek dünyaya dönmesi için çalışıyoruz.",
      "Bu bölüm, bir LEGO setine dönüştü. Parçaları topluyoruz.",
      "Bu bölüm, bir Pokemon oldu. Onu yakalamaya çalışıyoruz!",
      "Bu bölüm, bir bilgisayar oyununda level atlamaya çalışıyor. Başarılar diliyoruz!",
    ];

    final randomMessage = messages[Random().nextInt(messages.length)];

    _scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          randomMessage,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal.shade600,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Anladım',
          textColor: Colors.white,
          onPressed: () {
            _scaffoldMessenger.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  void _toggleStar(WordDetail word, ValueNotifier<bool> isStarredNotifier) async {
    final service = StarredWordsService();
    final newStatus = !isStarredNotifier.value;

    await service.toggleWordStarStatus(word.id, newStatus, widget.classroomId, widget.studySetId);
    setState(() {
      isStarredNotifier.value = newStatus; // UI'ı güncelleyin
      starredStatus[word.id] = newStatus; // Bu eklemeyi unutmayın
      _updateStarredWordCount();
    });
  }
  void _updateStarredWordCount() {
    int newCount = starredStatus.values.where((isStarred) => isStarred).length;
    animatedStarredCount.value = newCount; // Bu satırı ekledim
  }
  TableRow buildTableRow(String term, String meaning) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            term,
            style: GoogleFonts.roboto(fontSize: 18, color: _isDarkMode ? darkModeColors["text"] : lightModeColors["text"]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            meaning,
            style: GoogleFonts.roboto(fontSize: 18, color: Colors.teal),
          ),
        ),
      ],
    );
  }
// Ortak bir widget oluşturma fonksiyonu
  Widget buildSectionWidget({
    required String title,
    required List<Widget> children,
    Color titleColor = Colors.teal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: titleColor),
          ),
        ),
        ...children,
        const SizedBox(height: 20),
      ],
    );
  }

// Ortak bir liste öğesi oluşturma fonksiyonu
  Widget buildListItem({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required IconData icon,
    required Color iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: subtitle != null
              ? Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
          )
              : null,
        ),
      ),
    );
  }

// Synonyms bölümü
  Widget buildSynonymsSection(List<Synonym> synonyms) {
    var uniqueSynonyms = {for (var s in synonyms) s.tanim: s}.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.sync_alt_rounded,
                color: Colors.indigo,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                "Eş anlamlılar",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.withOpacity(0.1),
                Colors.indigo.withOpacity(0.05)
              ],
            ),
          ),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: uniqueSynonyms.map((synonym) => GestureDetector(
              onTap: () => speak(synonym.tanim),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.indigo.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  synonym.tanim,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.indigo.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
// Collocations bölümü
  Widget buildCollocationsSection(List<Collocation> collocations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.link_rounded,
                color: Colors.indigo,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                "Collocations",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
        ...collocations.map((collocation) => GestureDetector(
          onTap: () => collocation.definition != null
              ? speak(collocation.definition!)
              : null,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.indigo.withOpacity(0.1),
                  Colors.indigo.withOpacity(0.05)
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collocation.definition ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  collocation.anlam ?? '',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }
  Future<void> saveReminderNote(int wordId, String note) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminder_$wordId', note);
  }

  Future<String?> getReminderNote(int wordId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('reminder_$wordId');
  }
// Derivations bölümü
  Widget buildDerivationsSection(List<Derivation> derivations) {
    var groupedDerivations = groupBy(derivations, (d) => d.type.toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.account_tree_rounded,
                color: Colors.indigo,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                "Türemeler",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
        if (groupedDerivations.containsKey('verb'))
          buildDerivationList("Fiiller", groupedDerivations['verb']!, Icons.run_circle, Colors.lightBlueAccent),
        if (groupedDerivations.containsKey('noun'))
          buildDerivationList("İsimler", groupedDerivations['noun']!, Icons.account_balance, Colors.amber),
        if (groupedDerivations.containsKey('adjective'))
          buildDerivationList("Sıfatlar", groupedDerivations['adjective']!, Icons.adjust, Colors.purpleAccent),
        if (groupedDerivations.containsKey('adverb'))
          buildDerivationList("Zarflar", groupedDerivations['adverb']!, Icons.airplanemode_active, Colors.greenAccent),
      ],
    );
  }

  Widget buildDerivationList(String title, List<Derivation> derivations, IconData icon, Color iconColor) {
    var uniqueDerivations = {for (var d in derivations) d.definition: d}.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...uniqueDerivations.map((derivation) => _buildDerivationItem(derivation, iconColor)),
      ],
    );
  }

  Widget _buildDerivationItem(Derivation derivation, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => speak(derivation.definition),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    derivation.definition,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                  if (derivation.anlam != null) ...[
                    SizedBox(height: 4),
                    Text(
                      derivation.anlam!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        )
      )
    );
  }
  Widget buildSentencePageView(Future<List<String>> sentencesFuture, PageController controller) {
    return FutureBuilder<List<String>>(
      future: sentencesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 100,
                  height: 100,
                ),
                SizedBox(height: 20),
                SpinKitWave(
                  color: Colors.teal,
                  size: 50.0,
                ),
                SizedBox(height: 20),
                Text(
                  'Senin için örnek cümleler arıyorum...',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    color: _isDarkMode ? darkModeColors["text"] : lightModeColors["text"],
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Cümleler yüklenirken hata oluştu',
              style: GoogleFonts.roboto(
                fontSize: 18,
                color: Colors.red,
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Cümle bulunamadı',
              style: GoogleFonts.roboto(
                fontSize: 18,
                color: _isDarkMode ? darkModeColors["text"] : lightModeColors["text"],
              ),
            ),
          );
        }

        List<String> sentences = snapshot.data!;

        return Column(
          children: [
            // Uyarı mesajı
            GestureDetector(
              onTap: () => _showWarningDialog(context),
              child: Container(
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade600),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Örnek cümleler hakkında önemli bilgi',
                        style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.amber.shade800, size: 16),
                  ],
                ),
              ),
            ),
            Container(
              height: 200,
              child: PageView.builder(
                controller: controller,
                itemCount: sentences.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () => speak(sentences[index]),
                    child: Container(
                      margin: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: _isDarkMode ? darkModeColors["cardBackground"] : lightModeColors["cardBackground"],
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          sentences[index],
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            color: _isDarkMode ? darkModeColors["text"] : lightModeColors["text"],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
                onPageChanged: (index) {
                  _currentSentenceIndex.value = index;
                },
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: _currentSentenceIndex,
              builder: (_, value, __) {
                return Container(
                  margin: EdgeInsets.only(top: 10),
                  padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    '${value + 1}/${sentences.length}',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
  void _showWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: ContentBox(context),
        );
      },
    );
  }
  Widget buildAudioNoteWidget() {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF0D3B39) : Color(0xFFE0F4F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isDarkMode ? Color(0xFF1D5C5A) : Color(0xFF80CBC4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: _isDarkMode ? Color(0xFF4DB6AC) : Color(0xFF26A69A),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kelimelerin sesli okunuşunu dinlemek için üzerlerine tıklayabilirsiniz.',
              style: TextStyle(
                color: _isDarkMode ? Color(0xFF4DB6AC) : Color(0xFF26A69A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget ContentBox(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(left: 20, top: 65, right: 20, bottom: 20),
          margin: EdgeInsets.only(top: 45),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                offset: Offset(0, 10),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
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
        ),
        Positioned(
          left: 20,
          right: 20,
          child: CircleAvatar(
            backgroundColor: Colors.teal,
            radius: 45,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(45)),
              child: Icon(Icons.info_outline, color: Colors.white, size: 50),
            ),
          ),
        ),
      ],
    );
  }

  Widget bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  void filterWords(String query) {
    setState(() {
      filteredWords = widget.words.where((word) {
        return word.word.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }
}
class SideMenu extends StatefulWidget {
  final Function(String) onSectionSelected;
  final bool isExpanded;
  final Function(bool) onExpandChanged;

  SideMenu({
    required this.onSectionSelected,
    required this.isExpanded,
    required this.onExpandChanged,
  });

  @override
  _SideMenuState createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _widthAnimation = Tween<double>(begin: 60, end: 200).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (widget.isExpanded) {
      _animationController.value = 1.0;
    }

  }

  @override
  void didUpdateWidget(SideMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    widget.onExpandChanged(!widget.isExpanded);
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            color: Colors.teal.shade700,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildToggleButton(),
              Expanded(
                child: ListView(
                  children: [
                    _buildMenuItem(Icons.sync_alt, 'Synonyms'),
                    _buildMenuItem(Icons.format_quote, 'Örnek Cümleler'),
                    _buildMenuItem(Icons.account_tree, 'Türemeler'),
                    _buildMenuItem(Icons.link, 'Collocations'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: IconButton(
        icon: Icon(
          widget.isExpanded ? Icons.chevron_left : Icons.chevron_right,
          color: Colors.white,
        ),
        onPressed: _toggleMenu,
      ),
    );
  }


  Widget _buildMenuItem(IconData icon, String section) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: widget.isExpanded
          ? Text(
        section,
        style: TextStyle(color: Colors.white),
        overflow: TextOverflow.ellipsis,
      )
          : null,
      onTap: () {
        widget.onSectionSelected(section);
        // Menüyü daralt
        widget.onExpandChanged(false);
      },
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      hoverColor: Colors.white.withOpacity(0.1),
    );
  }
}