import 'package:flutter_riverpod/flutter_riverpod.dart';

final globalUserIdProvider = StateProvider<int>((ref) => 1);
final globalUsernameProvider = StateProvider<String>((ref) => '');
