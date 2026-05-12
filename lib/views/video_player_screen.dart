import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../controllers/video_controller.dart';

class VideoPlayerScreen extends StatelessWidget {
  final VideoController controller = Get.put(VideoController());
  final String videoName = Get.arguments as String;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00897B),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF00897B),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    videoName,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      color: Color(0xFF00897B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Kelime Videosu',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF00897B),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Video Yükleniyor...',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Color(0xFF00897B),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return controller.isInitialized.value
                    ? _buildVideoPlayer()
                    : _buildErrorWidget();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return GetBuilder<VideoController>(
      builder: (controller) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(controller.videoController),
                  // Play/Pause butonu
                  Obx(() => IconButton(
                        icon: FaIcon(
                          controller.isPlaying.value
                              ? FontAwesomeIcons.pause
                              : FontAwesomeIcons.play,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: controller.playPause,
                      )),
                  // Kontrol butonları
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          // İlerleme çubuğu
                          Obx(() => SliderTheme(
                                data: SliderThemeData(
                                  thumbColor: Color(0xFF00897B),
                                  activeTrackColor: Color(0xFF00897B),
                                  inactiveTrackColor: Colors.grey[300],
                                ),
                                child: Slider(
                                  value: controller
                                      .currentPosition.value.inSeconds
                                      .toDouble(),
                                  min: 0,
                                  max: controller.duration.value.inSeconds
                                      .toDouble(),
                                  onChanged: (value) {
                                    controller.seekTo(
                                        Duration(seconds: value.toInt()));
                                  },
                                ),
                              )),
                          // Zaman ve kontrol butonları
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Zaman
                              Obx(() => Text(
                                    '${controller.formatDuration(controller.currentPosition.value)} / ${controller.formatDuration(controller.duration.value)}',
                                    style: TextStyle(color: Colors.white),
                                  )),
                              // İleri/Geri butonları
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.replay_10,
                                        color: Colors.white),
                                    onPressed: controller.rewind10Seconds,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.forward_10,
                                        color: Colors.white),
                                    onPressed: controller.forward10Seconds,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.video,
            size: 64,
            color: Color(0xFF00897B).withOpacity(0.3),
          ),
          SizedBox(height: 24),
          Text(
            'Video Henüz Eklenmemiş',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00897B),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'Bu kelimenin videosu en kısa sürede sizlerle olacak.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          TextButton.icon(
            icon: Icon(Icons.arrow_back, color: Color(0xFF00897B)),
            label: Text(
              'Geri Dön',
              style: TextStyle(color: Color(0xFF00897B)),
            ),
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(color: Color(0xFF00897B)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
