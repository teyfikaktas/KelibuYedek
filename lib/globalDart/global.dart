import 'package:kelibu/Models/wordDetaik.dart'; // WordDetail modelinizin importu

abstract class StarredWordsEvent {}

class LoadStarredWords extends StarredWordsEvent {}

class RefreshStarredWords extends StarredWordsEvent {}

// starred_words_state.dart
abstract class StarredWordsState {}

class StarredWordsInitial extends StarredWordsState {}

class StarredWordsLoading extends StarredWordsState {}

class StarredWordsLoaded extends StarredWordsState {
  final List<WordDetail> words;

  StarredWordsLoaded(this.words);
}

class StarredWordsError extends StarredWordsState {
  final String message;

  StarredWordsError(this.message);
}
