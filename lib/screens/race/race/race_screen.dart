import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:kelibu/screens/race/race/race_controller.dart';

class RaceScreen extends StatelessWidget {
  const RaceScreen({Key? key}) : super(key: key);

  @override
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
    return WillPopScope(
      onWillPop: () async {
        // Geri tuşuna basıldığında çıkış diyaloğunu göster
        _showExitDialog(context, controller);
        return false; // Sistemin geri tuşunu engelle
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white,
            ),
            onPressed: () => _showExitDialog(context, controller),
          ),
          // Oyun durumunu gösteren etiket
          title: Obx(() => controller.isLastPlayerTimerActive.value
              ? Text(
            'Tek Oyuncu: ${controller.lastPlayerTimeLeft.value}s',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 16,
            ),
          )
              : const SizedBox.shrink()),
        ),
        body: SafeArea(
          child: Obx(() {
            return Column(
              children: [
                _buildScoreBoard(controller),

                // Tek oyuncu kaldığında zamanlayıcı göster
                if (controller.isLastPlayerTimerActive.value)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Odada tek kaldınız!',
                          style: TextStyle(
                            color: Colors.amber[300],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${controller.lastPlayerTimeLeft.value} saniye içinde başka oyuncu katılmazsa kazanan olarak ilan edileceksiniz.',
                          style: TextStyle(
                            color: Colors.amber[200],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                const Spacer(),
                _buildQuestion(controller),
                const SizedBox(height: 20),
                _buildOptions(controller),
                const Spacer(),
              ],
            );
          }),
        ),
      ),
    );
  }
  void _showExitDialog(BuildContext context, RaceController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF242424),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Oyundan Çık',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Oyundan çıkmak istediğinize emin misiniz?\nİlerlemeniz kaydedilecektir.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Dialog'u kapat
              await controller.leaveGame(); // Oyundan çık ve controller içinde ana sayfaya yönlendir
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Çık'),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
  Widget _buildLastPlayerTimer(RaceController controller) {
    return Obx(() {
      if (!controller.isLastPlayerTimerActive.value) {
        return const SizedBox.shrink(); // Aktif değilse görünmez
      }

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              'Diğer oyuncu bekleniyor: ${controller.lastPlayerTimeLeft.value}s',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    });
  }
  void _showVictoryMessage(RaceController controller) {
    if (controller.showVictoryMessage.value) {
      // Bu metod doğrudan kullanılmayacak, çünkü dialog controller içinden gösteriliyor
      // Sadece referans için burada
      Get.dialog(
        AlertDialog(
          backgroundColor: const Color(0xFF242424),
          title: const Text(
            'Tebrikler!',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Diğer oyuncular ayrıldı. Kazanan olarak ilan edildiniz!',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                Get.offNamed('/race-results/${controller.roomId.value}');
              },
              child: const Text(
                'Tamam',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    }
  }
  Widget _buildPlayerConnectionStatus(RaceController controller, int playerId) {
    return FutureBuilder<bool>(
      future: controller.isPlayerConnected(playerId),
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected ? Colors.green : Colors.red,
          ),
        );
      },
    );
  }

// Skor tablosunda oyuncu isminin yanına bağlantı durumu eklemek için
// _buildScoreBoard metodunda isim kısmını şöyle değiştirebilirsiniz:
  Widget _buildPlayerName(RaceController controller, int playerId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
        Obx(() {
          final isConnected = controller.playerConnectionStatus[playerId] ?? true;
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.red,
            ),
          );
        }),
      ],
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