import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

import '../Models/category.dart';
import '../providers/socket.dart';
import '../providers/user_provider.dart';

class RaceScreenBuild extends StatefulWidget {
  @override
  _RaceScreenBuildState createState() => _RaceScreenBuildState();
}



class _RaceScreenBuildState extends State<RaceScreenBuild> {
  final roomNumberController = TextEditingController();

  bool _isNavigating = false;  // Navigasyon durumu için kontrol değişkeni

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);
    final userProvider = Provider.of<UserProvider>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isNavigating) {
        if (socketService.currentRoom.isNotEmpty && socketService.quizStarted) {
          _isNavigating = true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoomScreen(roomNumber: socketService.currentRoom, username: userProvider.username),
            ),
          );
        } else if (socketService.currentRoom.isNotEmpty && !socketService.quizStarted) {
          _isNavigating = true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WaitingScreen(roomNumber: socketService.currentRoom),
            ),
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Canlı Yarış',
          style: GoogleFonts.pressStart2p(
            textStyle: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.pink.shade300,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink.shade300, Colors.purple.shade900],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 100,
                        width: 100,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Bu uygulama hala geliştirme aşamasındadır. Bir hata oluşması durumunda lütfen iletişim kısmından bize ulaşarak gelişimimize destek olun. Phd Akademi öğrenim sürecinizde size başarılar diler!',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: roomNumberController,
                    decoration: InputDecoration(
                      hintText: 'Oda Numarası',
                      hintStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.videogame_asset, color: Colors.white),
                    ),
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      final roomNumber = roomNumberController.text;
                      final username = userProvider.username;
                      if (roomNumber.isNotEmpty && username.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          socketService.setUsername(username); // Kullanıcı adını ayarla
                        });
                        socketService.socket!.emit('join room', {'roomNumber': roomNumber, 'username': username});
                        roomNumberController.clear();
                      }
                    },
                    icon: Icon(Icons.meeting_room, color: Colors.purple.shade700),
                    label: Text(
                      'Odaya Katıl',
                      style: GoogleFonts.pressStart2p(
                        textStyle: TextStyle(color: Colors.purple.shade700),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RoomOptionsScreen(socketService: socketService, username: userProvider.username)),
                      );
                    },
                    icon: Icon(Icons.add, color: Colors.pink.shade700),
                    label: Text(
                      'Oda Oluştur',
                      style: GoogleFonts.pressStart2p(
                        textStyle: TextStyle(color: Colors.pink.shade700),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      'Şu an yalnızca birebir yarış desteklenmektedir.',
                      style: TextStyle(color: Colors.white),
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
}


class ChatRoomScreen extends StatefulWidget {
  final String roomNumber;
  final String username;

  ChatRoomScreen({required this.roomNumber, required this.username});

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  Timer? _timer;
  int _remainingSeconds = 15;
  late SocketService socketService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    socketService = Provider.of<SocketService>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      socketService.setUsername(widget.username); // Kullanıcı adını ayarla
    });

    socketService.socket!.on('reset timer', _resetTimer); // Timer resetleme olayını dinleyin
    _startTimer();
  }


  @override
  void dispose() {
    _timer?.cancel();
    socketService.socket!.off('reset timer', _resetTimer); // Timer resetleme olayını kaldırın
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel(); // Var olan bir zamanlayıcıyı iptal et
    if (mounted) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            if (_remainingSeconds > 0) {
              _remainingSeconds--;
            } else {
              _showCorrectAnswer();
              _timer?.cancel();
            }
          });
        } else {
          timer.cancel();
        }
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _resetTimer(data) {
    if (mounted) {
      setState(() {
        _remainingSeconds = 15;
      });
    }
  }

  void _showCorrectAnswer() {
    socketService.bothAnswered = true;

    if (mounted) {
      setState(() {}); // Bu satırı ekleyerek UI'ı güncelleyip renk değişikliklerini görmesini sağlayın
    }

    Future.delayed(Duration(seconds: 1), () {
      if (socketService.currentQuestionIndex < socketService.questions.length - 1) {
        socketService.nextQuestion();
        if (mounted) {
          _resetTimer(null); // Yeni soruya geçildiğinde zamanlayıcıyı sıfırla ve başlat
          _startTimer();
        }
      } else {
        socketService.endQuiz();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (socketService.quizEnded) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              userScores: socketService.userScores,
              winner: socketService.determineWinner(),
              secondPlace: socketService.determineSecondPlace(),
            ),
          ),
        );
      }
    });

    return WillPopScope(
      onWillPop: () async {
        socketService.leaveRoom();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Oda: ${widget.roomNumber}',
            style: GoogleFonts.pressStart2p(
              textStyle: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: Colors.pink.shade300,
          actions: [
            IconButton(
              icon: Icon(Icons.exit_to_app, color: Colors.white),
              onPressed: () {
                socketService.leaveRoom();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RaceScreenBuild(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.pink.shade300, Colors.purple.shade900],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (socketService.quizStarted)
                  Column(
                    children: [
                      Text(
                        'Soru ${socketService.currentQuestionIndex + 1} / ${socketService.questions.length}',
                        style: GoogleFonts.pressStart2p(
                          textStyle: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        socketService.currentQuestion.question,
                        style: GoogleFonts.pressStart2p(
                          textStyle: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Kalan Süre: $_remainingSeconds saniye',
                        style: GoogleFonts.pressStart2p(
                          textStyle: TextStyle(color: Colors.yellow, fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Column(
                          children: socketService.currentQuestion.answers.map((answer) {
                            Color tileColor = Colors.grey.shade800;
                            if (socketService.userAnswers.containsKey(widget.username) &&
                                socketService.userAnswers[widget.username] == answer) {
                              tileColor = Colors.blue.withOpacity(0.5);
                            }
                            if (socketService.bothAnswered) {
                              if (answer == socketService.currentQuestion.correctAnswer) {
                                tileColor = Colors.green;
                              } else if (socketService.userAnswers.containsKey(widget.username) &&
                                  socketService.userAnswers[widget.username] == answer) {
                                tileColor = Colors.red;
                              }
                            }

                            return InkWell(
                              onTap: () {
                                if (!socketService.userAnswers.containsKey(widget.username)) {
                                  socketService.submitAnswer(widget.username, answer);
                                  _stopTimer();
                                  if (socketService.userAnswers.length == socketService.userCount) {
                                    _showCorrectAnswer();
                                  }
                                  if (mounted) {
                                    setState(() {});
                                  }
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: tileColor,
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(color: Colors.white, width: 1.0),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                padding: const EdgeInsets.all(12.0),
                                child: Center(
                                  child: Text(
                                    answer,
                                    style: GoogleFonts.pressStart2p(
                                      textStyle: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 20),
                      if (socketService.userAnswers.containsKey(widget.username) && !socketService.bothAnswered)
                        Text(
                          'Diğer kullanıcının yanıtı bekleniyor...',
                          style: GoogleFonts.pressStart2p(
                            textStyle: TextStyle(color: Colors.yellow, fontSize: 18),
                          ),
                        ),
                      if (socketService.bothAnswered)
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Text(
                                'Doğru Cevap: ${socketService.currentQuestion.correctAnswer}',
                                style: GoogleFonts.pressStart2p(
                                  textStyle: TextStyle(color: Colors.white, fontSize: 18),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                if (socketService.currentQuestionIndex < socketService.questions.length - 1) {
                                  socketService.nextQuestion();
                                  _resetTimer(null); // Yeni soruya geçildiğinde zamanlayıcıyı sıfırla ve başlat
                                  _startTimer();
                                } else {
                                  socketService.endQuiz();
                                }
                              },
                              child: Text(
                                'Sonraki Soruya Geç',
                                style: GoogleFonts.pressStart2p(),
                              ),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.white,
                                onPrimary: Colors.pink.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                if (!socketService.quizStarted) ...[
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Quiz başlaması için bekleniyor...',
                    style: GoogleFonts.pressStart2p(
                      textStyle: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                Spacer(),
                // Kullanıcı puanlarını göstermek için eklenen bölüm
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: socketService.userScores.entries.map((entry) {
                      return Text(
                        '${entry.key}: ${entry.value} puan',
                        style: GoogleFonts.pressStart2p(
                          textStyle: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RoomOptionsScreen extends StatefulWidget {
  final SocketService socketService;
  final String username;

  RoomOptionsScreen({required this.socketService, required this.username});

  @override
  _RoomOptionsScreenState createState() => _RoomOptionsScreenState();
}

class _RoomOptionsScreenState extends State<RoomOptionsScreen> {
  String _questionCount = '10';
  String _studySet = 'Demo Sınıf';
  String _timeLimit = '10';
  String _examType = 'Türkçe\'den İngilizce\'ye';
  String _imageStatus = 'Var';
  String _selectedPackageTitle = '';
  List<String> _packagesTitles = [];
  List<int> _packageIds = [];
  List<int> _classroomIds = [];
  List<int> _wordIds = [];
  List<Question> _questions = [];
  Map<int, Map<String, String>> _wordDetailsCache = {};

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  void _loadPackages() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String packageData = prefs.getString('packages') ?? '[]';
      List<dynamic> jsonData = json.decode(packageData);
      List<Package> packages = jsonData.map((item) => Package.fromJson(item)).toList();
      setState(() {
        _packagesTitles = packages.map((p) => p.classroom?.title ?? 'No title').toList();
        _packageIds = packages.map((p) => p.id).toList();
        _classroomIds = packages.map((p) => p.classroom?.id ?? -1).toList();

        if (_packagesTitles.isNotEmpty) {
          _selectedPackageTitle = _packagesTitles.first;
          _studySet = _packagesTitles.first; // Set initial value to the first item
          // Rastgele bir çalışma seti seç
          int selectedClassroomId = _classroomIds.first;
          loadRandomWordsForClassroom(selectedClassroomId);
        }
      });
      print('Packages loaded successfully');
    } catch (e) {
      print('Error loading packages: $e');
    }
  }

  Future<void> loadRandomWordsForClassroom(int classroomId) async {
    try {
      print('Loading random words for classroomId: $classroomId');
      String wordsFilePath = 'assets/Model/study_sets.csv';
      final csvFile = await rootBundle.loadString(wordsFilePath);
      List<String> csvList = LineSplitter().convert(csvFile);

      // İlk satırı başlık olarak kabul edip atlıyoruz
      List<int> wordsList = [];
      for (var i = 1; i < csvList.length; i++) {
        var row = csvList[i];
        List<String> rowData = row.split(',"');
        rowData[0] = rowData[0].replaceAll('"', ''); // Satır başındaki " karakterini kaldır
        rowData[1] = rowData[1].substring(0, rowData[1].length - 1); // Satır sonundaki " karakterini kaldır

        if (rowData[0] == classroomId.toString()) {
          // İlgili satırı bulduk
          String words = rowData[1];
          words = words.substring(1, words.length - 1); // Köşeli parantezleri kaldır

          // Kelimeleri listeye dönüştür
          wordsList = words.split(',').map(int.parse).toList();
          break;
        }
      }

      // Rastgele kelime ID'leri seç
      wordsList.shuffle();
      List<int> selectedWordIds = wordsList.take(int.parse(_questionCount)).toList();

      // Kelime detaylarını yükle ve soruları oluştur
      await loadWordsDetails(selectedWordIds);
      print('Random words loaded for classroomId: $classroomId');
    } catch (e) {
      print('Error loading random words for classroomId $classroomId: $e');
    }
  }

  Future<void> loadWordsDetails(List<int> wordIds) async {
    try {
      print('Loading word details for wordIds: $wordIds');
      if (_wordDetailsCache.isEmpty) {
        await _loadWordDetailsCache();
      }

      List<Map<String, String>> wordDetails = wordIds
          .where((id) => _wordDetailsCache.containsKey(id))
          .map((id) => _wordDetailsCache[id]!)
          .toList();

      setState(() {
        _questions = createQuestions(wordDetails);
      });
      print('Word details loaded for wordIds: $wordIds');
    } catch (e) {
      print('Error loading word details: $e');
    }
  }

  Future<void> _loadWordDetailsCache() async {
    try {
      print('Loading word details cache');
      String wordsFilePath = 'assets/Model/race.csv';
      final csvFile = await rootBundle.loadString(wordsFilePath);
      List<String> csvList = LineSplitter().convert(csvFile);

      for (var i = 1; i < csvList.length; i++) {
        var row = csvList[i];
        List<String> rowData = row.split(',');

        if (rowData.length >= 4) {
          int wordId = int.parse(rowData[0].replaceAll('"', ''));
          String term = rowData[1].replaceAll('"', '');
          String definition = rowData[2].replaceAll('"', '');
          String type = rowData[3].replaceAll('"', '');

          // Eğer tanım veya tür NULL ise bunları boş string olarak ayarlayın
          if (definition.toLowerCase() == 'null') {
            definition = '';
          }
          if (type.toLowerCase() == 'null') {
            type = '';
          }

          _wordDetailsCache[wordId] = {
            'term': term,
            'definition': definition,
            'type': type,
          };
        } else {
          print("Satır veri formatı geçersiz: $row");
        }
      }
      print('Word details cache loaded successfully');
    } catch (e) {
      print("Error loading word details cache: $e");
    }
  }

  List<Question> createQuestions(List<Map<String, String>> wordDetails) {
    List<Question> questions = [];
    Random random = Random();

    for (var word in wordDetails) {
      List<String> answers = [word['term']!];
      while (answers.length < 4) {
        var randomWord = wordDetails[random.nextInt(wordDetails.length)]['term']!;
        if (!answers.contains(randomWord)) {
          answers.add(randomWord);
        }
      }
      answers.shuffle();

      questions.add(Question(
        question: word['definition']!,
        correctAnswer: word['term']!,
        answers: answers,
      ));
    }

    return questions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Oda Ayarları',
          style: GoogleFonts.pressStart2p(
            textStyle: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.pink.shade300,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink.shade300, Colors.purple.shade900],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildDropdownTile(
                context,
                title: 'Soru Adedi',
                options: ['5', '10', '20', '30'],
                icon: Icons.format_list_numbered,
                value: _questionCount,
                onChanged: (String? newValue) {
                  setState(() {
                    _questionCount = newValue!;
                  });
                },
              ),
              _buildDropdownTile(
                context,
                title: 'Çalışma Seti',
                options: _packagesTitles,
                icon: Icons.book,
                value: _studySet,
                onChanged: (String? newValue) async {
                  if (newValue != null && newValue != 'Bir set seçiniz') {
                    setState(() {
                      _studySet = newValue;
                    });
                    int selectedClassroomId = _classroomIds[_packagesTitles.indexOf(newValue)];
                    await loadRandomWordsForClassroom(selectedClassroomId);
                  }
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  widget.socketService.createRoom(widget.username, _questions, int.parse(_questionCount));
                  Navigator.pop(context);
                },
                child: Text(
                  'Oda Oluştur',
                  style: GoogleFonts.pressStart2p(),
                ),
                style: ElevatedButton.styleFrom(
                  primary: Colors.white,
                  onPrimary: Colors.pink.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownTile(BuildContext context, {required String title, required List<String> options, required IconData icon, required String value, required ValueChanged<String?> onChanged}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      trailing: Container(
        constraints: BoxConstraints(maxWidth: 200), // Dropdown için maksimum genişlik ayarla
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          dropdownColor: Colors.purple.shade700,
          onChanged: onChanged,
          underline: Container(), // Alt çizgiyi kaldır
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: TextStyle(color: Colors.white)),
            );
          }).toList(),
        ),
      ),
    );
  }
}
class WaitingScreen extends StatelessWidget {
  final String roomNumber;

  WaitingScreen({required this.roomNumber});

  bool _isNavigating = false;  // Navigasyon durumu için kontrol değişkeni

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isNavigating && socketService.quizStarted) {
        _isNavigating = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(roomNumber: roomNumber, username: 'Unknown'),
          ),
        );
      }
    });

    return WillPopScope(
      onWillPop: () async {
        socketService.leaveRoom();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Lütfen Bekleyin',
            style: GoogleFonts.pressStart2p(
              textStyle: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: Colors.pink.shade300,
          actions: [
            IconButton(
              icon: Icon(Icons.exit_to_app, color: Colors.white),
              onPressed: () {
                socketService.leaveRoom();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RaceScreenBuild(),
                  ),
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.pink.shade300, Colors.purple.shade900],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Quiz başlaması için bekleniyor...',
                      style: GoogleFonts.pressStart2p(
                        textStyle: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Oda Numarası: $roomNumber',
                      style: GoogleFonts.pressStart2p(
                        textStyle: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Odadaki Kişi Sayısı: ${socketService.userCount}',
                      style: GoogleFonts.pressStart2p(
                        textStyle: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        final text = 'Oda Numarası: $roomNumber';
                        Share.share(text, subject: 'Quiz Oda Numarası');
                      },
                      icon: Icon(Icons.share, color: Colors.white),
                      label: Text(
                        'Oda Numarasını Paylaş',
                        style: GoogleFonts.pressStart2p(
                          textStyle: TextStyle(color: Colors.white),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}class QuizResultScreen extends StatelessWidget {
  final Map<String, int> userScores;
  final String winner;
  final String secondPlace;

  QuizResultScreen({
    required this.userScores,
    required this.winner,
    required this.secondPlace,
  });

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz Sonuçları',
          style: GoogleFonts.pressStart2p(
            textStyle: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.pink.shade300,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink.shade300, Colors.purple.shade900],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Lottie.asset(
                  'assets/trophy.json',
                  height: 150,
                  width: 150,
                  repeat: false,
                ),
                SizedBox(height: 20),
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Kazanan: $winner',
                          style: GoogleFonts.pressStart2p(
                            textStyle: TextStyle(color: Colors.green, fontSize: 20),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Puan: ${userScores[winner]}',
                          style: GoogleFonts.pressStart2p(
                            textStyle: TextStyle(color: Colors.green, fontSize: 18),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'İkinci: $secondPlace',
                          style: GoogleFonts.pressStart2p(
                            textStyle: TextStyle(color: Colors.red, fontSize: 20),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Puan: ${userScores[secondPlace]}',
                          style: GoogleFonts.pressStart2p(
                            textStyle: TextStyle(color: Colors.red, fontSize: 18),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    socketService.leaveRoom();  // Odayı terk et ve sıfırla
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => RaceScreenBuild()),
                    );
                  },
                  child: Text(
                    'Ana Sayfaya Dön',
                    style: GoogleFonts.pressStart2p(),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white,
                    onPrimary: Colors.pink.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}