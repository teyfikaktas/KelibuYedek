class Question {
  final int id;
  final String englishWord;
  final List<String> options;
  final int correctOptionIndex;

  Question({
    required this.id,
    required this.englishWord,
    required this.options,
    required this.correctOptionIndex,
  });

  // Boş bir soru nesnesi oluşturmak için factory method
  factory Question.empty() {
    return Question(
      id: -1,
      englishWord: "Yükleniyor...",
      options: ["Seçenek 1", "Seçenek 2", "Seçenek 3", "Seçenek 4"],
      correctOptionIndex: 0,
    );
  }

  // JSON dönüşüm metodu...
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      englishWord: json['english_word'],
      options: List<String>.from(json['options']),
      correctOptionIndex: json['correct_option_index'],
    );
  }
}
