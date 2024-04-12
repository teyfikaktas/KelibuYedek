import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

class WebViewPage extends StatefulWidget {
  @override
  WebViewPageState createState() => WebViewPageState();
}

class WebViewPageState extends State<WebViewPage> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final cookieManager = WebviewCookieManager();
    cookieManager.clearCookies();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (url=='https://www.kelibu.net/home') {

              Navigator.pop(context);

            }
            else{
              print(url);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.kelibu.net/register'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFAF6), // Arka plan rengini burada ayarlayın

      appBar: AppBar(
        title: const Text('Kayıt Ol'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
