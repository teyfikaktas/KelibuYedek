import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:kelibu/screens/race/race/race_controller.dart';

class RaceScreen extends StatelessWidget {
  const RaceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('RaceScreen building...');

    // Controller'ı en başta bul ve null değilse devam et
    late final RaceController controller;
    try {
      controller = Get.find<RaceController>();
      print('RaceController found with roomId: ${controller.roomId.value}');
    } catch (e) {
      print('Error finding RaceController: $e');
      // Hata durumunda geri dön
      Future.microtask(() => Get.back());
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Controller artık null olmayacak şekilde kullanılabilir
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Get.dialog(
              AlertDialog(
                backgroundColor: const Color(0xFF242424),
                title: const Text(
                  'Oyundan Çık',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  'Oyundan çıkmak istediğinize emin misiniz?',
                  style: TextStyle(color: Colors.grey),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      'İptal',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Get.back(); // Dialog'u kapat
                      await controller.leaveGame(); // Oyundan çık
                    },
                    child: const Text(
                      'Çık',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          // Oyuncular bekleniyor

          // Oyun başladı
          return Column(
            children: [
              _buildScoreBoard(controller),
              const Spacer(),
              _buildQuestion(controller),
              const SizedBox(height: 20),
              _buildOptions(controller),
              const Spacer(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildWaitingScreen(RaceController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Oyuncular Bekleniyor',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 20),
          Obx(() => Text(
            '${controller.connectedPlayers.length}/${controller.playerScores.length} oyuncu hazır',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildScoreBoard(RaceController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Row(
        children: controller.playerScores.entries.map((entry) {
          final playerId = entry.key;
          final score = entry.value;

          return Expanded(
            child: Column(
              children: [
                FutureBuilder<String>(
                  future: controller.getPlayerName(playerId),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Oyuncu',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  score.score.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${score.currentQuestionIndex + 1}/10',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuestion(RaceController controller) {
    final currentQuestion = controller.getCurrentQuestion();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Column(
        children: [
          Text(
            'Soru ${controller.currentQuestionIndex.value + 1}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            currentQuestion.englishWord,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(RaceController controller) {
    final currentQuestion = controller.getCurrentQuestion();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: currentQuestion.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;

          // Cevap gösteriliyorken butonun rengini belirle
          Color? buttonColor = const Color(0xFF242424);
          if (controller.showAnswer.value) {
            if (index == currentQuestion.correctOptionIndex) {
              buttonColor = Colors.green;
            } else if (index == controller.selectedAnswer.value) {
              buttonColor = Colors.red;
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.showAnswer.value ? null : () => controller.submitAnswer(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                option,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }}