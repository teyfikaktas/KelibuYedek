import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kelibu/screens/race/waiting_room/waiting_room_controller.dart';

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.find<WaitingRoomController>(); // Bindings'deki controller'ı al
    print('Screen using roomId: ${controller.roomId.value}'); // Debug log
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF242424),
        title: const Text('Bekleme Odası'),
        elevation: 0,
      ),
      body: Obx(() => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildRoomInfo(controller),
                _buildPlayersList(controller),
                Obx(() => controller.isHost.value
                    ? _buildStartButton(controller)
                    : const SizedBox()),
              ],
            )),
    );
  }

  Widget _buildRoomInfo(WaitingRoomController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Oda ID: ',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              SelectableText(
                controller.roomId.value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Oyun başlamadan önce tüm oyuncuların katılmasını bekleyin.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

// WaitingRoomScreen içindeki _buildPlayersList metodunu güncelleyin

  Widget _buildPlayersList(WaitingRoomController controller) {
    print(
        'Current players for roomId ${controller.roomId.value}: ${controller.players}');

    // Sadece is_connected=true olan oyuncuları filtrele
    final connectedPlayers =
        controller.players.where((player) => player.isConnected).toList();

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: connectedPlayers.length,
        itemBuilder: (context, index) {
          final player = connectedPlayers[index];
          final isCurrentUser =
              player.userId == controller.roomService.getCurrentUserId();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: player.isReady ? Colors.green : Colors.grey[850]!,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      player.avatarLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Oyuncu bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            player.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isCurrentUser)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Sen',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (player.isHost)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Oda Sahibi',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Hazır/Bekliyor butonu
                GestureDetector(
                  onTap: isCurrentUser ? controller.toggleReady : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: player.isReady
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                      border: isCurrentUser
                          ? Border.all(
                              color: player.isReady
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.grey[700]!,
                              width: 1,
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (player.isReady)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 14,
                            ),
                          ),
                        Text(
                          player.isReady ? 'Hazır' : 'Bekliyor',
                          style: TextStyle(
                            color: player.isReady
                                ? Colors.green
                                : Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStartButton(WaitingRoomController controller) {
    String? tooltipMessage;
    if (!controller.isHost.value) {
      tooltipMessage = 'Sadece oda sahibi oyunu başlatabilir';
    } else if (controller.players.length < 2) {
      tooltipMessage = 'Oyun başlatmak için en az 2 oyuncu gerekli';
    } else if (!controller.players.every((player) => player.isReady)) {
      tooltipMessage = 'Tüm oyuncular hazır olmalı';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        border: Border(
          top: BorderSide(color: Colors.grey[850]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Tooltip(
              message: tooltipMessage ?? 'Oyunu başlat',
              child: ElevatedButton(
                onPressed:
                    controller.canStartGame ? controller.startGame : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.play_circle_filled_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Oyunu Başlat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
