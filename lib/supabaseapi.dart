// pubspec.yaml'a ekle:
// supabase_flutter: ^2.0.0
// google_sign_in: ^6.2.1
// sign_in_with_apple: ^6.1.0

import 'package:supabase_flutter/supabase_flutter.dart';

// ApiException'ı burada tanımla - import etme
class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? details;

  ApiException(this.message, {this.details});

  @override
  String toString() {
    return 'ApiException: $message';
  }
}

class SupabaseApiService {
  // Supabase client'ı al
  final SupabaseClient supabase = Supabase.instance.client;

  // ================== EMAIL/PASSWORD LOGIN ==================
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String fcmToken,
  }) async {
    try {
      // 1. Supabase Auth ile giriş yap
      final AuthResponse authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw ApiException('Giriş başarısız');
      }

      final user = authResponse.user!;

      // 2. user_profiles tablosundan kullanıcı bilgilerini al
      final profileResponse = await supabase
          .from('user_profiles')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (profileResponse == null) {
        throw ApiException('Kullanıcı profili bulunamadı');
      }

      // 3. FCM token'ı güncelle (eğer varsa)
      if (fcmToken.isNotEmpty) {
        await supabase
            .from('user_profiles')
            .update({'fcm_token': fcmToken}).eq('user_id', user.id);
      }

      // 4. Laravel formatında response döndür (uyumluluk için)
      return {
        'user': {
          'id': profileResponse['id'], // user_profiles id'si
          'name': profileResponse['name'],
          'first_name': profileResponse['first_name'],
          'last_name': profileResponse['last_name'],
          'email': user.email,
          'phone': profileResponse['phone'],
          'avatar': profileResponse['avatar'],
          'point': profileResponse['point'] ?? 0,
          'level': profileResponse['level'] ?? 1,
          'city': profileResponse['city'],
          'birth_year': profileResponse['birth_year'],
          'team': profileResponse['team'],
          'created_at': profileResponse['created_at'],
          'phone_verified': profileResponse['is_phone_verified'] ?? false,
          'streak_count': 0, // Bu alanları sonra ekleyebilirsin
          'daily_rank': 0,
          'weekly_rank': 0,
          'monthly_rank': 0,
          'all_time_rank': 0,
        },
        'access_token': authResponse.session?.accessToken,
        'refresh_token': authResponse.session?.refreshToken,
        'token_type': 'Bearer',
        'expires_in': authResponse.session?.expiresIn ?? 3600,
      };
    } on AuthException catch (e) {
      // Supabase Auth hataları
      switch (e.message) {
        case 'Invalid login credentials':
          throw ApiException('Geçersiz e-posta veya şifre');
        case 'Email not confirmed':
          throw ApiException('E-posta adresinizi doğrulayın');
        case 'Too many requests':
          throw ApiException(
              'Çok fazla deneme yaptınız. Lütfen bekleyip tekrar deneyin.');
        default:
          throw ApiException(e.message);
      }
    } catch (e) {
      // Genel hatalar
      if (e is ApiException) {
        rethrow; // ApiException'ı olduğu gibi fırlat
      }
      throw ApiException('Beklenmeyen bir hata oluştu: ${e.toString()}');
    }
  }

  // ================== GOOGLE SIGN IN ==================
  Future<Map<String, dynamic>> googleLogin({
    required String googleId,
    required String email,
    required String name,
    required String photoUrl,
    required String accessToken,
    required String idToken,
    required String fcmToken,
  }) async {
    try {
      // 1. Supabase Auth ile Google OAuth login
      final AuthResponse authResponse = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (authResponse.user == null) {
        throw ApiException('Google ile giriş başarısız');
      }

      final user = authResponse.user!;

      // 2. user_profiles tablosunda kullanıcı var mı kontrol et
      final existingProfile = await supabase
          .from('user_profiles')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      Map<String, dynamic> profileData;

      if (existingProfile == null) {
        // 3. Yeni kullanıcı - profil oluştur

        final newProfile = {
          'user_id': user.id,
          'name': name,
          'first_name': name.split(' ').first,
          'last_name': name.split(' ').length > 1 ? name.split(' ').last : '',
          'avatar': photoUrl,
          'point': 0,
          'level': 1,
          'fcm_token': fcmToken,
          'provider': 'google',
          'provider_id': googleId,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final insertResponse = await supabase
            .from('user_profiles')
            .insert(newProfile)
            .select()
            .single();

        profileData = insertResponse;
      } else {
        // 4. Mevcut kullanıcı - FCM token güncelle

        final updateData = <String, dynamic>{
          'fcm_token': fcmToken,
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Avatar'ı güncelle (eğer boşsa)
        if ((existingProfile['avatar'] == null ||
                existingProfile['avatar'].isEmpty) &&
            photoUrl.isNotEmpty) {
          updateData['avatar'] = photoUrl;
        }

        await supabase
            .from('user_profiles')
            .update(updateData)
            .eq('user_id', user.id);

        profileData = existingProfile;
        profileData.addAll(updateData); // Güncellenmiş verileri ekle
      }

      // 5. Response formatı
      return {
        'user': {
          'id': profileData['id'],
          'name': profileData['name'],
          'first_name': profileData['first_name'],
          'last_name': profileData['last_name'],
          'email': user.email,
          'phone': profileData['phone'],
          'avatar': profileData['avatar'],
          'point': profileData['point'] ?? 0,
          'level': profileData['level'] ?? 1,
          'city': profileData['city'],
          'birth_year': profileData['birth_year'],
          'team': profileData['team'],
          'created_at': profileData['created_at'],
          'phone_verified': profileData['is_phone_verified'] ?? false,
          'streak_count': 0,
          'daily_rank': 0,
          'weekly_rank': 0,
          'monthly_rank': 0,
          'all_time_rank': 0,
        },
        'access_token': authResponse.session?.accessToken,
        'refresh_token': authResponse.session?.refreshToken,
        'token_type': 'Bearer',
        'expires_in': authResponse.session?.expiresIn ?? 3600,
      };
    } on AuthException catch (e) {
      throw ApiException('Google ile giriş hatası: ${e.message}');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
          'Google ile giriş sırasında hata oluştu: ${e.toString()}');
    }
  }

  // ================== APPLE SIGN IN ==================
  Future<Map<String, dynamic>> appleLogin({
    required String appleId,
    required String email,
    required String name,
    required String identityToken,
    required String authorizationCode,
    required String fcmToken,
  }) async {
    try {
      final AuthResponse authResponse = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: identityToken,
      );

      if (authResponse.user == null) {
        throw ApiException('Apple ile giriş başarısız');
      }

      final user = authResponse.user!;

      // 2. user_profiles tablosunda kullanıcı var mı kontrol et
      final existingProfile = await supabase
          .from('user_profiles')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      Map<String, dynamic> profileData;

      if (existingProfile == null) {
        // 3. Yeni kullanıcı - profil oluştur

        // Apple'dan gelen name boşsa email'den isim çıkar
        String userName = name.isNotEmpty ? name : email.split('@').first;

        final newProfile = {
          'user_id': user.id,
          'name': userName,
          'first_name': userName.split(' ').first,
          'last_name':
              userName.split(' ').length > 1 ? userName.split(' ').last : '',
          'point': 0,
          'level': 1,
          'fcm_token': fcmToken,
          'provider': 'apple',
          'provider_id': appleId,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final insertResponse = await supabase
            .from('user_profiles')
            .insert(newProfile)
            .select()
            .single();

        profileData = insertResponse;
      } else {
        // 4. Mevcut kullanıcı - FCM token güncelle
        final updateData = <String, dynamic>{
          'fcm_token': fcmToken,
          'updated_at': DateTime.now().toIso8601String(),
        };

        await supabase
            .from('user_profiles')
            .update(updateData)
            .eq('user_id', user.id);

        profileData = existingProfile;
        profileData.addAll(updateData);
      }

      // 5. Response formatı
      return {
        'user': {
          'id': profileData['id'],
          'name': profileData['name'],
          'first_name': profileData['first_name'],
          'last_name': profileData['last_name'],
          'email': user.email ?? email,
          'phone': profileData['phone'],
          'avatar': profileData['avatar'],
          'point': profileData['point'] ?? 0,
          'level': profileData['level'] ?? 1,
          'city': profileData['city'],
          'birth_year': profileData['birth_year'],
          'team': profileData['team'],
          'created_at': profileData['created_at'],
          'phone_verified': profileData['is_phone_verified'] ?? false,
          'streak_count': 0,
          'daily_rank': 0,
          'weekly_rank': 0,
          'monthly_rank': 0,
          'all_time_rank': 0,
        },
        'access_token': authResponse.session?.accessToken,
        'refresh_token': authResponse.session?.refreshToken,
        'token_type': 'Bearer',
        'expires_in': authResponse.session?.expiresIn ?? 3600,
      };
    } on AuthException catch (e) {
      throw ApiException('Apple ile giriş hatası: ${e.message}');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
          'Apple ile giriş sırasında hata oluştu: ${e.toString()}');
    }
  }

  // ================== REGISTER ==================
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      // 1. Şifre kontrolü
      if (password != passwordConfirmation) {
        throw ApiException('Şifreler eşleşmiyor');
      }

      // 2. Supabase Auth ile kayıt
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name}, // metadata olarak name gönder
      );

      if (authResponse.user == null) {
        throw ApiException('Kayıt başarısız');
      }

      // 3. user_profiles tablosuna profil bilgilerini ekle
      // (Bu otomatik trigger ile de yapılabilir)
      await supabase.from('user_profiles').insert({
        'user_id': authResponse.user!.id,
        'name': name,
        'first_name': name.split(' ').first,
        'last_name': name.split(' ').length > 1 ? name.split(' ').last : '',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return {
        'user': {
          'id': authResponse.user!.id,
          'name': name,
          'email': email,
        },
        'access_token': authResponse.session?.accessToken,
        'refresh_token': authResponse.session?.refreshToken,
        'message': 'Kayıt başarılı! E-posta doğrulama linkini kontrol edin.',
      };
    } on AuthException catch (e) {
      switch (e.message) {
        case 'User already registered':
          throw ApiException('Bu e-posta adresi zaten kayıtlı');
        case 'Password should be at least 6 characters':
          throw ApiException('Şifre en az 6 karakter olmalıdır');
        default:
          throw ApiException(e.message);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Kayıt sırasında hata oluştu: ${e.toString()}');
    }
  }

  // ================== LOGOUT ==================
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {}
  }

  // ================== UTILITY METHODS ==================
  bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }

  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  // Kullanıcı bilgilerini güncelle
  Future<void> updateUserProfile({
    required String userId,
    Map<String, dynamic>? updates,
  }) async {
    try {
      if (updates != null && updates.isNotEmpty) {
        updates['updated_at'] = DateTime.now().toIso8601String();
        await supabase
            .from('user_profiles')
            .update(updates)
            .eq('user_id', userId);
      }
    } catch (e) {
      throw ApiException('Profil güncelleme hatası: ${e.toString()}');
    }
  }
}
