import 'dart:isolate';
import 'dart:async';
import 'gender.dart';

class Fish {
  final String id;
  final Gender gender;
  final String name;
  final Duration lifeSpan;
  final SendPort sendPort;
  final String? maleParentID;
  final String? femaleParentID;
  final List<Duration>? listPopulationTime;

  Fish({
    required this.name,
    required this.id,
    required this.gender,
    required this.lifeSpan,
    required this.sendPort,
    this.femaleParentID,
    this.maleParentID,
    this.listPopulationTime,
  });

  void startLife(Fish fish) async {
    for (final period in listPopulationTime ?? []) {
      await Future.delayed(period, () {
        sendPort.send('life');
      });
      await Future.delayed(lifeSpan, () {
        sendPort.send('end');
      });
    }
  }
}
