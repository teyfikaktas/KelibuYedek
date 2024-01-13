import 'package:flutter/material.dart';
import 'package:kelibu/Models/Classroom.dart'; // Eğer Word sınıfı buradaysa
// import '../Models/category.dart'; // Eğer Word sınıfını burada kullanmıyorsanız bu importu kaldırabilirsiniz.
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/study_set.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body:Container(
        color: const Color(0xFFEEC4C9), // Set the background color here
        child:  FutureBuilder<List<Word>>(
          future: wordsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text("Hata: ${snapshot.error}");
            } else if (snapshot.hasData && snapshot.data != null) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var word = snapshot.data![index];
                  return ListTile(
                    title: Text(word.name),
                    onTap: () {
                      // Burada kelimenin bağlı olduğu studySet sayfasına yönlendirin
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => StudySetListScreen(classroomId: widget.categoryId),
                        ),
                      );
                    },
                  );
                },
              );
            } else {
              return const Text("Kelime listesi yok");
            }
          },
        ),
      )
    );
  }
}
