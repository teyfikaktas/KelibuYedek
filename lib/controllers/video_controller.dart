import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class VideoController extends GetxController {
  late VideoPlayerController videoController;
  var isPlaying = false.obs;
  var isInitialized = false.obs;
  var isLoading = true.obs;
  var currentPosition = Duration.zero.obs;
  var duration = Duration.zero.obs;

  @override
  void onInit() {
    super.onInit();
    String videoName = Get.arguments as String;
    initializeVideo(videoName);
  }

  Future<void> initializeVideo(String videoName) async {
    isLoading.value = true;
    try {
      Uri videoUri = Uri.parse('https://cloud.phdakademi.com/uploads/kelibu.net/videos/$videoName.mp4');
      videoController = VideoPlayerController.networkUrl(videoUri);

      await videoController.initialize();
      duration.value = videoController.value.duration;

      // Video pozisyonunu takip et
      videoController.addListener(() {
        currentPosition.value = videoController.value.position;
      });

      await videoController.play();
      isPlaying.value = true;
      isInitialized.value = true;
      isLoading.value = false;
      update();
    } catch (error) {
      print('Video yüklenirken hata: $error');
      isInitialized.value = false;
      isLoading.value = false;
      update();
    }
  }

  void playPause() {
    if (!isInitialized.value || isLoading.value) return;

    if (videoController.value.isPlaying) {
      videoController.pause();
      isPlaying.value = false;
    } else {
      videoController.play();
      isPlaying.value = true;
    }
    update();
  }

  void seekTo(Duration position) {
    videoController.seekTo(position);
  }

  void forward10Seconds() {
    final newPosition = currentPosition.value + Duration(seconds: 10);
    if (newPosition <= duration.value) {
      seekTo(newPosition);
    } else {
      seekTo(duration.value);
    }
  }

  void rewind10Seconds() {
    final newPosition = currentPosition.value - Duration(seconds: 10);
    if (newPosition >= Duration.zero) {
      seekTo(newPosition);
    } else {
      seekTo(Duration.zero);
    }
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void onClose() {
    videoController.dispose();
    super.onClose();
  }
}

// VideoPlayerScreen içindeki _buildVideoPlayer metodu:
