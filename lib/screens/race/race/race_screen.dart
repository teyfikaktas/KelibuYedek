import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kelibu/screens/race/race/race_controller.dart';

class RaceScreen extends StatelessWidget {
  const RaceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Controller'ı kontrol et
    if (!Get.isRegistered<RaceController>()) {
      // Widget ağacını oluştururken direkt navigasyon yapmak yerine,
      // buildden sonraki frame'de yapalım
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offNamed('/race'); // Ana sayfaya yönlendirme
      });

      // Yüklenme göstergesi döndürelim
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Controller var, şimdi güvenle kullanabiliriz
    final controller = Get.find<RaceController>();
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
          child: GetBuilder<RaceController>(
            init: controller,
            builder: (controller) {
              // Soruların yüklenmesini bekleyen bir loading göster
              if (controller.isWaitingForPlayers.value ||
                  controller.questions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Oyun Yükleniyor...',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  _buildScoreBoard(controller),

                  // Tek oyuncu kaldığında zamanlayıcı göster
                  Obx(() {
                    return controller.isLastPlayerTimerActive.value
                        ? Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.amber.withOpacity(0.5)),
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
                          )
                        : const SizedBox.shrink();
                  }),

                  const Spacer(),
                  _buildQuestion(controller),
                  const SizedBox(height: 20),
                  _buildOptions(controller),
                  const Spacer(),
                ],
              );
            },
          ),
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
              await controller
                  .leaveGame(); // Oyundan çık ve controller içinde ana sayfaya yönlendir
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
          final isConnected =
              controller.playerConnectionStatus[playerId] ?? true;
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

// RaceScreen içindeki _buildScoreBoard metoduna şu değişikliği ekleyin
  Widget _buildScoreBoard(RaceController controller) {
    // Skorboard verilerini kontrol et ve logla
    controller.playerScores.forEach((playerId, score) {
      print(
          'Oyuncu: $playerId, Skor: ${score.score}, Soru: ${score.currentQuestionIndex}');
    });

    // Eğer skorboard boşsa yükleniyor göster
    if (controller.playerScores.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[850]!),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Normal skorboard gösterimi - Obx ile sarmalanarak anlık güncellemeleri algıla
    return Obx(() {
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
                  // İsim gösterimi - Obx içine aldık, artık FutureBuilder gerekmeyebilir
                  FutureBuilder<String>(
                    future: controller.getPlayerName(playerId),
                    builder: (context, snapshot) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            snapshot.data ?? 'Oyuncu',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          // Bağlantı durumu göstergesi
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  controller.playerConnectionStatus[playerId] ??
                                          true
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  // Skor değerleri - Bu kısmı highlight edelim ki güncellendiğinde dikkat çeksin
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      '${score.score}',
                      key: ValueKey<int>(score.score),
                      // Değer değiştiğinde animasyon için key
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
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
    });
  }

  Widget _buildQuestion(RaceController controller) {
    // Soru ve seçenekleri göstermeden önce kontrol
    if (controller.questions.isEmpty) {
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
              'Sorular Yükleniyor...',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      );
    }

    // Soru listesi dolu, şimdi de indeksi kontrol et
    if (controller.currentQuestionIndex.value >= controller.questions.length) {
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
              'Sorular Tamamlandı',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bütün soruları yanıtladınız!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Artık güvenle soruyu gösterebiliriz
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
    // Sorular yüklenmemişse veya tamamlanmışsa boş bir container göster
    if (controller.questions.isEmpty ||
        controller.currentQuestionIndex.value >= controller.questions.length) {
      return Container();
    }

    final currentQuestion = controller.getCurrentQuestion();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: currentQuestion.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;

          // Default buton stili
          Color buttonColor = const Color(0xFF242424);
          Color textColor = Colors.white;
          IconData? leadingIcon;

          // Cevap gösteriliyorken buton renklerini ve ikonları belirle
          if (controller.showAnswer.value) {
            final bool isCorrectOption =
                index == currentQuestion.correctOptionIndex;
            final bool isSelectedOption =
                index == controller.selectedAnswer.value;

            if (isCorrectOption && isSelectedOption) {
              // Doğru cevap ve kullanıcı bunu seçti
              buttonColor = Colors.green;
              textColor = Colors.white;
              leadingIcon = Icons.check_circle;
            } else if (isCorrectOption) {
              // Doğru cevap ama kullanıcı bunu seçmedi
              buttonColor = Colors.green.withOpacity(0.7);
              textColor = Colors.white;
              leadingIcon = Icons.check_circle_outline;
            } else if (isSelectedOption) {
              // Yanlış cevap ve kullanıcı bunu seçti
              buttonColor = Colors.red;
              textColor = Colors.white;
              leadingIcon = Icons.cancel;
            } else {
              // Yanlış cevap ve kullanıcı bunu seçmedi
              buttonColor = const Color(0xFF242424);
              textColor = Colors.white.withOpacity(0.5);
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.showAnswer.value
                  ? null
                  : () => controller.submitAnswer(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                // Disable'da bile renkleri korumak için
                disabledBackgroundColor: buttonColor,
                disabledForegroundColor: textColor,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(leadingIcon, color: textColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    option,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
