import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/Models/Classroom.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/study_set.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'loadingIndicator.dart';
import '../variables.dart'; // variables.dart dosyasını dahil edin

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

  const WordListScreen({Key? key, required this.categoryId, required this.categoryName}) : super(key: key);

  @override
  _WordListScreenState createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  Future<List<Word>>? wordsFuture;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    wordsFuture = ApiService().fetchWords(widget.categoryId);
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
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

  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Scaffold(
      backgroundColor: colors["background"],
      appBar: AppBar(
        backgroundColor: colors["background"],
        title: Text(
          widget.categoryName,
          style: GoogleFonts.poppins(
            color: colors["text"],
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: colors["text"],
        ),
      ),
      body: Container(
        child: FutureBuilder<List<Word>>(
          future: wordsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: const LogoLoadingIndicator(),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text("Hata: ${snapshot.error}", style: TextStyle(color: colors["text"])));
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return ListView.separated(
                itemCount: snapshot.data!.length,
                separatorBuilder: (context, index) => Divider(color: colors["borderColor"]),
                itemBuilder: (context, index) {
                  var word = snapshot.data![index];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => StudySetListScreen(
                            classroomId: widget.categoryId,
                            wordid: word.id,
                          ),
                        ),
                      );
                    },
                    child: ListTile(
                      leading: Icon(Icons.bookmark, color: colors["iconColor"]),
                      title: Text(
                        word.name,
                        style: TextStyle(color: colors["text"], fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              );
            } else {
              return Center(child: Text("Kelime listesi yok", style: TextStyle(color: colors["text"])));
            }
          },
        ),
      ),
    );
  }
}
