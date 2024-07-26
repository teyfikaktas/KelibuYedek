import 'dart:async';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

import '../globalDart/urls.dart';
import '../shared_preferences/shared_preferences.dart';
import '../variables.dart';
import 'loadingIndicator.dart';
import 'package:collection/collection.dart';


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

class _StudyScreenState extends State<StudyScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  Map<int, ValueNotifier<bool>> starredNotifiers = {};
  late TabController _tabController;
  bool _isMenuExpanded = false;
  late ScaffoldMessengerState _scaffoldMessenger;
  @override
  Timer? _scrollDebounce;

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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_scrollListener);

    _pageController = PageController(initialPage: 0);
    _loadDarkModePreference();
    filteredWords = widget.words; // Başlangıçta tüm kelimeleri göster
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userID = userProvider.userId;
    int currentPoints = userProvider.point; // Mevcut puanı al ve int'e çevir. Eğer çevrilemezse 0 varsay.
    userProvider.addPoint((currentPoints + 1)); // Puanı 3 artır ve güncelle.
    ApiService().updateUserPointTimePeriod(userProvider.userId, currentPoints,1); // API üzerinden puanı güncelleyin

    _sentencePageController = PageController(initialPage: 0);
    for (var word in widget.words) {
      _sentencePageControllers[word.id] = PageController(initialPage: 0);
    }
    _loadStarredStatusAsync();
    loadExampleSentences();

    // İlk kelimenin seslendirilmesi için ekleme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.words.isNotEmpty) {
        speak(widget.words.first.word);
      }
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
  @override
  void dispose() {
    _pageController.dispose();
    _selectedPageIndex.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _sentencePageController.dispose();
    for (var controller in _sentencePageControllers.values) {
      controller.dispose();
    }
    for (var controller in _sentencePageControllers.values) {
      controller.dispose();
    }
// Kontrolcüyü temizle
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
                  'Çalış',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
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
          _buildRoundedIconButton(
            Icons.help,
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
  Widget _buildRoundedIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        primary: color,
        shape: CircleBorder(),
        padding: EdgeInsets.all(12.sp),
      ),
      child: Icon(icon, color: Colors.white, size: 24.sp),
    );
  }


  Widget _buildQuickAccessMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.white),
      onSelected: (String result) {
        switch (result) {
          case 'examples':
            _scrollToSection('Örnek Cümleler');
            break;
          case 'synonyms':
            _scrollToSection('Synonyms');
            break;
          case 'derivations':
            _scrollToSection('Türemeler');
            break;
          case 'collocations':
            _scrollToSection('Collocations');
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'synonyms',
          child: Text('Synonymsı Gör'),
        ),
        PopupMenuItem<String>(
          value: 'examples',
          child: Text('Örnek Cümleleri Gör'),
        ),
        PopupMenuItem<String>(
          value: 'derivations',
          child: Text('Türemeleri Gör'),
        ),
        PopupMenuItem<String>(
          value: 'Collocations',
          child: Text('Collocationsi Gör'),
        ),
      ],
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
                  SizedBox(width: 4),
                  Text(
                    _showOnlyStarred ? 'Yıldızlı' : 'Tümü',
                    style: GoogleFonts.poppins(
                      color: _showOnlyStarred ? Colors.yellow : Colors.white,
                      fontSize: 14,
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


  Widget _buildQuickAccessTabs() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: Colors.white.withOpacity(0.2),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: [
          _buildTab(Icons.sync_alt, 'Synonyms'),
          _buildTab(Icons.format_quote, 'Örnek Cümleler'),
          _buildTab(Icons.account_tree, 'Türemeler'),
          _buildTab(Icons.link, 'Collocations'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              _scrollToSection('Synonyms');
              break;
            case 1:
              _scrollToSection('Örnek Cümleler');
              break;
            case 2:
              _scrollToSection('Türemeler');
              break;
            case 3:
              _scrollToSection('Collocations');
              break;
          }
        },
      ),
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            SizedBox(width: 8),
            Text(label),
          ],
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
                        minFontSize: 12,
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
                        minFontSize: 10,
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

  void _onWordTap(WordDetail word, int index) {
    Navigator.of(context).pop(); // Drawer'ı kapat
    int originalIndex = widget.words.indexOf(word);
    _targetPageIndex = index;  // Hedef kelimenin indeksini ayarla

    _pageController.jumpToPage(originalIndex); // animateToPage yerine jumpToPage kullanın
    setState(() {
      currentWordIndex = originalIndex;
      _selectedPageIndex.value = originalIndex;
    });

    // Sadece 1 puan artır
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int currentPoints = userProvider.point;
    userProvider.addPoint(currentPoints + 1);
    ApiService().updateUserPointTimePeriod(userProvider.userId, currentPoints + 1, 1);
  }
  Widget buildPageView() {
    List<WordDetail> displayedWords = getDisplayedWords();
    return PageView.builder(
      key: PageStorageKey<String>('pageView'),
      controller: _pageController,
      itemCount: displayedWords.length,
      // PageView.builder içinde onPageChanged kısmını güncelleyin
      onPageChanged: (index) {
        setState(() {
          _selectedPageIndex.value = index;
          currentWordIndex = index;
          _scrollToTop(); // Sayfayı yukarı kaydır
          _isAtBottom.value = false; // "Aşağı İn" durumuna geri dön
        });
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
                height: Curves.easeOut.transform(value) * 600,
                width: Curves.easeOut.transform(value) * 400,
                child: child,
              ),
            );
          },
          child: buildWordDetail(displayedWords[index]),
        );
      },
    );
  }
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
                // Kelime başlığı ve yıldız
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        word.word,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: starredNotifiers[word.id] ?? ValueNotifier(false),
                      builder: (_, isStarred, __) => AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        child: widget.isStarred
                            ? SizedBox.shrink()  // Eğer widget.isStarred true ise, boş bir widget döndür
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
                    fit: BoxFit.fill,
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
                buildSentencePageView(exampleSentences[word.id] ?? Future.value(["Cümle bulunamadı"]), _sentencePageControllers[word.id]!),
                SizedBox(height: 24),

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
            )
          ),
        ),
      ],
    );
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
              primary: Colors.redAccent,
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
              primary: Colors.green,
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
            style: Theme.of(context).textTheme.headline6?.copyWith(color: titleColor),
          ),
        ),
        ...children,
        SizedBox(height: 20),
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
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.transparent, // GestureDetector'ın tüm alanı kaplaması için
            child: ListTile(
              leading: Icon(icon, color: iconColor),
              title: Text(
                title,
                style: Theme.of(context).textTheme.subtitle1,
              ),
              subtitle: subtitle != null
                  ? Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyText2,
              )
                  : null,
            ),
          ),
        )
    );
  }

// Synonyms bölümü
  Widget buildSynonymsSection(List<Synonym> synonyms) {
    var uniqueSynonyms = {for (var s in synonyms) s.tanim: s}.values.toList();

    return buildSectionWidget(
      title: "Synonyms",
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: uniqueSynonyms.map((synonym) => Semantics(
            button: true,
            label: 'Synonym: ${synonym.tanim}',
            child: InkWell(
              onTap: () => speak(synonym.tanim),
              child: Chip(
                label: Text(synonym.tanim),
                backgroundColor: Theme.of(context).chipTheme.backgroundColor,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

// Collocations bölümü
  Widget buildCollocationsSection(List<Collocation> collocations) {
    return buildSectionWidget(
      title: "Collocations",
      children: collocations.map((collocation) => Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.group_work,
              color: Colors.teal,
              size: 24,
            ),
          ),
          title: Text(
            collocation.definition ?? '',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              collocation.anlam ?? '',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.volume_up, color: Colors.teal),
            onPressed: () => collocation.definition != null ? speak(collocation.definition!) : null,
          ),
        ),
      )).toList(),
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

    return buildSectionWidget(
      title: "Türemeler",
      children: [
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
                style: Theme.of(context).textTheme.headline6?.copyWith(
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
                    style: Theme.of(context).textTheme.subtitle1?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                  if (derivation.anlam != null) ...[
                    SizedBox(height: 4),
                    Text(
                      derivation.anlam!,
                      style: Theme.of(context).textTheme.bodyText2?.copyWith(
                        color: Colors.grey[600],
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
                  'assets/logo.png', // Uygulamanızın logo dosya yolunu buraya ekleyin
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
  void filterWords(String query) {
    setState(() {
      filteredWords = widget.words.where((word) {
        return word.word.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }
}class SideMenu extends StatefulWidget {
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

class _SideMenuState extends State<SideMenu> with SingleTickerProviderStateMixin {
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