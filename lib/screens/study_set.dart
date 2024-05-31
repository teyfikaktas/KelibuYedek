import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/api.dart'; // ApiService dosyanızın yolu
import 'package:kelibu/Models/studySet.dart'; // StudySet modelinizin yolu
import 'package:kelibu/screens/game_mod.dart'; // GameModeScreen dosyanızın yolu
import 'package:kelibu/screens/game_screen_star.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../event.dart';
import '../event_bus.dart';
import '../providers/user_provider.dart';
import '../shared_preferences/shared_preferences.dart';
import 'loadingIndicator.dart'; // GameModeScreen dosyanızın yolu

// GameModeScreen dosyanızın yolu
class CustomLoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitChasingDots( // Circle türündeki yükleme göstergesi
        color: Colors.blue, // Yükleme göstergesi rengi
        size: 50.0, // Yükleme göstergesi boyutu
      ),
    );
  }
}

class StudySetListScreen extends StatefulWidget {
  final int classroomId;
  final int wordid;
  const StudySetListScreen({Key? key, required this.classroomId, required this.wordid}) : super(key: key);

  @override
  _StudySetListScreenState createState() => _StudySetListScreenState();
}

class _StudySetListScreenState extends State<StudySetListScreen> {
  Map<int, int> starredWordCounts = {}; // Her study set için yıldızlanmış kelime sayısını tutacak bir map
  ValueNotifier<Map<int, int>> starredWordCountsNotifier = ValueNotifier({});

  Future<List<StudySet>>? studySetsFuture;
  List<StudySet>? studySets; // Yeni eklenen değişken
  List<int> studySetIds = []; // `null` olabilirliği kaldırıldı, doğrudan bir liste oluşturuldu
  @override
  void initState() {
    super.initState();
    appEventBus.on<StarredWordsChangedEvent>().listen((event) async {
        await loadStarredWordsCounts(); // Yıldızlanmış kelimelerin sayısını yeniden yükle
    });
    loadStarredWordsCounts();

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int userID = userProvider.userId;
    studySetsFuture = ApiService().fetchStudySets(widget.classroomId, widget.wordid,userID.toString());
    studySetsFuture!.then((sets) {
      setState(() {
        studySets = sets; // studySets değişkenini güncelle
      });
      studySets?.forEach((studySet) {
        studySetIds.add(studySet.id);
      });
    });
  }

  Future<void> loadStarredWordsCounts() async {
    print('Yıldızlanmış kelimeler yükleniyor...');
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int userID = userProvider.userId;
    var sets = await ApiService().fetchStudySets(widget.classroomId, widget.wordid, userID.toString());
    print(widget.classroomId);
    final tempStarredWordCounts = <int, int>{};
    for (var studySet in sets) {
      final starredWordsSet = await StarredWordsService().loadStarredWords(widget.classroomId, studySet.id);
      tempStarredWordCounts[studySet.id] = starredWordsSet.length;
    }
    // ValueNotifier'ı güncelle
    starredWordCountsNotifier.value = tempStarredWordCounts;
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home:
      Scaffold(
        backgroundColor: const Color(0xFFFEFAF6), // Arka plan rengini burada ayarlayın

        appBar: AppBar(
          backgroundColor: Colors.white,
          title:  Text(
            'Setler',
            style: GoogleFonts.poppins(
              color: Colors.pink,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            color: Colors.pink,
            icon: Icon(Icons.arrow_back),

            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: buildBody(),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            navigateToGameModeStarScreen();
          },
          icon: Icon(Icons.star, color: Colors.yellowAccent), // Adjust icon color for better visibility
          label: Text(
            'Yıldızlanmış Kelimelere Çalış',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold, // Make text bold
              fontSize: 16, // Increase font size for better readability
            ),
          ),
          backgroundColor: Colors.lightBlueAccent, // Use a more vibrant color for the background
          elevation: 10.0, // Increase elevation for a more pronounced shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Make the button more rounded
            side: BorderSide(color: Colors.white, width: 2.5), // Make the border more prominent
          ),
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
  Future<void> navigateToGameModeStarScreen() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: LogoLoadingIndicator(), // Özel yükleme göstergeniz
            ),
          );
        },
      );

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      // Asenkron işleminizi burada gerçekleştirin
      String idString = studySetIds.join(', ');
      print('studytsets'+idString);
      // İşlem tamamlandığında yükleme göstergesini kapat
      Navigator.of(context).pop();

      // Sonraki sayfaya navigasyon
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GameModeStarScreen(
            studySetName: idString,
            classroomId: widget.classroomId,
            studySetId: widget.wordid,
          ),
        ),
      ).then((value) {
        // Geri dönüldüğünde gereken işlemler
        if (value != null) {
          // Gerekli güncellemeleri yap
          print('Geri dönüldü ve sayfa güncellenecek');
          reloadStudySets();
        }
      });
    } catch (e) {
      Navigator.of(context).pop(); // Hata durumunda yükleme göstergesini kapat
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
      studySetIds.clear(); // Önceki ID'leri temizleyin
      studySets?.forEach((studySet) {
        studySetIds.add(studySet.id);
      });
    });
  }
  Widget buildBody() {

    return FutureBuilder<List<StudySet>>(
      future: studySetsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: const LogoLoadingIndicator(), // Merkeze alınmış LogoLoadingIndicator
          );
        }else if (snapshot.hasError) {
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
    // ValueListenableBuilder'ı doğrudan döndür
    return ValueListenableBuilder<Map<int, int>>(
      valueListenable: starredWordCountsNotifier,
      builder: (context, starredWordCounts, child) {
        return ListView.builder(
          itemCount: studySets.length,
          itemBuilder: (context, index) {
            var studySet = studySets[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              color: Colors.lightBlue.shade50,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade900,
                  child: Icon(Icons.book, color: Colors.white),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        studySet.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.yellow.shade700, size: 24),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '${starredWordCounts[studySet.id] ?? 0}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                subtitle: Text(
                  'Bu sette ${studySet.words.split(',').length} kelime var.',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => GameModeScreen(
                        studySetName: studySet.words,
                        classroomId: widget.classroomId,
                        studySetId: studySet.id,
                      ),
                    ),
                  ); // Bu kapatma parantezi eksikti
                },

              ),
            );
          },
        );
      },
    );
  }

  String extractIds(List<dynamic> jsonData) {
    // JSON listesinden her öğenin 'id' alanını al ve String listesine dönüştür
    List<String> ids = jsonData.map((item) => item['id'].toString()).toList();

    // String listesini virgülle ayrılmış bir stringe dönüştür
    return ids.join(',');
  }
}
