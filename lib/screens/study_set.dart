import 'package:flutter/material.dart';
import 'package:kelibu/api.dart'; // ApiService dosyanızın yolu
import 'package:kelibu/Models/studySet.dart'; // StudySet modelinizin yolu
import 'package:kelibu/screens/game_mod.dart'; // GameModeScreen dosyanızın yolu
// GameModeScreen dosyanızın yolu

class StudySetListScreen extends StatefulWidget {
  final int classroomId;

  const StudySetListScreen({Key? key, required this.classroomId}) : super(key: key);

  @override
  _StudySetListScreenState createState() => _StudySetListScreenState();
}

class _StudySetListScreenState extends State<StudySetListScreen> {
  Future<List<StudySet>>? studySetsFuture;
  List<StudySet>? studySets; // Yeni eklenen değişken

  @override
  void initState() {
    super.initState();
    studySetsFuture = ApiService().fetchStudySets(widget.classroomId);
    studySetsFuture!.then((sets) {
      setState(() {
        studySets = sets; // studySets değişkenini güncelle
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Kelimelerim'),
          backgroundColor: const Color(0xFFEEC4C9),
        ),
        body: Column(
          children: [
            Expanded(
              child: buildBody(),
            ),
          ],
        ),
      ),
    );
  }


  Widget buildBody() {

    return FutureBuilder<List<StudySet>>(
      future: studySetsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Hata: ${snapshot.error}"));
        } else if (snapshot.hasData) {
          return buildStudySetList(snapshot.data!);
        } else {
          return const Center(child: Text("Study set listesi yok"));
        }
      },
    );
  }

  Widget buildStudySetList(List<StudySet> studySets) {
    return ListView.builder(
      itemCount: studySets.length,
      itemBuilder: (context, index) {
        var studySet = studySets[index];
        return Card(
          color: const Color(0x0ff87654), // Set the background color here
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: ListTile(
            title: Text(
              studySet.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF5E376D), // Açık beyaz yazı rengi
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => GameModeScreen(
                    studySetName: studySet.words,
                    classroomId: widget.classroomId, // Classroom ID
                    studySetId: studySet.id, // Study Set ID
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
