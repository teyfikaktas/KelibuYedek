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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animated_background/animated_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class RaceScreenBuild extends StatefulWidget {
  @override
  _RaceScreenBuildState createState() => _RaceScreenBuildState();
}

class _RaceScreenBuildState extends State<RaceScreenBuild> {
  final roomNumberController = TextEditingController();
  bool _isNavigating = false;

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Canlı Yarış',
          style: GoogleFonts.poppins(
            textStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFF5C6BC0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildLogo(),
                    SizedBox(height: 30),
                    _buildInfoBox(),
                    SizedBox(height: 30),
                    _buildRoomNumberField(),
                    SizedBox(height: 20),
                    _buildJoinRoomButton(socketService, userProvider),
                    SizedBox(height: 15),
                    _buildCreateRoomButton(context, socketService, userProvider),
                    SizedBox(height: 30),
                    _buildInfoText(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Shimmer.fromColors(
      baseColor: Colors.white,
      highlightColor: Colors.blue[300]!,
      period: Duration(seconds: 3),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
        ),
        child: Image.asset(
          'assets/logo.png',
          height: 120,
          width: 120,
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white70),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bu uygulama geliştirme aşamasındadır. Hatalar için lütfen bize ulaşın. Phd Akademi size başarılar diler!',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomNumberField() {
    return TextField(
      controller: roomNumberController,
      decoration: InputDecoration(
        hintText: 'Oda Numarası',
        hintStyle: GoogleFonts.poppins(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(Icons.meeting_room, color: Colors.white70),
      ),
      style: GoogleFonts.poppins(color: Colors.white),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildJoinRoomButton(SocketService socketService, UserProvider userProvider) {
    return ElevatedButton.icon(
      onPressed: () {
        final roomNumber = roomNumberController.text;
        final username = userProvider.username;
        if (roomNumber.isNotEmpty && username.isNotEmpty) {
          socketService.setUsername(username);
          socketService.socket!.emit('join room', {'roomNumber': roomNumber, 'username': username});
          roomNumberController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lütfen oda numarası ve kullanıcı adı girin.')),
          );
        }
      },
      icon: Icon(Icons.login, color: Colors.white),
      label: Text(
        'Odaya Katıl',
        style: GoogleFonts.poppins(
          textStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      style: ElevatedButton.styleFrom(
        primary: Color(0xFF303F9F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        minimumSize: Size(double.infinity, 50),
      ),
    );
  }

  Widget _buildCreateRoomButton(BuildContext context, SocketService socketService, UserProvider userProvider) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RoomOptionsScreen(socketService: socketService, username: userProvider.username)),
        );
      },
      icon: Icon(Icons.add, color: Colors.white),
      label: Text(
        'Oda Oluştur',
        style: GoogleFonts.poppins(
          textStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        minimumSize: Size(double.infinity, 50),
      ),
    );
  }

  Widget _buildInfoText() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Text(
        'Şu an yalnızca birebir yarış desteklenmektedir.',
        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        textAlign: TextAlign.center,
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
      socketService.setUsername(widget.username);
    });

    socketService.socket!.on('reset timer', _resetTimer);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    socketService.socket!.off('reset timer', _resetTimer);
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
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
      setState(() {});
    }

    Future.delayed(Duration(seconds: 1), () {
      if (socketService.currentQuestionIndex < socketService.questions.length - 1) {
        socketService.nextQuestion();
        if (mounted) {
          _resetTimer(null);
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'Oda: ${widget.roomNumber}',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
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
              colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFF5C6BC0)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  if (socketService.quizStarted)
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Soru ${socketService.currentQuestionIndex + 1} / ${socketService.questions.length}',
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 16),
                          Card(
                            color: Colors.white.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                socketService.currentQuestion.question,
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(color: Colors.white, fontSize: 20),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Kalan Süre: $_remainingSeconds saniye',
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(color: Colors.yellow, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 24),
                          Expanded(
                            child: ListView.builder(
                              itemCount: socketService.currentQuestion.answers.length,
                              itemBuilder: (context, index) {
                                final answer = socketService.currentQuestion.answers[index];
                                Color tileColor = Colors.white.withOpacity(0.1);
                                if (socketService.userAnswers.containsKey(widget.username) &&
                                    socketService.userAnswers[widget.username] == answer) {
                                  tileColor = Colors.blue.withOpacity(0.5);
                                }
                                if (socketService.bothAnswered) {
                                  if (answer == socketService.currentQuestion.correctAnswer) {
                                    tileColor = Colors.green.withOpacity(0.7);
                                  } else if (socketService.userAnswers.containsKey(widget.username) &&
                                      socketService.userAnswers[widget.username] == answer) {
                                    tileColor = Colors.red.withOpacity(0.7);
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: ElevatedButton(
                                    onPressed: () {
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
                                    child: Text(
                                      answer,
                                      style: GoogleFonts.poppins(
                                        textStyle: TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      primary: tileColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (socketService.userAnswers.containsKey(widget.username) && !socketService.bothAnswered)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                'Diğer kullanıcının yanıtı bekleniyor...',
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(color: Colors.yellow, fontSize: 18),
                                ),
                              ),
                            ),
                          if (socketService.bothAnswered)
                            Column(
                              children: [
                                SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    'Doğru Cevap: ${socketService.currentQuestion.correctAnswer}',
                                    style: GoogleFonts.poppins(
                                      textStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    if (socketService.currentQuestionIndex < socketService.questions.length - 1) {
                                      socketService.nextQuestion();
                                      _resetTimer(null);
                                      _startTimer();
                                    } else {
                                      socketService.endQuiz();
                                    }
                                  },
                                  child: Text(
                                    'Sonraki Soruya Geç',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    primary: Colors.white,
                                    onPrimary: Color(0xFF3949AB),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  if (!socketService.quizStarted) ...[
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Quiz başlaması için bekleniyor...',
                              style: GoogleFonts.poppins(
                                textStyle: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Card(
                      color: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Skorlar',
                              style: GoogleFonts.poppins(
                                textStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(height: 8),
                            ...socketService.userScores.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  '${entry.key}: ${entry.value} puan',
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
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
          _studySet = _packagesTitles.first;
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

      List<int> wordsList = [];
      for (var i = 1; i < csvList.length; i++) {
        var row = csvList[i];
        List<String> rowData = row.split(',"');
        rowData[0] = rowData[0].replaceAll('"', '');
        rowData[1] = rowData[1].substring(0, rowData[1].length - 1);

        if (rowData[0] == classroomId.toString()) {
          String words = rowData[1];
          words = words.substring(1, words.length - 1);
          wordsList = words.split(',').map(int.parse).toList();
          break;
        }
      }

      wordsList.shuffle();
      List<int> selectedWordIds = wordsList.take(int.parse(_questionCount)).toList();

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
          style: GoogleFonts.poppins(
            textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFF5C6BC0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Oda Özellikleri',
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 20),
                          _buildOptionTile(
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
                          SizedBox(height: 20),
                          _buildOptionTile(
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
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    widget.socketService.createRoom(widget.username, _questions, int.parse(_questionCount));
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Oda Oluştur',
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white,
                    onPrimary: Color(0xFF3949AB),
                    padding: EdgeInsets.symmetric(vertical: 15),
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

  Widget _buildOptionTile({
    required String title,
    required List<String> options,
    required IconData icon,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            textStyle: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
              dropdownColor: Color(0xFF3949AB),
              onChanged: onChanged,
              items: options.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}


class WaitingScreen extends StatelessWidget {
  final String roomNumber;

  WaitingScreen({required this.roomNumber});

  bool _isNavigating = false;

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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'Bekleme Odası',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
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
              colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFF5C6BC0)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Colors.white.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Text(
                                'Quiz başlaması için bekleniyor...',
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
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
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Odadaki Kişi Sayısı: ${socketService.userCount}',
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
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
                          style: GoogleFonts.poppins(
                            textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
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
}

class QuizResultScreen extends StatelessWidget {
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Quiz Sonuçları',
          style: GoogleFonts.poppins(
            textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFF5C6BC0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Lottie.asset(
                      'assets/trophy.json',
                      height: 200,
                      width: 200,
                      repeat: true,
                    ),
                    SizedBox(height: 30),
                    Card(
                      color: Colors.white.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 10,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            _buildResultItem('Kazanan', winner, userScores[winner] ?? 0, Colors.green),
                            SizedBox(height: 20),
                            _buildResultItem('İkinci', secondPlace, userScores[secondPlace] ?? 0, Colors.orange),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        socketService.leaveRoom();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => RaceScreenBuild()),
                        );
                      },
                      child: Text(
                        'Ana Sayfaya Dön',
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white,
                        onPrimary: Color(0xFF3949AB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 15),
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

  Widget _buildResultItem(String title, String name, int score, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            textStyle: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Text(
          name,
          style: GoogleFonts.poppins(
            textStyle: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.w600),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 5),
        Text(
          'Puan: $score',
          style: GoogleFonts.poppins(
            textStyle: TextStyle(color: Colors.black54, fontSize: 20),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}