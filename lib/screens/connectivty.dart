import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static Future<bool> isConnected() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    try {
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}