import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

class DeviceService {
  final FlutterSecureStorage storage = FlutterSecureStorage();

  // Rastgele string oluşturmak için yardımcı metod
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random.secure();
    return String.fromCharCodes(
        Iterable.generate(
            length,
                (_) => chars.codeUnitAt(rnd.nextInt(chars.length))
        )
    );
  }

  Future<String> getDeviceId() async {
    String? deviceId = await storage.read(key: 'device_id');
    if (deviceId != null) {
      return deviceId;
    }

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String newDeviceId;

    if (defaultTargetPlatform == TargetPlatform.android) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      newDeviceId = androidInfo.id+androidInfo.model; // Benzersiz cihaz ID'si
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      newDeviceId = (iosInfo.identifierForVendor! + iosInfo.model)! ?? _generateRandomString(10); // Benzersiz cihaz ID'si
    } else {
      newDeviceId = _generateRandomString(10); // Diğer platformlar için
    }

    await storage.write(key: 'device_id', value: newDeviceId);
    return newDeviceId;
  }
}
