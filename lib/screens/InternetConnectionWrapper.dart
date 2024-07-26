import 'package:flutter/material.dart';
import 'NetWorkService.dart';
import 'noInternetPage.dart';

class InternetConnectionWrapper extends StatefulWidget {
  final Widget child;

  const InternetConnectionWrapper({Key? key, required this.child}) : super(key: key);

  @override
  _InternetConnectionWrapperState createState() => _InternetConnectionWrapperState();
}

class _InternetConnectionWrapperState extends State<InternetConnectionWrapper> {
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    while (true) {
      final isConnected = await NetworkService.isConnected();
      if (isConnected != _isConnected) {
        setState(() {
          _isConnected = isConnected;
        });
      }
      await Future.delayed(Duration(seconds: 5)); // Her 5 saniyede bir kontrol et
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isConnected ? widget.child : NoInternetPage();
  }
}