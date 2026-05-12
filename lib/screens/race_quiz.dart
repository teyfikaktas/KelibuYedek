import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class RaceQuizScreen extends StatefulWidget {
  final IO.Socket socket;
  final String roomNumber;

  RaceQuizScreen({required this.socket, required this.roomNumber});

  @override
  _RaceQuizScreenState createState() => _RaceQuizScreenState();
}

class _RaceQuizScreenState extends State<RaceQuizScreen> {
  int questionIndex = 0;
  int correctAnswerIndex = -1;
  bool answerRevealed = false;

  List<Map<String, dynamic>> questions = [
    {
      'question': 'Translate "apple" to Turkish.',
      'answers': ['Elma', 'Armut', 'Muz', 'Karpuz', 'Portakal'],
      'correctAnswer': 0,
    },
    {
      'question': 'Translate "car" to Turkish.',
      'answers': ['Araba', 'Bisiklet', 'Uçak', 'Gemi', 'Tren'],
      'correctAnswer': 0,
    },
    {
      'question': 'Translate "book" to Turkish.',
      'answers': ['Kitap', 'Kalem', 'Defter', 'Sözlük', 'Gazete'],
      'correctAnswer': 0,
    },
    {
      'question': 'Translate "house" to Turkish.',
      'answers': ['Ev', 'Bina', 'Okul', 'Hastane', 'Mağaza'],
      'correctAnswer': 0,
    },
    {
      'question': 'Translate "cat" to Turkish.',
      'answers': ['Kedi', 'Köpek', 'Kuş', 'Balık', 'Fare'],
      'correctAnswer': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
    widget.socket.on('reveal answer', onRevealAnswer);
    widget.socket.on('next question', onNextQuestion);
  }

  void onRevealAnswer(dynamic data) {
    if (mounted) {
      setState(() {
        correctAnswerIndex = data['correctAnswer'];
        answerRevealed = true;
      });
    }
  }

  void onNextQuestion(dynamic data) {
    if (mounted) {
      setState(() {
        questionIndex = data['questionIndex'];
        correctAnswerIndex = -1;
        answerRevealed = false;
      });
    }
  }

  void answerQuestion(int answerIndex) {
    widget.socket.emit('answer', {
      'roomNumber': widget.roomNumber,
      'questionIndex': questionIndex,
      'answerIndex': answerIndex,
    });
  }

  @override
  void dispose() {
    widget.socket.off('reveal answer', onRevealAnswer);
    widget.socket.off('next question', onNextQuestion);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[questionIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Room: ${widget.roomNumber}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(question['question']),
            ...List.generate(question['answers'].length, (index) {
              return ListTile(
                title: Text(question['answers'][index]),
                onTap: answerRevealed
                    ? null
                    : () {
                        answerQuestion(index);
                      },
                tileColor: answerRevealed && index == correctAnswerIndex
                    ? Colors.green
                    : null,
              );
            }),
            if (answerRevealed)
              ElevatedButton(
                onPressed: () {
                  widget.socket
                      .emit('next question', {'roomNumber': widget.roomNumber});
                },
                child: Text('Next Question'),
              ),
          ],
        ),
      ),
    );
  }
}
