import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/Models/Classroom.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/study_set.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:kelibu/screens/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../globalDart/urls.dart';
import 'loadingIndicator.dart';
import '../variables.dart';

class CustomLoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitChasingDots(
        color: Colors.blue,
        size: 50.0,
      ),
    );
  }
}

class WordListScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const WordListScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  _WordListScreenState createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  Future<List<Word>>? wordsFuture;
  bool _isDarkMode = false;
  ApiService _apiService = ApiService(); // ApiService instance

  @override
  void initState() {
    super.initState();
    wordsFuture = _apiService.fetchWords(widget.categoryId);
    _loadDarkModePreference();

    ApiService().logSetEntry('Kategori Giriş',widget.categoryName,'kategorisine'); // Ekran açıldığında log gönder
  }

  /// Dark Mode tercihini yükler
  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  /// Ekran giriş logunu gönderir
  Future<void> _sendEntryLog() async {
    try {
      await _apiService.sendUserLog(
        type: 'screen_entry',
        log: 'Kullanıcı setler ekranına giriş yaptı.',
      );
      print('Giriş logu başarıyla gönderildi.');
    } catch (e) {
      print('Giriş logu gönderilirken hata oluştu: $e');
      // Gerekirse kullanıcıya hata bildirimi ekleyebilirsiniz
    }
  }

  void checkAndNavigate(List<Word> words) {
    if (words.length == 1) {
      Future.delayed(Duration.zero, () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StudySetListScreen(
              classroomId: widget.categoryId,
              wordid: words[0].id,
            ),
          ),
        );
      });
    }
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

  /// Log gönderme metodu

  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Scaffold(
      backgroundColor: colors["background"],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors["background"],
        title: Row(
          children: [
            Icon(
              Icons.category_outlined,
              color: colors["text"],
              size: 24,
            ),
            SizedBox(width: 8),
            AutoSizeText(
              widget.categoryName,
              style: GoogleFonts.poppins(
                color: colors["text"],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              minFontSize: 8,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        iconTheme: IconThemeData(
          color: colors["text"],
        ),
        actions: [
          _buildRoundedIconButton(
            Icons.slow_motion_video_sharp,
            Colors.green,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(videoUrl: AppUrls.category),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Word>>(
        future: wordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: const LogoLoadingIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Hata: ${snapshot.error}",
                style: TextStyle(color: colors["text"]),
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return AnimationLimiter(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var word = snapshot.data![index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Card(
                          elevation: 2,
                          margin: EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: colors["cardBackground"],
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              // Log gönderme
                              await ApiService().logSetEntry('Set Giriş',word.name,'setine');

                              // Set ekranına navigasyon
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => StudySetListScreen(
                                    classroomId: widget.categoryId,
                                    wordid: word.id,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colors["iconBackground"],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.bookmark,
                                      color: colors["iconColor"],
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      word.name,
                                      style: GoogleFonts.poppins(
                                        color: colors["text"],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: colors["iconColor"],
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          } else {
            return Center(
              child: Text(
                "Kelime listesi yok",
                style: TextStyle(color: colors["text"]),
              ),
            );
          }
        },
      ),
    );
  }
}
