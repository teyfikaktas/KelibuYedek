import 'package:http/http.dart' as http;

class NetworkService {
  static Future<bool> isConnected() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}