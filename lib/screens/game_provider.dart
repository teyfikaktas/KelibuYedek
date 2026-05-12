import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(GameState.initial()) {
    shuffleWords();
  }

  void shuffleWords() {
    var random = Random();
    state = state.copyWith(
      remainingWords: state.remainingWords..shuffle(random),
      currentWordIndex: 0,
    );
    setOptions();
  }

  void setOptions() {
    var currentWord = state.remainingWords[state.currentWordIndex].keys.first;
    var correctAnswer =
        state.remainingWords[state.currentWordIndex][currentWord]!;
    var options = [correctAnswer];
    var random = Random();

    while (options.length < 4) {
      var option = state
          .remainingWords[random.nextInt(state.remainingWords.length)]
          .values
          .first;
      if (!options.contains(option)) {
        options.add(option);
      }
    }

    options.shuffle(random);
    state = state.copyWith(options: options, selectedAnswer: '');
  }

  void selectAnswer(String answer) {
    var currentWord = state.remainingWords[state.currentWordIndex].keys.first;
    var correctAnswer =
        state.remainingWords[state.currentWordIndex][currentWord]!;
    if (answer == correctAnswer) {
      state = state.copyWith(correctAnswers: state.correctAnswers + 1);
      if (state.correctAnswers % 3 == 0) {
        state = state.copyWith(
          remainingWords: List.from(state.remainingWords)
            ..removeAt(state.currentWordIndex),
          correctAnswers: 0,
        );
        if (state.remainingWords.isEmpty) {
          state = state.copyWith(gameFinished: true);
          return;
        }
      }
      shuffleWords();
    } else {
      setOptions();
    }
  }
}

class GameState {
  final List<Map<String, String>> remainingWords;
  final List<String> options;
  final int currentWordIndex;
  final int correctAnswers;
  final String selectedAnswer;
  final bool gameFinished;

  GameState({
    required this.remainingWords,
    required this.options,
    required this.currentWordIndex,
    required this.correctAnswers,
    required this.selectedAnswer,
    required this.gameFinished,
  });

  factory GameState.initial() {
    return GameState(
      remainingWords: [
        {"apple": "elma"},
        {"tree": "ağaç"},
        {"book": "kitap"},
        {"car": "araba"},
        {"dog": "köpek"},
        {"flower": "çiçek"},
        {"house": "ev"},
        {"computer": "bilgisayar"},
      ],
      options: [],
      currentWordIndex: 0,
      correctAnswers: 0,
      selectedAnswer: '',
      gameFinished: false,
    );
  }

  GameState copyWith({
    List<Map<String, String>>? remainingWords,
    List<String>? options,
    int? currentWordIndex,
    int? correctAnswers,
    String? selectedAnswer,
    bool? gameFinished,
  }) {
    return GameState(
      remainingWords: remainingWords ?? this.remainingWords,
      options: options ?? this.options,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      gameFinished: gameFinished ?? this.gameFinished,
    );
  }
}
