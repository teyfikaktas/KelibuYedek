import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global kullanıcı ID'sini tutacak StateProvider.
/// Başlangıç değeri 1 (test için, users tablosunda var olmalı).
final globalUserIdProvider = StateProvider<int>((ref) => 1);
final globalUsernameProvider = StateProvider<String>((ref) => '');