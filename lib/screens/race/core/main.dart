// main_race_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:kelibu/screens/race/core/services/RoomService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/user_provider.dart';
import '../models/room.dart';

class MainRaceController extends GetxController {
  final RoomService roomService;
  final selectedIndex = 0.obs;
  final isLoading = false.obs;
  final isJoiningRoom = false.obs;

  // Dialog için kontrolcüler
  final selectedCategory = ''.obs;
  final selectedDuration = 60.obs;
  final isJokerEnabled = true.obs;
  final generatedRoomCode = ''.obs;
  final joinRoomCode = ''.obs;

  MainRaceController() : roomService = RoomService(Supabase.instance.client,  Get.find<UserProvider>(),
  );

  final List<Map<String, dynamic>> categories = [
    {
      'id': 'GK001',
      'name': 'Genel Kültür',
      'icon': FontAwesomeIcons.graduationCap,
      'color': const Color(0xFF1E88E5),
      'description': 'Genel kültür soruları',
    },
    {
      'id': 'SP001',
      'name': 'Spor',
      'icon': FontAwesomeIcons.footballBall,
      'color': const Color(0xFF4CAF50),
      'description': 'Spor dünyasından sorular',
    },
    {
      'id': 'TR001',
      'name': 'Tarih',
      'icon': FontAwesomeIcons.landmark,
      'color': const Color(0xFFFF9800),
      'description': 'Tarih soruları',
    },
    {
      'id': 'BL001',
      'name': 'Bilim',
      'icon': FontAwesomeIcons.flask,
      'color': const Color(0xFF9C27B0),
      'description': 'Bilim ve teknoloji soruları',
    },
    {
      'id': 'SN001',
      'name': 'Sanat',
      'icon': FontAwesomeIcons.paintBrush,
      'color': const Color(0xFFF44336),
      'description': 'Sanat ve kültür soruları',
    },
  ];

  Future<void> createRoom() async {
    try {
      if (selectedCategory.value.isEmpty) {
        Get.snackbar(
          'Hata',
          'Lütfen bir kategori seçin',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        return;
      }

      final userId = roomService.getCurrentUserId();
      if (userId == null) {
        Get.snackbar(
          'Hata',
          'Kullanıcı girişi yapılmamış',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
        return;
      }

      isLoading.value = true;
      final room = await roomService.createRoom(
        roomCode: generatedRoomCode.value,
        userId: userId,
        playerCount: 4,
      );
      print('Navigating to waiting room with roomId: ${room.id}');

      Get.back(); // Dialog'u kapat
      Get.toNamed('/waiting-room/${room.id}'); // room.id ile yönlendirme (örneğin, /waiting-room/33)
    } catch (e) {
      print('Oda oluşturma hatası: $e'); // Konsola yazdır
      Get.snackbar(
        'Hata',
        'Oda oluşturulurken bir hata oluştu',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> joinRoom() async {
    if (joinRoomCode.value.isEmpty) {
      Get.snackbar(
        'Hata',
        'Lütfen oda kodunu veya ID’sini girin',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    try {
      isJoiningRoom.value = true;
      Room? room;

      print('Joining room with input: ${joinRoomCode.value}');
      final isNumeric = int.tryParse(joinRoomCode.value) != null;
      print('Input is numeric: $isNumeric');
      if (isNumeric) {
        // Oda ID’si ile arat ve oyuncuyu odaya ekle
        final roomId = int.parse(joinRoomCode.value);
        print('Attempting to join room by ID: $roomId');
        room = await roomService.getRoomById(roomId);
        print('Calling joinRoomById with roomId: $roomId');
        await roomService.joinRoomById(roomId);  // Oyuncuyu odaya ekle
      } else {
        // Oda Kodu ile arat ve oyuncuyu odaya ekle
        print('Attempting to join room by code: ${joinRoomCode.value}');
        room = await roomService.getRoomByCode(joinRoomCode.value);
        print('Calling joinRoom with roomCode: ${joinRoomCode.value}');
        await roomService.joinRoom(joinRoomCode.value);  // Oyuncuyu odaya ekle
      }

      if (room != null) {
        print('Successfully found room with ID: ${room.id}');
        Get.back(); // Dialog'u kapat
        Get.toNamed('/waiting-room/${room.id}'); // room.id ile yönlendirme
      } else {
        Get.snackbar(
          'Hata',
          'Oda bulunamadı',
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
        );
      }
    } catch (e) {
      print('Odaya girilirken hata: $e');
      Get.snackbar(
        'Hata',
        'Odaya girilirken bir hata oluştu: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isJoiningRoom.value = false;
    }
  }
  void showCreateRoomDialog() {
    generatedRoomCode.value = 'RACE${DateTime.now().millisecondsSinceEpoch}';
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: Get.width * 0.9,
          decoration: BoxDecoration(
            color: const Color(0xFF242424),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey[850]!,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader('Oda Oluştur', FontAwesomeIcons.plusCircle),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRoomCodeSection(),
                    const SizedBox(height: 20),
                    _buildCategorySection(),
                    const SizedBox(height: 20),
                    _buildSettingsSection(),
                  ],
                ),
              ),
              _buildDialogActions(
                onConfirm: createRoom,
                confirmText: 'Oluştur',
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void showJoinRoomDialog() {
    joinRoomCode.value = '';
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: Get.width * 0.9,
          decoration: BoxDecoration(
            color: const Color(0xFF242424),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey[850]!,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader('Odaya Katıl', FontAwesomeIcons.doorOpen),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Oda Kodu',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[800]!,
                        ),
                      ),
                      child: TextField(
                        onChanged: (value) => joinRoomCode.value = value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Oda kodunu girin',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildDialogActions(
                onConfirm: joinRoom,
                confirmText: 'Katıl',
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // Dialog helper widgets...
  Widget _buildDialogHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          FaIcon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[100],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Get.back(),
            icon: const FaIcon(
              FontAwesomeIcons.xmark,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Oda Kodu',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[800]!,
            ),
          ),
          child: Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.hashtag,
                color: Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 8),
              Obx(() => Text(
                generatedRoomCode.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              )),
              const Spacer(),
              IconButton(
                onPressed: () {
                  generatedRoomCode.value = 'RACE${DateTime.now().millisecondsSinceEpoch}';
                },
                icon: const FaIcon(
                  FontAwesomeIcons.arrowsRotate,
                  color: Colors.grey,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Obx(() => GestureDetector(
                onTap: () => selectedCategory.value = category['id'],
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: selectedCategory.value == category['id']
                        ? category['color'].withOpacity(0.2)
                        : Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedCategory.value == category['id']
                          ? category['color']
                          : Colors.grey[800]!,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        category['icon'],
                        color: selectedCategory.value == category['id']
                            ? category['color']
                            : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name'],
                        style: TextStyle(
                          color: selectedCategory.value == category['id']
                              ? Colors.white
                              : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Süre (Saniye)',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[800]!,
                  ),
                ),
                child: Obx(() => DropdownButton<int>(
                  value: selectedDuration.value,
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  icon: const FaIcon(
                    FontAwesomeIcons.chevronDown,
                    color: Colors.grey,
                    size: 16,
                  ),
                  underline: const SizedBox(),
                  items: [30, 45, 60, 90, 120]
                      .map((duration) => DropdownMenuItem(
                    value: duration,
                    child: Text('$duration saniye'),
                  ))
                      .toList(),
                  onChanged: (value) => selectedDuration.value = value!,
                )),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Joker Hakkı',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[800]!,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => isJokerEnabled.toggle(),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            isJokerEnabled.value
                                ? FontAwesomeIcons.toggleOn
                                : FontAwesomeIcons.toggleOff,
                            color: isJokerEnabled.value
                                ? Colors.green
                                : Colors.grey,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }
  // Önceki kodun devamı...

  Widget _buildDialogActions(
      {required VoidCallback onConfirm, required String confirmText}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Get.back(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'İptal',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextButton(
              onPressed: onConfirm,
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                confirmText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }
}

// SCREEN
class MainRaceScreen extends GetView<MainRaceController> {
  MainRaceScreen({Key? key}) : super(key: key) {
    Get.put(MainRaceController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          _buildBalance(),
          Expanded(
            child: _buildFeatureGrid(),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      title: Row(
        children: [
          Image.asset(
            'assets/logo.png',
            height: 32,
          ),
          const SizedBox(width: 8),
        ],
      ),
      actions: [
        IconButton(
          icon: Stack(
            children: [
              const FaIcon(FontAwesomeIcons.bell, color: Colors.white, size: 22),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: const Text(
                    '19',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Kelibu ',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: '🏎️ Yarış',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalance() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[850]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.trophy,
                    color: Colors.grey,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Puanınız',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.solidStar,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '1250',
                    style: TextStyle(
                      color: Colors.grey[200],
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    children: const [
                      FaIcon(
                        FontAwesomeIcons.plus,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Puan Kazan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      {
        'title': 'Oda Kur',
        'icon': FontAwesomeIcons.plus,
        'color': const Color(0xFF1E88E5),
        'onTap': () => controller.showCreateRoomDialog(),
        'isComingSoon': false,
      },
      {
        'title': 'Odaya Katıl',
        'icon': FontAwesomeIcons.doorOpen,
        'color': const Color(0xFF4CAF50),
        'onTap': () => controller.showJoinRoomDialog(),
        'isComingSoon': false,
      },
      {
        'title': 'Hızlı Eşleştir',
        'icon': FontAwesomeIcons.bolt,
        'color': const Color(0xFFFF9800),
        'isComingSoon': true,
      },
      {
        'title': 'Arkadaşınla Oyna',
        'icon': FontAwesomeIcons.userGroup,
        'color': const Color(0xFF9C27B0),
        'isComingSoon': true,
      },
      {
        'title': 'Grup Yarışması',
        'icon': FontAwesomeIcons.users,
        'color': const Color(0xFF009688),
        'isComingSoon': true,
      },
      {
        'title': 'Market',
        'icon': FontAwesomeIcons.shop,
        'color': const Color(0xFFF44336),
        'isComingSoon': true,
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: features.map((feature) => _buildFeatureCard(
        feature['title'] as String,
        feature['icon'] as IconData,
        feature['color'] as Color,
        onTap: feature['onTap'] as Function()?,
        isComingSoon: feature['isComingSoon'] as bool,
      )).toList(),
    );
  }

  Widget _buildFeatureCard(
      String title,
      IconData icon,
      Color color, {
        VoidCallback? onTap,
        bool isComingSoon = false,
      }) {
    return Obx(() => Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.isLoading.value ? null : (isComingSoon ? null : onTap),
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FaIcon(
                        icon,
                        size: 28,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (controller.isLoading.value && title == 'Oda Kur')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                ],
              ),
              if (isComingSoon)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[850]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.clock,
                          size: 10,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Yakında',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': FontAwesomeIcons.house, 'label': 'Anasayfa'},
      {'icon': FontAwesomeIcons.trophy, 'label': 'Sıralama'},
      {'icon': FontAwesomeIcons.user, 'label': 'Profil'},
      {'icon': FontAwesomeIcons.gear, 'label': 'Ayarlar'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        border: Border(
          top: BorderSide(
            color: Colors.grey[900]!,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Obx(
            () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildBottomNavItem(
              item['icon'] as IconData,
              item['label'] as String,
              index,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = controller.selectedIndex.value == index;
    return InkWell(
        onTap: () => controller.changeTab(index),
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
    color: isSelected ? Colors.green.withOpacity(0.1) : Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    FaIcon(
    icon,
    size: 20,
    color: isSelected ? Colors.green : Colors.grey[600],
    ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.green : Colors.grey[600],
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ],
    ),
        ),
    );
  }
}