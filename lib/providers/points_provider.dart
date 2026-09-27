import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class PointsNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> setPoint(int newPoint) async {
    state = newPoint;
    var box = await Hive.openBox('userBox');
    await box.put('point', newPoint);
  }

  Future<void> addPoints(int points) async {
    state += points;
    var box = await Hive.openBox('userBox');
    await box.put('point', state);
  }

  Future<void> loadPoint() async {
    var box = await Hive.openBox('userBox');
    state = box.get('point') is int ? box.get('point') : 0;
  }
}

final pointsProvider = NotifierProvider<PointsNotifier, int>(
  PointsNotifier.new,
);