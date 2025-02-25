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
    ),
    GetPage(
      name: '/waiting-room/:id',
      page: () => const WaitingRoomScreen(),
      binding: BindingsBuilder(() {
        Get.put(WaitingRoomController(roomService: Get.find<RoomService>()));
      }),
    ),
    GetPage(
      name: '/race/:roomId',
      page: () => const RaceScreen(),
      binding: BindingsBuilder(() {
        print('Race route binding başlatılıyor');
        final roomService = Get.find<RoomService>();

        // Binding'de Get.back() kullanmayın
        Get.put<RaceController>(
            RaceController(roomService: roomService),
            permanent: false
        );
      }),
    )
  ];
}