import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flash Card Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FlashCardScreen(),
    );
  }
}

class FlashCardScreen extends StatefulWidget {
  const FlashCardScreen({super.key});

  @override
  _FlashCardScreenState createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen> {
  bool _isFlipped = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flash Card Demo'),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () => setState(() {
            _isFlipped = !_isFlipped;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            width: 300,
            // Genişlik arttırıldı
            height: 400,
            // Yükseklik arttırıldı
            decoration: BoxDecoration(
              color: _isFlipped ? Colors.orange : Colors.yellow,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  spreadRadius: 5,
                  blurRadius: 10,
                ),
              ],
            ),
            transform: Matrix4.rotationY(_isFlipped ? 3.14159 : 0),
            transformAlignment: Alignment.center,
            child: Center(
              child: _isFlipped
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(3.14159),
                      child: const Text(
                        'ELMA',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'APPLE',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Noun',
                          style: TextStyle(
                              fontSize: 18, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
