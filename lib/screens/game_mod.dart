import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // Google Fonts paketini import edin.
import 'package:kelibu/Models/wordDetaik.dart'; // WordDetail modelinizin importu
import 'package:kelibu/api.dart';
import 'package:kelibu/providers/user_provider.dart'; // UserProvider importu
import 'package:kelibu/screens/classic_kelibu.dart'; // FlashCardScreen sayfasının importu
import 'package:kelibu/screens/flash_card.dart'; // FlashCardScreen sayfasının importu
import 'package:kelibu/screens/personelcollection/personelcollenction.dart';
import 'package:kelibu/screens/quiz.dart';
import 'package:kelibu/screens/video_player.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../event.dart';
import '../event_bus.dart';
import '../globalDart/urls.dart';
import '../shared_preferences/shared_preferences.dart';
import '../variables.dart';
import '../widgets/match_mode_widget.dart';
import 'games/WordQuizScreen.dart';
import 'games/strach.dart';
import 'listen_write.dart'; // StudyScreen'i içe aktar
import 'study_screen.dart'; // StudyScreen'i içe aktar

class CustomLoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animasyonu
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: Duration(seconds: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Image.asset(
                'assets/logo.png', // Logo dosyanızın yolunu buraya girin
                width: 80,
                height: 80,
              ),
            ),
            SizedBox(height: 20),
            // Pulsating efekti
            SpinKitPulse(
              color: Colors.blue,
              size: 50.0,
            ),
            SizedBox(height: 10),
            Text(
              'Yükleniyor...',
              style: TextStyle(
                color: Colors.blue[800],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameModeScreen extends StatefulWidget {
  final String studySetName;
  final int classroomId;
  final int studySetId;

  const GameModeScreen({
    Key? key,
    required this.studySetName,
    required this.classroomId,
    required this.studySetId,
  }) : super(key: key);

  @override
  _GameModeScreenState createState() => _GameModeScreenState();
}

class _GameModeScreenState extends State<GameModeScreen>
    with WidgetsBindingObserver {
  late Future<void> initializationFuture;
  late List<WordDetail> words;
  late Map<int, bool> starredWords;
  bool _showOnlyStarredWords = false;
  bool _isDarkMode = false;
  bool _isMeaningVisible = true;
  bool _isSearchPanelVisible = false;
  FlutterTts flutterTts = FlutterTts();
  TextEditingController _searchController = TextEditingController();
  List<WordDetail> _filteredWords = [];
  int _starredWordCount = 0;
  int _selectedMatchOption = 0;
  List<PersonalCollection> _userSets = [];
  bool _isLoadingSets = false;

  @override
  void initState() {
    super.initState();
    words = [];
    starredWords = {};
    initializationFuture =
        _initializeData(); // wordsFuture'ı burada başlatıyoruz.
    ApiService().logSetEntry('Oyun Modları', 'Oyun modlarına', '');
    _searchController.addListener(_filterWords);
    _loadUserSets();
    appEventBus.on<StarredWordsChangedEvent>().listen((event) async {
      await updateStarredWords();
    });
  }

  Future<void> _loadUserSets() async {
    setState(() {
      _isLoadingSets = true;
    });

    try {
      final apiService = ApiService();
      final collections = await apiService.getMyWordSets();

      setState(() {
        _userSets = collections
            .map((json) => PersonalCollection(
                  id: json['id'],
                  name: json['set_name'],
                  icon: Icons.collections_bookmark,
                  isShared: json['is_public'] ?? false,
                  wordCount: json['word_count'] ?? 0,
                  createdAt: DateTime.parse(json['created_at']),
                ))
            .toList();
        _isLoadingSets = false;
      });
    } catch (e) {
      setState(() {
        _userSets = [];
        _isLoadingSets = false;
      });
    }
  }

  Future<void> _addWordToUserSet(int setId, int wordId, String setName) async {
    try {
      final apiService = ApiService();
      await apiService.addWordToSet(
        wordSetId: setId,
        wordId: wordId,
      );

      Get.snackbar(
        "",
        "",
        titleText: Container(),
        messageText: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Kelime "$setName" setine eklendi! 🎉',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF58CC02),
        borderRadius: 16,
        duration: Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      );

      // Setleri yenile
      await _loadUserSets();
    } on ApiException catch (e) {
      Get.snackbar(
        "",
        "",
        titleText: Container(),
        messageText: Text(
          e.message,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.red,
        borderRadius: 16,
        duration: Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        "",
        "",
        titleText: Container(),
        messageText: Text(
          'Kelime eklenirken hata oluştu',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.red,
        borderRadius: 16,
        duration: Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
      );
    }
  }

// Modal açan fonksiyon:
  void _showAddToSetModal(WordDetail word) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.sp),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sete Ekle',
                          style: GoogleFonts.nunito(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: _isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '"${word.word}" kelimesini ekle',
                          style: GoogleFonts.nunito(
                            fontSize: 14.sp,
                            color:
                                _isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1),

            // Setler listesi
            Expanded(
              child: _isLoadingSets
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF58CC02),
                      ),
                    )
                  : _userSets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.collections_bookmark,
                                size: 64.sp,
                                color: _isDarkMode
                                    ? Colors.white24
                                    : Colors.black12,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Henüz setiniz yok',
                                style: GoogleFonts.nunito(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: _isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Önce bir set oluşturun',
                                style: GoogleFonts.nunito(
                                  fontSize: 14.sp,
                                  color: _isDarkMode
                                      ? Colors.white54
                                      : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16.sp),
                          itemCount: _userSets.length,
                          itemBuilder: (context, index) {
                            final set = _userSets[index];
                            final colors = [
                              [Color(0xFF58CC02), Color(0xFF4CAF50)],
                              [Color(0xFF1CB0F6), Color(0xFF0EA5E9)],
                              [Color(0xFFFFC800), Color(0xFFFF9600)],
                              [Color(0xFF9C27B0), Color(0xFF8E24AA)],
                              [Color(0xFFE91E63), Color(0xFFC2185B)],
                            ];
                            final colorPair =
                                colors[set.id.hashCode % colors.length];

                            return Container(
                              margin: EdgeInsets.only(bottom: 12.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: colorPair,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorPair[0].withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _addWordToUserSet(
                                        set.id, word.id, set.name);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: EdgeInsets.all(16.sp),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12.sp),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.collections_bookmark,
                                            color: Colors.white,
                                            size: 24.sp,
                                          ),
                                        ),
                                        SizedBox(width: 16.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                set.name,
                                                style: GoogleFonts.nunito(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                '${set.wordCount} kelime',
                                                style: GoogleFonts.nunito(
                                                  fontSize: 14.sp,
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.add_circle,
                                          color: Colors.white,
                                          size: 28.sp,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeData() async {
    await _loadDarkModePreference();
    await initializeStarredNotifiers();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isDarkMode = prefs.getBool("darkMode") ?? false;
      });
    }
  }

  Future<void> updateStarredWords() async {
    var starredWordsSet = await StarredWordsService()
        .loadStarredWords(widget.classroomId, widget.studySetId);
    setState(() {
      for (var word in words) {
        starredWords[word.id] = starredWordsSet.contains(word.id);
      }
    });
  }

  Future<void> initializeStarredNotifiers() async {
    String processedString =
        widget.studySetName.replaceAll('[', '').replaceAll(']', '');
    List<String> stringIds = processedString
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    List<int> wordIds = stringIds.map((id) => int.tryParse(id) ?? 0).toList();
    var starredWordsSet = await StarredWordsService()
        .loadStarredWords(widget.classroomId, widget.studySetId);

    var wordDetails = await ApiService().fetchWordsDetail(wordIds);

    if (mounted) {
      setState(() {
        words = wordDetails;
        _filteredWords = words;
        _starredWordCount = 0; // Başlangıçta sıfırla
        for (var word in words) {
          starredWords[word.id] = starredWordsSet.contains(word.id);
          if (starredWords[word.id]!) {
            _starredWordCount++; // Yıldızlı kelimeleri say
          }
        }
      });
    }
  }

  void _filterWords() {
    setState(() {
      _filteredWords = words
          .where((word) => word.word
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              activeColor,
                              activeColor.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: getResponsiveFontSize(context, 16),
                                fontWeight: FontWeight.w600,
                                color:
                                    _isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: GoogleFonts.inter(
                                fontSize: getResponsiveFontSize(context, 13),
                                color: _isDarkMode
                                    ? Colors.white60
                                    : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: _isDarkMode ? Colors.white54 : Colors.black38,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

// Toplu ekleme için modal:
  void _showBulkAddToSetModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.sp),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.library_add,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sete Ekle',
                          style: GoogleFonts.nunito(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: _isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '${words.length} kelimeyi başka sete ekle',
                          style: GoogleFonts.nunito(
                            fontSize: 14.sp,
                            color:
                                _isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1),

            // Setler listesi
            Expanded(
              child: _isLoadingSets
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF58CC02),
                      ),
                    )
                  : _userSets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.collections_bookmark,
                                size: 64.sp,
                                color: _isDarkMode
                                    ? Colors.white24
                                    : Colors.black12,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Henüz setiniz yok',
                                style: GoogleFonts.nunito(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: _isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16.sp),
                          itemCount: _userSets.length,
                          itemBuilder: (context, index) {
                            final set = _userSets[index];

                            // Mevcut seti filtrele
                            if (set.id == widget.studySetId) {
                              return SizedBox.shrink();
                            }

                            final colors = [
                              [Color(0xFF58CC02), Color(0xFF4CAF50)],
                              [Color(0xFF1CB0F6), Color(0xFF0EA5E9)],
                              [Color(0xFFFFC800), Color(0xFFFF9600)],
                              [Color(0xFF9C27B0), Color(0xFF8E24AA)],
                              [Color(0xFFE91E63), Color(0xFFC2185B)],
                            ];
                            final colorPair =
                                colors[set.id.hashCode % colors.length];

                            return Container(
                              margin: EdgeInsets.only(bottom: 12.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: colorPair,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorPair[0].withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await _addAllWordsToSet(set.id, set.name);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: EdgeInsets.all(16.sp),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12.sp),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.collections_bookmark,
                                            color: Colors.white,
                                            size: 24.sp,
                                          ),
                                        ),
                                        SizedBox(width: 16.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                set.name,
                                                style: GoogleFonts.nunito(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                '${set.wordCount} kelime',
                                                style: GoogleFonts.nunito(
                                                  fontSize: 14.sp,
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.add_circle,
                                          color: Colors.white,
                                          size: 28.sp,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAllWordsToSet(int setId, String setName) async {
    int successCount = 0;
    int errorCount = 0;

    // Progress dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(24.sp),
          margin: EdgeInsets.symmetric(horizontal: 40.w),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF58CC02)),
              SizedBox(height: 16.h),
              Text(
                'Kelimeler ekleniyor...',
                style: GoogleFonts.nunito(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    for (var word in words) {
      try {
        await ApiService().addWordToSet(
          wordSetId: setId,
          wordId: word.id,
        );
        successCount++;
      } catch (e) {
        errorCount++;
      }
    }

    Navigator.pop(context); // Progress dialog'u kapat

    // Sonuç mesajı
    Get.snackbar(
      "",
      "",
      titleText: Container(),
      messageText: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.sp),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              errorCount == 0 ? Icons.check_circle : Icons.info,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              errorCount == 0
                  ? '$successCount kelime "$setName" setine eklendi! 🎉'
                  : '$successCount kelime eklendi, $errorCount kelime eklenemedi',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: errorCount == 0 ? Color(0xFF58CC02) : Colors.orange,
      borderRadius: 16,
      duration: Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    );

    await _loadUserSets();
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    var screenSize = MediaQuery.of(context).size;
    int gridCount = screenSize.width > 600 ? 4 : 2;
    double aspectRatio = screenSize.width > 600 ? 1.5 : 2;
    bool isTablet = screenSize.width > 600;
    bool yatayEkran = MediaQuery.of(context).size.aspectRatio > 1.5;
    int childAspectRatio = isTablet ? 4 : 2;
    double crossAxisCount = yatayEkran ? 4 : 2;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int currentUserId = userProvider.userId;

    return Scaffold(
      backgroundColor: colors["background"],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          child: AppBar(
            elevation: 0,
            backgroundColor: colors["background"],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isDarkMode
                      ? [
                          Colors.deepPurple.shade900,
                          Colors.deepPurple.shade800,
                        ]
                      : [
                          Colors.deepPurple.shade400,
                          Colors.deepPurple.shade600,
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.extension, // veya başka bir oyun ikonu
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(width: 8),
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 200),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: getResponsiveFontSize(context, 22),
                  ),
                  child: Text('Oyun Modları'),
                ),
              ],
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
              splashRadius: 24,
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
            actions: [
              _buildRoundedIconButton(
                Icons.slow_motion_video_sharp,
                Colors.green.withOpacity(0.9),
                () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VideoPlayerScreen(videoUrl: AppUrls.gamescreen),
                    ),
                  );
                },
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: Icon(
                      _isSearchPanelVisible ? Icons.close : Icons.search,
                      color: Colors.white,
                      key: ValueKey<bool>(_isSearchPanelVisible),
                    ),
                  ),
                  splashRadius: 24,
                  onPressed: () {
                    setState(() {
                      _isSearchPanelVisible = !_isSearchPanelVisible;
                    });
                    HapticFeedback.lightImpact();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<void>(
        future: initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CustomLoadingIndicator();
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Bir hata oluştu: ${snapshot.error}',
                style: GoogleFonts.poppins(
                  color: colors["text"],
                  fontSize: getResponsiveFontSize(context, 16),
                ),
              ),
            );
          } else {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: _isSearchPanelVisible ? 60.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          hintText: 'Kelime ara...',
                          filled: true,
                          fillColor:
                              _isDarkMode ? Colors.grey[700] : Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCount,
                    childAspectRatio: aspectRatio,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildGameModeTile(
                      context,
                      "Eşleştir",
                      Colors.indigo,
                      Icons.compare_arrows,
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                          () {
                        showMatchModeDialog(context, _isDarkMode);
                      },
                    ),
                    _buildGameModeTile(
                      context,
                      "Klasik Kelibu",
                      Colors.deepPurple,
                      Icons.gamepad,
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                          () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => KelimeOyunu(
                              words: words,
                              classroomId: widget.classroomId,
                              studySetId: widget.studySetId,
                            ),
                          ),
                        );
                      },
                    ),
                  ]),
                ),
                SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCount,
                    childAspectRatio: aspectRatio,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildGameModeTile(
                      context,
                      "Öğren",
                      Colors.blue,
                      Icons.school,
                      TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                      () {
                        if (words.length < 4) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Text(
                                  'Ups! Kelimelerimiz Kaçmış!',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[800],
                                  ),
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 80,
                                        color: Colors.amber[800],
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                        'Öğren modundan en yüksek verimi almanız için en az 4 kelime gerekiyor. Haydi, biraz daha kelime ekleyelim!',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.amber[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    child: Text(
                                      'Tamam',
                                      style: GoogleFonts.poppins(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(
                                words: words,
                                classroomId: widget.classroomId,
                                studySetId: widget.studySetId,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    _buildGameModeTile(
                      context,
                      "Flash Kart",
                      Colors.green,
                      Icons.flash_on,
                      TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FlashCardScreen(
                              words: words,
                              classroomId: widget.classroomId,
                              studySetId: widget.studySetId,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildGameModeTile(
                      context,
                      "Çalış",
                      Colors.greenAccent,
                      Icons.work,
                      TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => StudyScreen(
                              words: words,
                              classroomId: widget.classroomId,
                              studySetId: widget.studySetId,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildGameModeTile(
                      context,
                      "Dinle",
                      Colors.deepOrangeAccent,
                      Icons.music_note,
                      TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ListenAndWriteScreen(
                              words: words,
                              classroomId: widget.classroomId,
                              studySetId: widget.studySetId,
                            ),
                          ),
                        );
                      },
                    ),
                  ]),
                ),

                SliverToBoxAdapter(
                  child: _buildQuestionPanel(colors),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildSettingsCard(
                        icon: _isMeaningVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        title: "Anlamları Göster",
                        value: _isMeaningVisible,
                        onChanged: (value) {
                          setState(() {
                            _isMeaningVisible = value;
                          });
                        },
                        activeColor: Colors.blue,
                      ),
                    ],
                  ),
                ),

                if (widget.classroomId != -2 && widget.studySetId != -2)
                  SliverToBoxAdapter(
                    child: _buildActionCard(
                      icon: Icons.add_to_photos,
                      title: "Tüm Kelimeleri Sete Ekle",
                      subtitle: "",
                      activeColor: Color(0xFF58CC02),
                      onTap: () {
                        if (words.isNotEmpty) {
                          _showBulkAddToSetModal();
                        }
                      },
                    ),
                  ),
                if (widget.classroomId != -2 && widget.studySetId != -2)
                  SliverToBoxAdapter(
                    child: _buildDuolingoStyleStarredWordsIndicator(),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      WordDetail word = _filteredWords[index];
                      bool isStarred = starredWords[word.id] ?? false;

                      if (_showOnlyStarredWords && !isStarred) {
                        return SizedBox.shrink();
                      }
                      return AnimatedBuilder(
                        animation:
                            ValueNotifier(starredWords[word.id] ?? false),
                        builder: (context, child) {
                          bool isStarred = starredWords[word.id] ?? false;
                          return TweenAnimationBuilder(
                            tween: ColorTween(
                              begin:
                                  _isDarkMode ? Colors.grey[800] : Colors.white,
                              end: isStarred
                                  ? (_isDarkMode
                                      ? Colors.amber.shade900.withOpacity(0.3)
                                      : Colors.amber.shade100)
                                  : (_isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.white),
                            ),
                            duration: Duration(milliseconds: 300),
                            builder: (context, Color? backgroundColor, child) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(
                                          _isDarkMode ? 0.3 : 0.05),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _navigateToWordDetail(word),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        word.word,
                                                        style:
                                                            GoogleFonts.inter(
                                                          fontSize:
                                                              getResponsiveFontSize(
                                                                  context, 18),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isStarred
                                                              ? (_isDarkMode
                                                                  ? Colors.amber
                                                                      .shade200
                                                                  : Colors.amber
                                                                      .shade800)
                                                              : (_isDarkMode
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black87),
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        word.type?.isNotEmpty ==
                                                                true
                                                            ? word.type!
                                                            : "Tip belirsiz",
                                                        style:
                                                            GoogleFonts.inter(
                                                          fontSize:
                                                              getResponsiveFontSize(
                                                                  context, 14),
                                                          fontStyle:
                                                              FontStyle.italic,
                                                          color: _isDarkMode
                                                              ? Colors.white60
                                                              : Colors.black45,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (widget.classroomId != -2 &&
                                                    widget.studySetId != -2)
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.add_circle_outline,
                                                      color: _isDarkMode
                                                          ? Color(0xFF58CC02)
                                                              .withOpacity(0.8)
                                                          : Color(0xFF58CC02),
                                                    ),
                                                    onPressed: () {
                                                      HapticFeedback
                                                          .lightImpact();
                                                      _showAddToSetModal(word);
                                                    },
                                                  ),

                                                // Yıldız Butonu
                                                if (widget.classroomId != -2 &&
                                                    widget.studySetId != -2)
                                                  IconButton(
                                                    icon: AnimatedSwitcher(
                                                      duration: Duration(
                                                          milliseconds: 300),
                                                      transitionBuilder:
                                                          (child, animation) {
                                                        return ScaleTransition(
                                                            scale: animation,
                                                            child: child);
                                                      },
                                                      child: Icon(
                                                        isStarred
                                                            ? Icons.star
                                                            : Icons.star_border,
                                                        key: ValueKey<bool>(
                                                            isStarred),
                                                        color: isStarred
                                                            ? (_isDarkMode
                                                                ? Colors.amber
                                                                    .shade300
                                                                : Colors.amber
                                                                    .shade600)
                                                            : (_isDarkMode
                                                                ? Colors.grey
                                                                    .shade400
                                                                : Colors.grey
                                                                    .shade600),
                                                      ),
                                                    ),
                                                    onPressed: () async {
                                                      setState(() {
                                                        starredWords[word.id] =
                                                            !isStarred;
                                                      });
                                                      await toggleStar(
                                                          word.id, isStarred);
                                                    },
                                                  ),
                                                // Ses Butonu
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.volume_up,
                                                    color: _isDarkMode
                                                        ? Colors.blue.shade300
                                                        : Colors.blue.shade700,
                                                  ),
                                                  onPressed: () =>
                                                      _speak(word.word),
                                                ),
                                              ],
                                            ),
                                            if (_isMeaningVisible) ...[
                                              SizedBox(height: 8),
                                              Text(
                                                word.meaning,
                                                style: GoogleFonts.inter(
                                                  fontSize:
                                                      getResponsiveFontSize(
                                                          context, 14),
                                                  color: isStarred
                                                      ? (_isDarkMode
                                                          ? Colors
                                                              .amber.shade100
                                                              .withOpacity(0.8)
                                                          : Colors
                                                              .amber.shade900
                                                              .withOpacity(0.8))
                                                      : (_isDarkMode
                                                          ? Colors.white70
                                                          : Colors.black54),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    childCount: _filteredWords.length,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
  Widget _buildQuestionPanel(Map<String, Color?> colors) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Color(0xFF5865F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xFF5865F2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF5865F2).withOpacity(_isDarkMode ? 0.3 : 0.4),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizSettingsScreen(
                        wordIds: _parseWordIds(widget.studySetName),
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.psychology_outlined,
                          color: Colors.white, size: 28),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Test yourself!",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: getResponsiveFontSize(context, 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_forward,
                          color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // YENİ badge
          Positioned(
            top: -4,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFFFF3B30),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF3B30).withOpacity(0.4),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                "YENİ",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  List<int> _parseWordIds(String wordIdsString) {
    if (wordIdsString.isEmpty) return [];
    return wordIdsString
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .where((id) => id != null)
        .cast<int>()
        .toList();
  }
  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required Color activeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return RotationTransition(
                            turns: child.key == ValueKey('visible')
                                ? Tween<double>(begin: 0.75, end: 1.0)
                                    .animate(animation)
                                : Tween<double>(begin: 1.0, end: 0.75)
                                    .animate(animation),
                            child: child,
                          );
                        },
                        child: Icon(
                          icon,
                          key: ValueKey(value),
                          color:
                              _isDarkMode ? Colors.white70 : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w500,
                            color: _isDarkMode ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: CupertinoSwitch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: activeColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToWordDetail(WordDetail word) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => StudyScreen(
        words: [word],
        classroomId: widget.classroomId,
        studySetId: widget.studySetId,
      ),
    ));
  }

  Future<void> toggleStar(int wordId, bool isStarred) async {
    try {
      await StarredWordsService().toggleWordStarStatus(
          wordId, !isStarred, widget.classroomId, widget.studySetId);
      setState(() {
        if (!isStarred) {
          _starredWordCount++;
        } else {
          _starredWordCount--;
        }
      });
      Fluttertoast.showToast(
        msg: isStarred ? 'Yıldız kaldırıldı' : 'Kelime yıldızlandı',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: isStarred ? Colors.redAccent : Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'İşlem başarısız oldu: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Widget _buildDuolingoStyleStarredWordsIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 28),
              SizedBox(width: 8),
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Text(
                  '$_starredWordCount / ${words.length}',
                  key: ValueKey<int>(_starredWordCount),
                  style: GoogleFonts.poppins(
                    fontSize: getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          Switch(
            value: _showOnlyStarredWords,
            onChanged: (value) {
              setState(() {
                _showOnlyStarredWords = value;
              });
            },
            activeColor: Colors.amber,
          ),
        ],
      ),
    );
  }

  Color _adjustColorForDarkMode(BuildContext context, Color color) {
    if (_isDarkMode) {
      double darknessFactor = 0.7;
      int red = (color.red * (1 - darknessFactor)).toInt();
      int green = (color.green * (1 - darknessFactor)).toInt();
      int blue = (color.blue * (1 - darknessFactor)).toInt();
      return Color.fromARGB(color.alpha, red, green, blue);
    }
    return color;
  }

  Widget _buildGameModeTile(BuildContext context, String title, Color color,
      IconData? icon, TextStyle textStyle,
      [VoidCallback? onTap]) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final padding = isSmallScreen ? 12.0 : 16.0;
    final iconSize = isSmallScreen ? 28.0 : 32.0;
    final fontSize = isSmallScreen ? 16.0 : 20.0;

    color = _adjustColorForDarkMode(context, color);

    return Padding(
      padding: EdgeInsets.all(8),
      child: Hero(
        tag: title, // Her buton için benzersiz bir tag
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap ??
                () {
                },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.7), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              padding: EdgeInsets.all(padding),
              child: Row(
                children: <Widget>[
                  if (icon != null) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: iconSize),
                    ),
                    SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
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

  bool hasEnoughWords() {
    return words.length < 4;
  }

  // Yardımcı Fonksiyon: Responsive Font Size
  double getResponsiveFontSize(BuildContext context, double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return baseSize * 1.5;
    } else if (screenWidth > 800) {
      return baseSize * 1.2;
    } else {
      return baseSize;
    }
  }

  Widget _buildModernModeOption(
    BuildContext context,
    String title,
    String description,
    int index,
    int selectedIndex,
    Color gradientStart,
    Color gradientEnd,
    IconData icon,
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Function(int) onTap,
  ) {
    final bool isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [gradientStart, gradientEnd],
                )
              : null,
          color: isSelected ? null : cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradientStart.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ]
              : [],
        ),
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : (isDarkMode ? Colors.grey[800] : Colors.grey[100]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : gradientStart,
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : textColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: isSelected
                    ? null
                    : Border.all(
                        color:
                            isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 2,
                      ),
              ),
              child: isSelected
                  ? Center(
                      child: Icon(
                        Icons.check,
                        color: gradientEnd,
                        size: 14,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

// Süre seçim kısmını üste alma ve puan çarpanlarını ekleme
  void showMatchModeDialog(BuildContext context, bool isDarkMode) {
    int selectedOption = 0;
    TimeSelection selectedTime = TimeSelection.medium; // Varsayılan süre
    bool _isDifficultyExpanded = false;

    final Color primaryColor = Colors.deepPurple;
    final Color backgroundColor = isDarkMode ? Color(0xFF1E1E2C) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Color(0xFF2D3142);
    final Color subtitleColor =
        isDarkMode ? Colors.grey[400]! : Color(0xFF9DA3B0);
    final Color dividerColor =
        isDarkMode ? Color(0xFF2A2A40) : Color(0xFFF0F0F5);
    final Color cardColor = isDarkMode ? Color(0xFF272838) : Color(0xFFF8F9FC);

    final List<Map<String, dynamic>> modes = [
      {
        'title': 'İngilizce - Türkçe',
        'description':
            'İngilizce kelimeleri Türkçe karşılıklarıyla eşleştirin.',
        'icon': Icons.language,
        'gradient': [Color(0xFF36D1DC), Color(0xFF5B86E5)],
        'matchType': MatchType.englishTurkish,
      },
      {
        'title': 'İngilizce Tanım - İngilizce Kelime',
        'description': 'İngilizce tanımları doğru kelimelerle eşleştirin.',
        'icon': Icons.description,
        'gradient': [Color(0xFFFF8960), Color(0xFFFF62A5)],
        'matchType': MatchType.definitionWord,
      },
      {
        'title': 'İngilizce Tanım - Türkçe Kelime',
        'description': 'İngilizce tanımları Türkçe kelimelerle eşleştirin.',
        'icon': Icons.compare,
        'gradient': [Color(0xFF9D50BB), Color(0xFF6E48AA)],
        'matchType': MatchType.definitionTurkish,
      },
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode ? Colors.black26 : Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.compare_arrows,
                                    color: primaryColor,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    "Eşleştir Modu",
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => Navigator.of(context).pop(),
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Color(0xFF272838)
                                          : Color(0xFFF5F5F7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: subtitleColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Oynamak istediğiniz modu seçin",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: dividerColor,
                      ),

                      // Container for all content - with scrolling
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ✅ YENİ: Süre & Zorluk seçimi bölümü
                              _buildTimeSelectionSection(
                                context,
                                selectedTime,
                                isDarkMode,
                                primaryColor,
                                textColor,
                                (TimeSelection time) {
                                  setState(() {
                                    selectedTime = time;
                                    HapticFeedback.mediumImpact();
                                  });
                                },
                              ),

                              // ✅ YENİ: Dinamik puan çarpanları bölümü
                              _buildDynamicMultiplierSection(
                                context,
                                selectedTime,
                                isDarkMode,
                                primaryColor,
                                textColor,
                                _isDifficultyExpanded,
                                () {
                                  setState(() {
                                    _isDifficultyExpanded =
                                        !_isDifficultyExpanded;
                                  });
                                  HapticFeedback.lightImpact();
                                },
                              ),

                              // Mod seçenekleri başlığı
                              Container(
                                margin: EdgeInsets.only(top: 24, bottom: 8),
                                child: Text(
                                  "Eşleşme Modları",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),

                              // Mod seçenekleri
                              for (int i = 0; i < modes.length; i++)
                                Padding(
                                  padding: EdgeInsets.only(
                                      bottom: i < modes.length - 1 ? 12 : 0),
                                  child: _buildModernModeOption(
                                    context,
                                    modes[i]['title'],
                                    modes[i]['description'],
                                    i,
                                    selectedOption,
                                    modes[i]['gradient'][0],
                                    modes[i]['gradient'][1],
                                    modes[i]['icon'],
                                    isDarkMode,
                                    cardColor,
                                    textColor,
                                    subtitleColor,
                                    (index) {
                                      setState(() {
                                        selectedOption = index;
                                        HapticFeedback.mediumImpact();
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      Divider(
                        height: 1,
                        thickness: 1,
                        color: dividerColor,
                      ),

                      // Actions
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          children: [
                            // Nasıl Oynanır butonu
                            Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: 8),
                              child: TextButton.icon(
                                onPressed: () {
                                  _showHowToPlayPanel(context, isDarkMode);
                                },
                                icon: Icon(
                                  Icons.help_outline,
                                  color: primaryColor,
                                ),
                                label: Text(
                                  "Nasıl Oynanır?",
                                  style: GoogleFonts.poppins(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  backgroundColor:
                                      primaryColor.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                            // Butonlar satırı
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                  ),
                                  child: Text(
                                    "İptal",
                                    style: GoogleFonts.poppins(
                                      color: subtitleColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();

                                    // Kelimelerin sayısını kontrol et
                                    if (words.length < 4) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            title: Text(
                                              'Yeterli Kelime Yok',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber[800],
                                              ),
                                            ),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.warning_amber_rounded,
                                                    size: 80,
                                                    color: Colors.amber[800],
                                                  ),
                                                  SizedBox(height: 20),
                                                  Text(
                                                    'Eşleştirme modundan en yüksek verimi almanız için en az 4 kelime gerekiyor. Haydi, biraz daha kelime ekleyelim!',
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      color: Colors.amber[900],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  'Tamam',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.blue,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      return;
                                    }

                                    // ✅ YENİ: Süre seçimine göre zorluk seviyesi belirle
                                    DifficultyLevel selectedDifficulty =
                                        getDifficultyFromTimeSelection(
                                            selectedTime);

                                    // Seçili moda göre MatchingGame'i başlat
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => MatchingGame(
                                          words: words,
                                          classroomId: widget.classroomId,
                                          studySetId: widget.studySetId,
                                          matchType: modes[selectedOption]
                                              ['matchType'],
                                          difficulty: selectedDifficulty,
                                          // ✅ YENİ: Otomatik zorluk
                                          timeSelection: selectedTime,
                                          customTimeValue:
                                              "120", // Geriye uyumluluk için
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    "Başla",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showHowToPlayPanel(BuildContext context, bool isDarkMode) {
    final Color backgroundColor = isDarkMode ? Color(0xFF1E1E2C) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Color(0xFF2D3142);
    final Color subtitleColor = isDarkMode
        ? Colors.grey[300]!
        : Color(0xFF555A6B); // Daha açık ve okunabilir renkler
    final Color accentColor = Colors.purple[600]!; // Biraz daha açık mor
    final Color cardColor = isDarkMode ? Color(0xFF272838) : Color(0xFFF8F9FC);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Başlık çubuğu
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Eşleştir Nasıl Oynanır?",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // İçerik (kaydırılabilir)
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHowToPlaySection(
                        "Oyunun Amacı",
                        "İki sütundaki eşleşen kelimeleri bulun! Sol ve sağ taraftaki kartlara tıklayarak doğru eşleşmeleri bulmalısınız.",
                        Icons.emoji_events,
                        accentColor,
                        isDarkMode,
                        cardColor,
                        textColor,
                      ),
                      _buildBonusCard(
                        "Zorluk Bonusu",
                        "Oyun zorluk seviyesine göre baz puan ve süre ayarlanır:\n• Kolay: 0.8x çarpan, 180 saniye süre\n• Orta: 1.0x çarpan, 120 saniye süre\n• Zor: 1.5x çarpan, 90 saniye süre\nZor modda daha az süre olsa da daha yüksek puan çarpanı var!",
                        Icons.trending_up,
                        Colors.green[500]!,
                        isDarkMode,
                        cardColor,
                        textColor,
                        subtitleColor,
                      ),

                      _buildHowToPlaySection(
                        "Puanlama Sistemi",
                        "Her doğru eşleşme için puanlar kazanırsınız. Seri halinde doğru eşleşmeler yapmak, puan çarpanınızı artırır!",
                        Icons.stars,
                        Colors.amber[600]!,
                        // Daha okunabilir amber tonu
                        isDarkMode,
                        cardColor,
                        textColor,
                      ),
                      _buildBonusCard(
                        "Tutarlılık Bonusu",
                        "Oyun sonunda en uzun serinize göre ekstra bonus kazanırsınız! "
                            "• 3 roundluk oyun: 9+ seri = +150 puan, 6-8 seri = +100 puan, 3-5 seri = +50 puan\n"
                            "• 5 roundluk oyun: 15+ seri = +150 puan, 10-14 seri = +100 puan, 5-9 seri = +50 puan\n\n"
                            "💡 Strateji: Tek seferde uzun seri yapmak, birkaç kısa seriden çok daha değerli!",
                        Icons.trending_up_outlined,
                        Colors.indigo[500]!,
                        isDarkMode,
                        cardColor,
                        textColor,
                        subtitleColor,
                      ),

// Seri Kurtarma Jokeri kartını güncelleyin:
                      _buildBonusCard(
                        "Seri Kurtarma Jokeri",
                        "Oyun başında 1 adet jokeriniz var! Hatalı bir eşleşme yaptığınızda, jokeri kullanma seçeneği sunulur. "
                            "Jokeri kullanırsanız seriniz bozulmaz ve devam eder.\n\n"
                            "💡 İpucu: Joker'i uzun serilerde (5+) kullanın, kısa serilerde harcamayın! "
                            "Tutarlılık bonusu için tek uzun seri yapmak çok daha karlı.",
                        Icons.auto_awesome,
                        Colors.amber[500]!,
                        isDarkMode,
                        cardColor,
                        textColor,
                        subtitleColor,
                      ),

// Maksimum Puan Stratejisi kartını güncelleyin:
                      _buildBonusCard(
                        "Maksimum Puan Stratejisi",
                        "🏆 ALTIN KURAL: Tek uzun seri yap, birkaç kısa seri yapma!\n\n"
                            "En yüksek puan için:\n"
                            "• Zor modda oyna (+20% çarpan)\n"
                            "• Hiç hata yapma (mükemmel bonus)\n"
                            "• Tek seferde 10+ seri yap (tutarlılık bonusu)\n"
                            "• Hızlı bitir (zaman bonusu)\n"
                            "• Joker'i uzun seride kullan\n\n"
                            "Örnek: 15 seri = +150 bonus | 3+3+3+3+3 seri = 0 bonus",
                        Icons.workspace_premium,
                        Colors.purple[500]!,
                        isDarkMode,
                        cardColor,
                        textColor,
                        subtitleColor,
                      ),
                      // Bonus türleri kartı
                      Container(
                        margin: EdgeInsets.only(top: 20, bottom: 10),
                        child: Text(
                          "Bonus Türleri",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),

                      // Seri Bonusu
                      _buildBonusCard(
                        "Seri Bonusu",
                        "Arka arkaya doğru eşleşmeler yaptığınızda kazanırsınız. Kombo sayısı arttıkça, bonus puanlar da artar!",
                        Icons.whatshot,
                        Colors.deepOrange[400]!,
                        // Daha okunabilir turuncu
                        isDarkMode,
                        cardColor,
                        textColor,
                        subtitleColor,
                      ),
                      _buildBonusCard(
                        "Seri Kurtarma Jokeri",
                        "10 seri yaptığınızda 1 adet seri kurtarma jokeri kazanırsınız! Hatalı bir eşleşme yaptığınızda, jokeri kullanma seçeneği sunulur. Jokeri kullanmayı seçerseniz, seriniz bozulmaz ve devam eder. Oyun boyunca sadece 1 kez kullanabilirsiniz, ne zaman kullanacağınıza dikkat edin!",
                        Icons.auto_awesome,
                        // Joker için parlak yıldız ikonu
                        Colors.amber[500]!,
                        // Altın rengi
                        isDarkMode,
                        cardColor,
                        textColor,
                        subtitleColor,
                      ),
                      _buildBonusCard(
                        "Maksimum Puan Stratejisi",
                        "En yüksek puanı almak için: Zor modda, mükemmel bir tur yaparak, yüksek bir seri oluşturarak ve hızlı bitirerek maksimum puanı kazanabilirsiniz. Zor modun daha kısa süresi olsa da, puan çarpanı ve zaman bonusu çok daha yüksek!",
                        Icons.workspace_premium,
                        Colors.purple[500]!,
                        isDarkMode,
                        cardColor,
                        textColor,
                        subtitleColor,
                      ),
                      // Zaman Bonusu
                      _buildBonusCard(
                        "Zaman Bonusu",
                        "Her zorluk seviyesinde, ne kadar hızlı bitirirseniz o kadar çok bonus alırsınız. Zor modda kalan her saniye için +2 puan, orta seviyede +1 puan, kolay seviyede +0.5 puan kazanırsınız. Hızlı oynamak her zor modda çok daha değerli!",
                        Icons.timer,
                        Colors.blue[500]!,
                        isDarkMode,
                        cardColor,
                        textColor,
                        subtitleColor,
                      ),

                      // Mükemmel Tur
                      _buildBonusCard(
                        "Mükemmel Tur",
                        "Hiç hata yapmadan tüm eşleşmeleri bulursanız, özel bir 'Mükemmel Tur' bonusu kazanırsınız!",
                        Icons.workspace_premium,
                        Colors.amber[500]!,
                        // Daha okunabilir amber
                        isDarkMode,
                        cardColor,
                        textColor,
                        subtitleColor,
                      ),

                      // Zorluk Bonusu
                      _buildBonusCard(
                        "Zorluk Bonusu",
                        "Daha zor seviyelerde oynarsanız, puan çarpanınız artar! Kolay: 0.8x, Orta: 1.0x, Zor: 1.2x",
                        Icons.trending_up,
                        Colors.green[500]!,
                        // Standart yeşil
                        isDarkMode,
                        cardColor,
                        textColor,
                        subtitleColor,
                      ),

                      // Tüm Oyunu Bitirme
                      _buildBonusCard(
                        "Oyun Bitirme Bonusu",
                        "Tüm turları tamamlayıp oyunu bitirdiğinizde büyük bir bonus kazanırsınız! Zorluk seviyesine göre 150-300 arası bonus puan!",
                        Icons.celebration,
                        Colors.purple[500]!,
                        // Standart mor
                        isDarkMode,
                        cardColor,
                        textColor,
                        subtitleColor,
                      ),

                      // İpuçları - Koyu modda özellikle dikkat edilmesi gereken kısım
                      Container(
                        margin: EdgeInsets.only(top: 24, bottom: 16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Color(0xFF2A2D4A)
                              : Colors.blue[50], // Koyu modda koyu mavi tonları
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isDarkMode
                                  ? Colors.blue[800]!
                                  : Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb,
                                  color: Colors.amber[
                                      500]!, // Her zaman okunabilir amber
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "İpuçları",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors
                                            .black87, // Koyu modda beyaz yazı
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            _buildTipItem(
                                "Hızlı olmak için kelime anlamlarını önceden çalışın!",
                                isDarkMode),
                            _buildTipItem(
                                "10 seri yapmak için sabırlı olun ve jokeri stratejik bir zamanda kullanın. Yüksek seriler oluştururken jokeri saklamak daha değerli olabilir!",
                                isDarkMode),
                            _buildTipItem(
                                "Zor modda maksimum puan için, önce kelimeleri iyi ezberleyin, sonra hiç hata yapmadan ve çok hızlı şekilde eşleştirmeleri tamamlayın!",
                                isDarkMode),
                            _buildTipItem(
                                "Tek uzun seri yapmak, birden fazla kısa seriden çok daha değerli! Tutarlılık bonusu için 10+ seri hedefleyin.",
                                isDarkMode),
                            _buildTipItem(
                                "Joker'i stratejik kullanın: 5+ seriniz varken hata yaparsanız kullanın, 1-4 seride harcamayın!",
                                isDarkMode),
                            _buildTipItem(
                                "Mükemmel tur bonusları için özellikle dikkatli olun.",
                                isDarkMode),
                            _buildTipItem(
                                "Seri yapmak için konsantre olun, bir hata yaparsanız seri sıfırlanır.",
                                isDarkMode),
                            _buildTipItem(
                                "Zorluk seviyesi, puanlarınızı doğrudan etkiler. Kendinize güveniyorsanız, Zor modunu deneyin!",
                                isDarkMode),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Alt buton
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white, // Yazı rengini beyaz yapar
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Anladım, Hadi Oynayalım!",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors
                          .white, // Ayrıca Text widget'ına da beyaz renk veriyoruz
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// İpucu maddesi widget'ı - isDarkMode parametresi eklendi
  Widget _buildTipItem(String tip, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? Colors.white
                    : Colors.black87, // Koyu modda beyaz yazı
              )),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode
                    ? Colors.white
                    : Colors.black87, // Koyu modda beyaz yazı
              ),
            ),
          ),
        ],
      ),
    );
  }

// Nasıl oynanır bölümü widget'ı
  Widget _buildHowToPlaySection(String title, String description, IconData icon,
      Color iconColor, bool isDarkMode, Color cardColor, Color textColor) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.9)
                  : Colors.black87, // Koyu modda daha açık beyaz
            ),
          ),
        ],
      ),
    );
  }

// Bonus kartı widget'ı
  Widget _buildBonusCard(
    String title,
    String description,
    IconData icon,
    Color color,
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? color.withOpacity(0.15) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black26 : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? color.withOpacity(0.9) : color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.85)
                        : subtitleColor, // Koyu modda daha açık beyaz
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// 1. Süre seçimine göre zorluk seviyesi belirleme fonksiyonu
  DifficultyLevel getDifficultyFromTimeSelection(TimeSelection timeSelection) {
    switch (timeSelection) {
      case TimeSelection.short:
        return DifficultyLevel.hard; // 60 sn = Zor (1.2x çarpan)
      case TimeSelection.medium:
        return DifficultyLevel.medium; // 120 sn = Orta (1.0x çarpan)
      case TimeSelection.long:
        return DifficultyLevel.easy; // 180 sn = Kolay (0.8x çarpan)
      case TimeSelection.custom:
        return DifficultyLevel.medium; // Özel süre = Orta (varsayılan)
    }
  }

// İpucu maddesi widget'ı
// Süre seçim widget'ı
  Widget _buildTimeOption(
    BuildContext context,
    String time,
    String label,
    TimeSelection option,
    TimeSelection selectedOption,
    bool isDarkMode,
    Color primaryColor,
    Function(TimeSelection) onSelect,
  ) {
    bool isSelected = selectedOption == option;

    // ✅ YENİ: Süre seçimine göre zorluk ve çarpan hesapla
    DifficultyLevel difficulty = getDifficultyFromTimeSelection(option);
    String multiplier = difficulty == DifficultyLevel.easy
        ? "0.8x"
        : difficulty == DifficultyLevel.medium
            ? "1.0x"
            : "1.2x";
    Color multiplierColor = difficulty == DifficultyLevel.easy
        ? Colors.green
        : difficulty == DifficultyLevel.medium
            ? Colors.blue
            : Colors.red;

    return GestureDetector(
      onTap: () => onSelect(option),
      child: Container(
        width: 80, // ✅ Biraz genişlettik çarpan bilgisi için
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : isDarkMode
                  ? Colors.grey[800]
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer,
              color: isSelected
                  ? Colors.white
                  : isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[700],
              size: 22,
            ),
            SizedBox(height: 4),
            Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : isDarkMode
                        ? Colors.grey[300]
                        : Colors.grey[800],
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isSelected
                    ? Colors.white.withOpacity(0.8)
                    : isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
              ),
            ),
            // ✅ YENİ: Çarpan bilgisi
            Container(
              margin: EdgeInsets.only(top: 4),
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : multiplierColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                multiplier,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : multiplierColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelectionSection(
    BuildContext context,
    TimeSelection selectedTime,
    bool isDarkMode,
    Color primaryColor,
    Color textColor,
    Function(TimeSelection) onTimeSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Süre & Zorluk Seçin",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Süre seçiminiz zorluk seviyesini ve puan çarpanını belirler",
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        SizedBox(height: 12),

        // Süre seçenekleri
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTimeOption(
              context,
              "60 sn",
              "Zor",
              TimeSelection.short,
              selectedTime,
              isDarkMode,
              primaryColor,
              onTimeSelect,
            ),
            _buildTimeOption(
              context,
              "120 sn",
              "Orta",
              TimeSelection.medium,
              selectedTime,
              isDarkMode,
              primaryColor,
              onTimeSelect,
            ),
            _buildTimeOption(
              context,
              "180 sn",
              "Kolay",
              TimeSelection.long,
              selectedTime,
              isDarkMode,
              primaryColor,
              onTimeSelect,
            ),
          ],
        ),

        // ✅ YENİ: Seçilen zorluğun detayı
        Container(
          margin: EdgeInsets.only(top: 16),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withOpacity(0.3)),
          ),
          child:
              _buildSelectedDifficultyInfo(selectedTime, isDarkMode, textColor),
        ),
      ],
    );
  }

  Widget _buildSelectedDifficultyInfo(
      TimeSelection selectedTime, bool isDarkMode, Color textColor) {
    DifficultyLevel difficulty = getDifficultyFromTimeSelection(selectedTime);

    String difficultyText = difficulty == DifficultyLevel.easy
        ? "Kolay"
        : difficulty == DifficultyLevel.medium
            ? "Orta"
            : "Zor";
    String multiplier = difficulty == DifficultyLevel.easy
        ? "0.8x"
        : difficulty == DifficultyLevel.medium
            ? "1.0x"
            : "1.2x";
    String description = difficulty == DifficultyLevel.easy
        ? "Daha fazla süre, daha az çarpan"
        : difficulty == DifficultyLevel.medium
            ? "Dengeli süre ve çarpan"
            : "Daha az süre, daha yüksek çarpan!";

    Color difficultyColor = difficulty == DifficultyLevel.easy
        ? Colors.green
        : difficulty == DifficultyLevel.medium
            ? Colors.blue
            : Colors.red;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: difficultyColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            difficulty == DifficultyLevel.easy
                ? Icons.sentiment_satisfied
                : difficulty == DifficultyLevel.medium
                    ? Icons.sentiment_neutral
                    : Icons.local_fire_department,
            color: difficultyColor,
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "$difficultyText Seviye",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: difficultyColor,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: difficultyColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      multiplier,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: difficultyColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicMultiplierSection(
    BuildContext context,
    TimeSelection selectedTime,
    bool isDarkMode,
    Color primaryColor,
    Color textColor,
    bool isExpanded,
    Function() onToggle,
  ) {
    DifficultyLevel currentDifficulty =
        getDifficultyFromTimeSelection(selectedTime);

    return Container(
      margin: EdgeInsets.only(top: 24, bottom: 16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Başlık satırı
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.calculate_outlined, color: primaryColor),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Puan Çarpanları",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  // ✅ YENİ: Mevcut seçimin çarpanını göster
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(currentDifficulty)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Seçili: ${_getMultiplierText(currentDifficulty)}",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getDifficultyColor(currentDifficulty),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Genişletilir içerik
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 300),
              opacity: isExpanded ? 1.0 : 0.0,
              child: isExpanded
                  ? Container(
                      padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: Column(
                        children: [
                          Divider(
                            color: primaryColor.withOpacity(0.3),
                            thickness: 1,
                          ),
                          SizedBox(height: 8),

                          // Zorluk çarpanları - mevcut seçimi vurgula
                          _buildMultiplierRow(
                              "Kolay (180 sn)",
                              "x0.8",
                              Colors.green,
                              currentDifficulty == DifficultyLevel.easy,
                              textColor),
                          SizedBox(height: 8),
                          _buildMultiplierRow(
                              "Orta (120 sn)",
                              "x1.0",
                              Colors.blue,
                              currentDifficulty == DifficultyLevel.medium,
                              textColor),
                          SizedBox(height: 8),
                          _buildMultiplierRow(
                              "Zor (60 sn)",
                              "x1.2",
                              Colors.red,
                              currentDifficulty == DifficultyLevel.hard,
                              textColor),
                        ],
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

// 7. Yardımcı fonksiyonlar
  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.medium:
        return Colors.blue;
      case DifficultyLevel.hard:
        return Colors.red;
    }
  }

  String _getMultiplierText(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return "x0.8";
      case DifficultyLevel.medium:
        return "x1.0";
      case DifficultyLevel.hard:
        return "x1.2";
    }
  }

  Widget _buildMultiplierRow(String label, String multiplier, Color color,
      bool isSelected, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: color, width: 1) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isSelected) Icon(Icons.check_circle, color: color, size: 16),
              if (isSelected) SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : textColor,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(isSelected ? 0.3 : 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              multiplier,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Mod seçenek kartı
  Widget _buildModeOption(
      BuildContext context,
      String title,
      String description,
      int index,
      int selectedOption,
      Color color,
      IconData icon,
      bool isDarkMode,
      Function(int) onSelect) {
    bool isSelected = selectedOption == index;

    return GestureDetector(
      onTap: () => onSelect(index),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? color.withOpacity(0.2) : color.withOpacity(0.1))
              : (isDarkMode ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : isDarkMode
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // İkon
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.2)
                    : (isDarkMode ? Colors.grey[700] : Colors.white),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? color
                    : isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                size: 22,
              ),
            ),
            SizedBox(width: 12),

            // Metin içeriği
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? color
                          : isDarkMode
                              ? Colors.white
                              : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Seçim durumu
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? color
                      : isDarkMode
                          ? Colors.grey[600]!
                          : Colors.grey[400]!,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

// Yakında diyaloğu
  void _showComingSoonDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Center(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.rocket_launch,
                    color: Colors.purple[700],
                    size: 40,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Çok Yakında!",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[600],
                  ),
                ),
              ],
            ),
          ),
          content: Text(
            "Eşleştir modu çok yakında hizmetinizde olacak. Bu özelliği ilk kullanan siz olmak için bizi takip edin!",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  minimumSize: Size(150, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Tamam",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
