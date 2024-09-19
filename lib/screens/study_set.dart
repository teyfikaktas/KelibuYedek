import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/Models/studySet.dart';
import 'package:kelibu/screens/game_mod.dart';
import 'package:kelibu/screens/game_screen_star.dart';
import 'package:kelibu/screens/video_player.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'loadingIndicator.dart';

import '../event.dart';
import '../event_bus.dart';
import '../globalDart/urls.dart';
import '../providers/user_provider.dart';
import '../shared_preferences/shared_preferences.dart';
import 'loadingIndicator.dart';
import '../variables.dart';


class StudySetListScreen extends StatefulWidget {
  final int classroomId;
  final int wordid;
  const StudySetListScreen({Key? key, required this.classroomId, required this.wordid}) : super(key: key);

  @override
  _StudySetListScreenState createState() => _StudySetListScreenState();
}

class _StudySetListScreenState extends State<StudySetListScreen> {
  Map<int, int> starredWordCounts = {};
  ValueNotifier<Map<int, int>> starredWordCountsNotifier = ValueNotifier({});
  Future<List<StudySet>>? studySetsFuture;
  List<StudySet>? studySets;
  List<int> studySetIds = [];
  bool _isDarkMode = false;
  int totalStarredWords = 0;


  @override
  void initState() {
    super.initState();
    appEventBus.on<StarredWordsChangedEvent>().listen((event) async {
      await loadStarredWordsCounts();
    });
    _initializeData();
  }

  Future<void> loadStarredWordsCounts() async {
    print('Yıldızlanmış kelimeler yükleniyor...');
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int userID = userProvider.userId;
    var sets = await ApiService().fetchStudySets(widget.classroomId, widget.wordid, userID.toString());
    print(widget.classroomId);
    final tempStarredWordCounts = <int, int>{};
    int tempTotalStarredWords = 0;
    for (var studySet in sets) {
      final starredWordsSet = await StarredWordsService().loadStarredWords(widget.classroomId, studySet.id);
      tempStarredWordCounts[studySet.id] = starredWordsSet.length;
      tempTotalStarredWords += starredWordsSet.length;
    }
    setState(() {
      starredWordCountsNotifier.value = tempStarredWordCounts;
      totalStarredWords = tempTotalStarredWords;
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        title: Text(
          'Setler',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          _buildRoundedIconButton(
            Icons.slow_motion_video_sharp,
            Colors.green,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: AppUrls.studysets)),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[800] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: Offset(0, 3),
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
                      Text(
                        '$totalStarredWords',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: buildBody(textColor),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: FloatingActionButton.extended(
          onPressed: navigateToGameModeStarScreen,
          icon: Icon(Icons.star, color: Colors.amber),
          label: Text('Yıldızlı Kelimelere Çalış'),
          backgroundColor: _isDarkMode ? Colors.blueGrey[700] : Color(0xFF3D5AFE),
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  Widget _buildRoundedIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: CircleBorder(),
      ),
      child: Icon(icon, color: Colors.white, size: 16.sp),
    );
  }

  Widget buildBody(Color textColor) {
    return FutureBuilder<List<StudySet>>(
      future: studySetsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: LogoLoadingIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Hata: ${snapshot.error}", style: TextStyle(color: textColor)));
        } else if (snapshot.hasData) {
          return buildStudySetList(snapshot.data!, textColor);
        } else {
          return Center(child: Text("Study set listesi yok", style: TextStyle(color: textColor)));
        }
      },
    );
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  Future<void> _initializeData() async {
    await _loadDarkModePreference();
    await loadStarredWordsCounts();

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int userID = userProvider.userId;
    studySetsFuture = ApiService().fetchStudySets(widget.classroomId, widget.wordid, userID.toString());
    studySetsFuture!.then((sets) {
      setState(() {
        studySets = sets;
      });
      studySets?.forEach((studySet) {
        studySetIds.add(studySet.id);
      });
    });
  }

  Future<void> navigateToGameModeStarScreen() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: LogoLoadingIndicator(),
          ),
        );
      },
    );

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      String idString = studySetIds.join(', ');
      print('studytsets' + idString);

      // Veri yükleme işlemini bekleyin

      Navigator.of(context).pop(); // Yükleme göstergesini kapat

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GameModeStarScreen(
            studySetName: idString,
            classroomId: widget.classroomId,
            studySetId: widget.wordid,
          ),
        ),
      );

      if (result != null) {
        print('Geri dönüldü ve sayfa güncellenecek');
        await loadStarredWordsCounts();
        reloadStudySets();
      }
    } catch (e) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      print('Hata: $e');
    }
  }

  void reloadStudySets() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int userID = userProvider.userId;
    studySetsFuture = ApiService().fetchStudySets(widget.classroomId, widget.wordid, userID.toString());
    studySetsFuture!.then((sets) {
      setState(() {
        studySets = sets;
      });
      studySetIds.clear();
      studySets?.forEach((studySet) {
        studySetIds.add(studySet.id);
      });
    });
  }

  Widget buildStudySetList(List<StudySet> studySets, Color textColor) {
    return AnimationLimiter(
      child: ListView.builder(
        itemCount: studySets.length,
        itemBuilder: (context, index) {
          var studySet = studySets[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: buildStudySetCard(studySet, textColor),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildStudySetCard(StudySet studySet, Color textColor) {
    final cardColor = _isDarkMode ? Colors.grey[800] : Colors.white;
    final subtitleColor = _isDarkMode ? Colors.grey[400] : Colors.black54;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _isDarkMode ? Colors.blueGrey[700] : Colors.blue[700],
          child: Icon(Icons.book, color: Colors.white),
        ),
        title: Text(
          studySet.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
          ),
        ),
        subtitle: Text(
          'Bu sette ${studySet.words.split(',').length} kelime var.',
          style: GoogleFonts.poppins(fontSize: 14, color: subtitleColor),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Colors.amber),
            Text(
              '${starredWordCountsNotifier.value[studySet.id] ?? 0}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
        onTap: () => navigateToGameModeScreen(studySet),
      ),
    );
  }

  void navigateToGameModeScreen(StudySet studySet) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: LogoLoadingIndicator(),
          ),
        );
      },
    );

    try {
      // 300 ms bekletme ekleniyor
      await Future.delayed(Duration(milliseconds: 100));

      // Burada gerekli verileri yükleyin
      // Örnek olarak, 2 saniye bekletelim

      Navigator.of(context).pop(); // Yükleme göstergesini kapat

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GameModeScreen(
            studySetName: studySet.words,
            classroomId: widget.classroomId,
            studySetId: studySet.id,
          ),
        ),
      );

      if (result != null) {
        print('Geri dönüldü ve sayfa güncellenecek');
        await loadStarredWordsCounts();
        reloadStudySets();
      }
    } catch (e) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      print('Hata: $e');
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                  'assets/logo.png',
                  width: 100,
                  height: 100,
                ),
              ),
              SizedBox(height: 30),
              SpinKitFadingCube(
                color: Colors.blue,
                size: 40.0,
              ),
              SizedBox(height: 20),
              Text(
                "Oyun modları yükleniyor...",
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 10),
              LinearProgressIndicator(
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String extractIds(List<dynamic> jsonData) {
    List<String> ids = jsonData.map((item) => item['id'].toString()).toList();
    return ids.join(',');
  }
}