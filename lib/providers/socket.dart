import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:math';

class Question {
  final String question;
  final String correctAnswer;
  final List<String> answers;

  Question({
    required this.question,
    required this.correctAnswer,
    required this.answers,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'] as String,
      correctAnswer: json['correctAnswer'] as String,
      answers: List<String>.from(json['answers']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'correctAnswer': correctAnswer,
      'answers': answers,
    };
  }
}

class SocketService with ChangeNotifier {
  IO.Socket? socket;
  List<String> messages = [];
  int userCount = 0;
  String _currentRoom = '';
  String _username = ''; // Kullanıcı adını saklamak için
  List<Question> questions = [];
  int currentQuestionIndex = 0;
  Map<String, String> userAnswers = {};
  Map<String, int> userScores = {};
  bool bothAnswered = false;
  bool quizStarted = false;
  bool quizEnded = false;
  List<String> usersInRoom = [];

  SocketService() {
    _connectToSocket();
  }

  String get currentRoom => _currentRoom;
  String get username => _username; // Kullanıcı adı getter

  void setUsername(String name) {
    _username = name;
  } // Kullanıcı adı setter

  Question get currentQuestion {
    if (currentQuestionIndex >= 0 && currentQuestionIndex < questions.length) {
      return questions[currentQuestionIndex];
    } else {
      return Question(question: '', correctAnswer: '', answers: []);
    }
  }

  void _connectToSocket() {
    socket = IO.io('https://nervous-bhabha.213-238-168-122.plesk.page', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'ssl': true,
    });

    socket!.on('connect', (_) {
      addMessage('Bir Flutter cihazı bağlandı');
      print('Connected to socket server');
    });

    socket!.on('user connected', (_) {
      addMessage('Bir cihaz bağlandı');
      fetchRoomInfo();
    });

    socket!.on('user disconnected', (_) {
      addMessage('Bir cihaz ayrıldı');
      fetchRoomInfo();
    });

    socket!.on('disconnect', (_) {
      addMessage('Bir Flutter cihazı ayrıldı');
      print('Disconnected from socket server');
    });

    socket!.on('connect_error', (error) {
      addMessage('Bağlantı hatası: $error');
      print('Connect error: $error');
    });

    socket!.on('connect_timeout', (error) {
      addMessage('Bağlantı zaman aşımı: $error');
      print('Connect timeout: $error');
    });

    socket!.on('error', (error) {
      addMessage('Hata: $error');
      print('Error: $error');
    });

    socket!.on('room created', (roomNumber) => _onRoomCreated(roomNumber));
    socket!.on('room info', (data) => _onRoomInfo(data));
    socket!.on('join room success', (roomNumber) => _onJoinRoomSuccess(roomNumber));
    socket!.on('join room error', (error) => addMessage('Hata: $error'));
    socket!.on('answer submitted', (data) => _onAnswerSubmitted(data));
    socket!.on('both answered', (data) => _onBothAnswered(data));
    socket!.on('next question', (data) => _onNextQuestion(data));
    socket!.on('quiz start', (_) => _onQuizStart());
    socket!.on('quiz end', (data) => _onQuizEnd(data));
    socket!.on('user left', (_) => _onUserLeft());

    if (socket!.disconnected) {
      socket!.connect();
    }
  }

  void fetchRoomInfo() {
    if (socket != null && socket!.connected) {
      print('Fetching room info');
      socket!.emit('get room info', _currentRoom);
    }
  }

  void _onRoomCreated(dynamic roomNumber) {
    addMessage('Oda oluşturuldu: $roomNumber');
    _currentRoom = roomNumber;
    _resetQuiz();
    fetchRoomInfo();
    notifyListeners();
  }

  void _onRoomInfo(dynamic data) {
    print('Room info received: $data');

    final roomNumber = data['roomNumber']?.toString() ?? 'Unknown';
    final userCount = data['userCount'] is int
        ? data['userCount'] as int
        : int.tryParse(data['userCount']?.toString() ?? '') ?? 0;

    final users = data['users'] is List
        ? List<dynamic>.from(data['users'])
        : [];

    // Kullanıcıların yalnızca isimlerini alıyoruz
    this.usersInRoom = users.map((user) {
      if (user is Map<String, dynamic> && user.containsKey('username')) {
        return user['username']?.toString() ?? 'Unknown';
      } else if (user is String) {
        return user;
      } else {
        return 'Unknown';
      }
    }).toList();

    // Hata ayıklama için kullanıcı isimlerini yazdırıyoruz
    print('Users in room: ${this.usersInRoom}');

    // Soruları işlemek (varsa)
    if (users.isNotEmpty && users[0] is Map && (users[0] as Map).containsKey('questions')) {
      final firstUser = users[0] as Map<String, dynamic>;
      final questionsJson = firstUser['questions'] as List<dynamic>;
      questions = questionsJson.map((question) {
        return Question.fromJson(question as Map<String, dynamic>);
      }).toList();
    }

    addMessage('Oda $roomNumber\'daki kişi sayısı: $userCount');
    this.userCount = userCount;
    notifyListeners();
  }

  void _onJoinRoomSuccess(dynamic roomNumber) {
    addMessage('$roomNumber numaralı odaya katıldınız');
    _currentRoom = roomNumber;
    fetchRoomInfo();
    notifyListeners();
  }

  void _onAnswerSubmitted(dynamic data) {
    final answer = data['answer'];
    final username = data['username'];
    userAnswers[username] = answer;

    // Check if both users have answered
    bothAnswered = userAnswers.length == userCount;
    if (bothAnswered) {
      socket!.emit('both answered', {'roomNumber': _currentRoom, 'userAnswers': userAnswers});
    }

    // Kullanıcı puanlarını güncelle
    if (data.containsKey('scores')) {
      userScores = Map<String, int>.from(data['scores']);
    }

    notifyListeners();
  }

  void _onBothAnswered(dynamic data) {
    if (data != null) {
      userAnswers = Map<String, String>.from(data['userAnswers']);
      bothAnswered = true;
      notifyListeners();
    }
  }

  void _onNextQuestion(dynamic data) {
    if (currentQuestionIndex < questions.length - 1) {
      currentQuestionIndex++;
    } else {
      endQuiz();
    }
    userAnswers.clear();
    bothAnswered = false;
    notifyListeners();
  }

  void _onQuizStart() {
    quizStarted = true;
    notifyListeners();
  }

  void _onQuizEnd(dynamic data) {
    if (data != null) {
      try {
        final correctAnswers = data['correctAnswers'] != null
            ? List<String>.from(data['correctAnswers'])
            : <String>[];

        final userScoresData = data['userScores'] != null
            ? (data['userScores'] as Map).map((key, value) => MapEntry(key.toString(), value as int))
            : <String, int>{};

        userScores = userScoresData;
        quizEnded = true;
        notifyListeners();
      } catch (e) {
        print("Quiz end data format error: $e");
      }
    }
  }

  void submitAnswer(String username, String answer) {
    if (userAnswers[username] == null) {
      userAnswers[username] = answer;
      socket!.emit('submit answer', {
        'roomNumber': _currentRoom,
        'answer': answer,
        'username': username,
        'question': currentQuestion.question,
        'correctAnswer': currentQuestion.correctAnswer
      });
    }
  }

  void nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      socket!.emit('next question', {
        'roomNumber': _currentRoom,
        'question': questions[currentQuestionIndex + 1].toJson(),
      });
    } else {
      endQuiz();
    }
  }

  void endQuiz() {
    socket!.emit('quiz end', {
      'roomNumber': _currentRoom,
      'userScores': userScores,
      'correctAnswers': questions.map((q) => q.correctAnswer).toList(),
    });
  }

  void createRoom(String username, List<Question> questions, int questionCount) {
    this.questions = questions;

    // Soruları karıştır ve istenilen sayıda seç
    questions.shuffle();
    questions = questions.take(questionCount).toList();

    socket!.emit('create room', {'username': username, 'questions': questions.map((q) => q.toJson()).toList()});
  }

  String determineWinner() {
    if (userScores.isEmpty) return 'Unknown';

    int maxScore = userScores.values.isNotEmpty ? userScores.values.reduce((a, b) => a > b ? a : b) : 0;
    List<String> topScorers = userScores.entries.where((entry) => entry.value == maxScore).map((entry) => entry.key).toList();

    if (topScorers.length > 1) {
      return 'Berabere';
    } else {
      return topScorers.isNotEmpty ? topScorers[0] : 'Unknown';
    }
  }

  String determineSecondPlace() {
    if (userScores.length <= 1) return 'Unknown';

    List<MapEntry<String, int>> sortedScores = userScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedScores.length > 1 ? sortedScores[1].key : 'Unknown';
  }

  void _onUserLeft() {
    _resetQuiz();
    notifyListeners();
  }

  void _resetQuiz() {
    currentQuestionIndex = 0;
    userAnswers.clear();
    userScores.clear();
    bothAnswered = false;
    quizStarted = false;
    quizEnded = false;
    userCount = 0;
    usersInRoom.clear();
  }

  void leaveRoom() {
    if (_currentRoom.isNotEmpty) {
      socket!.emit('leave room', _currentRoom);
      _resetQuiz();
      _currentRoom = '';
      notifyListeners();
    }
  }

  void addMessage(String message) {
    print('addMessage called: $message');
    messages.add(message);
    notifyListeners();
  }

  int get currentUserScore {
    return userScores.entries.firstWhere((entry) => entry.key == _username, orElse: () => MapEntry(_username, 0)).value;
  }
}
