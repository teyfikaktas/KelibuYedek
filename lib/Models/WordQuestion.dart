class WordQuestionOption {
  final int id;
  final int wordQuestionId;
  final String optionLetter;
  final String optionText;
  final bool isCorrect;
  final DateTime createdAt;
  final DateTime updatedAt;

  WordQuestionOption({
    required this.id,
    required this.wordQuestionId,
    required this.optionLetter,
    required this.optionText,
    required this.isCorrect,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WordQuestionOption.fromJson(Map<String, dynamic> json) {
    return WordQuestionOption(
      id: json['id'],
      wordQuestionId: json['word_question_id'],
      optionLetter: json['option_letter'],
      optionText: json['option_text'],
      isCorrect: json['is_correct'] == 1 || json['is_correct'] == true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word_question_id': wordQuestionId,
      'option_letter': optionLetter,
      'option_text': optionText,
      'is_correct': isCorrect,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}