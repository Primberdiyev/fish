
import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'aquarium.dart';

class Shark {
  final SendPort sendPort;
  Timer? _timer;
  final Random random = Random();
  late ReceivePort receivePort;

  Shark(this.sendPort) {
    receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    receivePort.listen(listener);
  }

  void listener(dynamic message) {
    if (message == 'stop') {
      pause();
    } else if (message == 'start') {
      if (_timer?.isActive ?? false) {
        return;
      } else {
        start();
        // i am learning github
      }
    }
  }

  void pause() {
    _timer?.cancel();
  }

  void start() {
    _timer?.cancel();
    final seconds = secundForPopulation();
    _timer = Timer(Duration(seconds: seconds), () {
      sendPort.send("kill");
      start();
    });
  }

  int secundForPopulation() {
    final fishCount = Aquarium().fishMap.length;
    if (fishCount > 30) {
      return random.nextInt(20) + 5;
    } else if (fishCount > 20) {
      return random.nextInt(30) + 5;
    } else {
      return random.nextInt(40) + 5;
    }
  }
}

