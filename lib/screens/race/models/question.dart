class Question {
  final int id;
  final String englishWord;
  final String turkishWord;
  final List<String> options;
  final int correctOptionIndex;

  Question({
    required this.id,
    required this.englishWord,
    required this.turkishWord,
    required this.options,
    required this.correctOptionIndex,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      englishWord: json['english_word'],
      turkishWord: json['turkish_word'],
      options: List<String>.from(json['options']),
      correctOptionIndex: json['correct_option_index'],
    );
  }
}