import 'package:flutter/material.dart';
import 'package:kelibu/Models/wordDetaik.dart'; // WordDetail modelinizin importu
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/flash_card.dart'; // FlashCardScreen sayfasının importu
import 'package:kelibu/providers/user_provider.dart'; // UserProvider importu
import 'package:provider/provider.dart';
import 'package:kelibu/screens/quiz.dart';
import 'study_screen.dart'; // StudyScreen'i içe aktar

class GameModeScreen extends StatefulWidget {
  final String studySetName;
  final int classroomId; // Yeni eklenen alan
  final int studySetId; // Yeni eklenen alan

  const GameModeScreen({
    Key? key,
    required this.studySetName,
    required this.classroomId, // Yeni parametre
    required this.studySetId, // Yeni parametre
  }) : super(key: key);
  @override
  _GameModeScreenState createState() => _GameModeScreenState();
}


class _GameModeScreenState extends State<GameModeScreen> {
  late Future<List<WordDetail>> wordsFuture;
  late Map<int, bool> starredWords;
  final Map<int, Color> _tileColors = {};


  @override
  void initState() {
    super.initState();

    // Köşeli parantezleri kaldır
    String processedString = widget.studySetName;
    if (processedString.startsWith('[')) {
      processedString = processedString.substring(1);
    }
    if (processedString.endsWith(']')) {
      processedString = processedString.substring(0, processedString.length - 1);
    }
    starredWords = {}; // Başlangıçta boş olarak ayarlanır

    // Gelen string'i virgüllerle ayır ve boşlukları temizle
    List<String> stringIds = processedString.split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    // String'leri tamsayıya dönüştür
    List<int> wordIds = stringIds.map((id) {
      try {
        return int.parse(id);
      } catch (e) {
        return 0;
      }
    }).toList();

    wordsFuture = ApiService().fetchWordsDetail(wordIds);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int currentUserId = userProvider.userId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Game'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2,
              children: <Widget>[
                _buildGameModeTile(context, "Öğren", Colors.blue, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FutureBuilder<List<WordDetail>>(
                        future: wordsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return QuizScreen(
                              words: snapshot.data!,
                              classroomId: widget.classroomId, // classroomId değerini burada aktar
                              studySetId: widget.studySetId, // studySetId değerini burada aktar
                            );
                          } else {
                            return const Center(child: CircularProgressIndicator());
                          }
                        },
                      ),
                    ),
                  );
                }),

                _buildGameModeTile(context, "Flash Kart", Colors.green, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FutureBuilder<List<WordDetail>>(
                        future: wordsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return FlashCardScreen(
                              words: snapshot.data!,
                              classroomId: widget.classroomId, // classroomId değerini burada aktar
                              studySetId: widget.studySetId, // studySetId değerini burada aktar
                            );
                          } else {
                            return const Center(child: CircularProgressIndicator());
                          }
                        },
                      ),
                    ),
                  );
                }),
                _buildGameModeTile(context, "Çalış", Colors.blue, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FutureBuilder<List<WordDetail>>(
                        future: wordsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return StudyScreen(
                              words: snapshot.data!,
                              classroomId: widget.classroomId, // classroomId değerini burada aktar
                              studySetId: widget.studySetId, // studySetId değerini burada aktar
                            );
                          } else {
                            return const Center(child: CircularProgressIndicator());
                          }
                        },
                      ),
                    ),
                  );
                }),
                _buildGameModeTile(context, "Dinle", Colors.red),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: FutureBuilder<List<WordDetail>>(
              future: wordsFuture,
              builder: (context, wordSnapshot) {
                if (wordSnapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (wordSnapshot.hasError) {
                  return Text('Error: ${wordSnapshot.error}');
                } else if (wordSnapshot.hasData) {


                  return FutureBuilder<Map<int, bool>>(
                    future: ApiService().checkStarredBulk(
                      wordSnapshot.data!.map((word) => word.id).toList(),
                      widget.studySetId,
                      currentUserId,
                    ),
                    builder: (context, starredSnapshot) {
                      if (starredSnapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (starredSnapshot.hasError) {
                        return Text('Error: ${starredSnapshot.error}');
                      } else if (starredSnapshot.hasData) {
                        starredWords.addAll(starredSnapshot.data!);
                        int starredCount = starredWords.values.where((isStarred) => isStarred).length;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(1.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blueGrey),
                                ),
                                child: Text(
                                  "Yıldızlı Kelime Sayısı: $starredCount",
                                  style: TextStyle(
                                    color: Colors.blueGrey[900],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: wordSnapshot.data!.length,
                                itemBuilder: (context, index) {
                                  var word = wordSnapshot.data![index];
                                  bool isStarred = starredWords[word.id] ?? false;
                                  return AnimatedContainer(
                                    duration: Duration(seconds: 1),
                                    decoration: BoxDecoration(
                                      color: _tileColors[word.id] ?? Colors.white, // Başlangıçta beyaz, sonra turuncu
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: ListTile(
                                      leading: InkWell(
                                        onTap: () async {
                                          // API çağrısını yapın ve durumu güncelleyin
                                          await toggleStar(word.id, isStarred, currentUserId);
                                          // Renk animasyonunu tetikle
                                          _triggerColorChange(word.id, isStarred);
                                        },
                                        child: Icon(
                                          isStarred ? Icons.star : Icons.star_border,
                                          color: isStarred ? Colors.yellow : Colors.grey,
                                        ),
                                      ),
                                      title: Text(word.word),
                                      subtitle: Text(word.meaning),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      } else {
                        return const Text('No starred word info available');
                      }
                    },
                  );
                } else {
                  return const Text('No words available');
                }
              },
            ),
          ),        ],
      ),
    );
  }
  void _triggerColorChange(int wordId, bool isStarred) {
    Color newColor = isStarred ? Colors.orange : Colors.white;
    setState(() {
      _tileColors[wordId] = newColor;
    });

    // Animasyon sonrası rengi beyaza döndür
    Future.delayed(Duration(seconds: 1), () {
      if (_tileColors[wordId] == newColor) { // Eğer renk değişmediyse
        setState(() {
          _tileColors[wordId] = Colors.white;
        });
      }
    });
  }

  Future<void> toggleStar(int wordId, bool isStarred, int userId) async {
    try {
      // API çağrısını yap ve durumu güncelle
      await ApiService().starWord(wordId, widget.classroomId, widget.studySetId, userId);

      // State'i başarıyla güncelle
      setState(() {
        starredWords[wordId] = !isStarred;
        // Animasyonu burada tetikle
        _triggerColorChange(wordId, !isStarred);
      });
    } catch (e) {
      print('Error toggling star: $e');
      // Hata durumunda kullanıcıya bilgi ver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yıldızlama işlemi başarısız: $e')),
      );
    }
  }
  Widget _buildGameModeTile(BuildContext context, String title, Color color, [VoidCallback? onTap]) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Kenarlık yarıçapı
      ),
      color: color,
      elevation: 4, // Yükselti ve gölge
      child: InkWell(
        onTap: onTap ?? () {
          print('$title tıklandı');
        },
        borderRadius: BorderRadius.circular(10), // Ripple efekti için aynı yarıçap
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // İsteğe bağlı olarak ikon eklenebilir
              // Icon(Icons.gamepad, color: Colors.white),
              // SizedBox(width: 10), // İkon ve metin arasında boşluk
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}