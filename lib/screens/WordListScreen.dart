import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/Models/Classroom.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/study_set.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'loadingIndicator.dart';

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

  @override
  void initState() {
    super.initState();
    wordsFuture = ApiService().fetchWords(widget.categoryId);
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
    return Scaffold(
      backgroundColor: const Color(0xFFFEFAF6), // Arka plan rengini burada ayarlayın

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.categoryName,
          style: GoogleFonts.poppins(
            color: Colors.pink,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.pink,
        ),
      ),
      body: Container(
        child: FutureBuilder<List<Word>>(
          future: wordsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: const LogoLoadingIndicator(), // Merkeze alınmış LogoLoadingIndicator
              );
            }
            else if (snapshot.hasError) {
              return Center(child: Text("Hata: ${snapshot.error}"));
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              // Veri yüklendikten sonra, eğer yalnızca bir eleman varsa, yönlendirme yap

              return ListView.separated(
                itemCount: snapshot.data!.length,
                separatorBuilder: (context, index) => Divider(color: Colors.grey),
                itemBuilder: (context, index) {
                  var word = snapshot.data![index];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => StudySetListScreen(
                              classroomId: widget.categoryId,
                              wordid: word.id
                          ),
                        ),
                      );
                    },
                    child: ListTile(
                      leading: Icon(Icons.bookmark, color: Colors.pink),
                      title: Text(
                        word.name,
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              );
            } else {
              return Center(child: Text("Kelime listesi yok"));
            }
          },
        ),
      ),
    );
  }
}
