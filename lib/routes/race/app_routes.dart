import 'package:get/get.dart';
import '../../screens/race/core/main.dart';
import '../../screens/race/core/services/RoomService.dart';
import '../../screens/race/race/race_controller.dart';
import '../../screens/race/race/race_screen.dart';
import '../../screens/race/waiting_room/waiting_room_controller.dart';
import '../../screens/race/waiting_room/waiting_room_screen.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: '/race',
      page: () => MainRaceScreen(),
      binding: BindingsBuilder(() {
        // Ana race sayfasına geçerken temizlikler yapılır
        if (Get.isRegistered<RaceController>()) {
          print('Ana race sayfasına geçiş: RaceController siliniyor');
          Get.delete<RaceController>();
        }

        if (Get.isRegistered<WaitingRoomController>()) {
          print('Ana race sayfasına geçiş: WaitingRoomController siliniyor');
          Get.delete<WaitingRoomController>();
        }
      }),
    ),
    GetPage(
      name: '/waiting-room/:id',
      page: () => const WaitingRoomScreen(),
      binding: BindingsBuilder(() {
        // Önce eski WaitingRoomController varsa temizle
        if (Get.isRegistered<WaitingRoomController>()) {
          print('Eski WaitingRoomController siliniyor');
          Get.delete<WaitingRoomController>();
        }

        // Eğer RaceController varsa ve başka bir odadan geçiş yapıyorsak,
        // RaceController'ı da temizle
        if (Get.isRegistered<RaceController>()) {
          print('Race sayfasından waiting room''a geçiş: RaceController siliniyor');
          Get.delete<RaceController>();
        }

        // Yeni controller'ı ekle
        print('Yeni WaitingRoomController oluşturuluyor');
        Get.put(
            WaitingRoomController(roomService: Get.find<RoomService>()),
            permanent: false
        );
      }),
    ),
    GetPage(
      name: '/race/:roomId',
      page: () => const RaceScreen(),
      binding: BindingsBuilder(() {
        print('Race route binding başlatılıyor');
        final roomService = Get.find<RoomService>();

        // Önce eski RaceController varsa temizle
        if (Get.isRegistered<RaceController>()) {
          print('Eski RaceController siliniyor');
          Get.delete<RaceController>();
        }

        // Eğer waiting room'dan geçiş yapıyorsak WaitingRoomController'ı da temizle
        if (Get.isRegistered<WaitingRoomController>()) {
          print('Waiting room sayfasından race''e geçiş: WaitingRoomController siliniyor');
          Get.delete<WaitingRoomController>();
        }

        // Yeni controller'ı oluştur
        print('Yeni RaceController oluşturuluyor');
        Get.put<RaceController>(
            RaceController(roomService: roomService),
            permanent: false
        );
      }),
    ),
    // Race sonuçları sayfasını da ekleyin
  ];
}