import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'names.dart';
import 'gender.dart';
import 'fish.dart';
import 'akula.dart';

class Aquarium {
  final Map<String, Isolate> fishMap = {};
  final Map<String, Gender> fishGenders = {};
  final Random random = Random();
  int maleCount = 0;
  int femaleCount = 0;
  final Names names = Names();
  
  Isolate? sharkIsolate;
  ReceivePort? sharkReceivePort;
  SendPort? sharkSendPort;
  bool isstart = true;

  Future<void> start() async {
    stdout.write("Akvariumga nechta baliq tashlamoqchisiz ");
    int n = int.parse(stdin.readLineSync()!);
    
    for (int i = 0; i < n; i++) {
      await addFish();
    }
    aquariumInfo();
    await IsolateShark();
  }

  Future<void> addFish({String? maleParentID, String? femaleParentID}) async {
    final receivePort = ReceivePort();

    final uuid = Uuid();
    final String id = uuid.v4();
    final name = getGender() == Gender.male
        ? names.getMaleName()
        : names.getFemaleName();
    final gender = getGender();
    final lifeSpan = Duration(seconds: random.nextInt(50) + 10);
    final listPopulationTime = List.generate(
      getNumber(fishMap.length),
      (index) => Duration(seconds: random.nextInt(50) + 20),
    );
    if (maleParentID == null || femaleParentID == null) {
      //  maleParentID = '710b962e-041c-11e1-9234-0123456789ab';
      //   femaleParentID = '710b962e-041c-11e1-9234-0123456789ab';
      isstart = false;
    }
    final fish = Fish(
      gender: gender,
      id: id,
      name: name,
      lifeSpan: lifeSpan,
      listPopulationTime: listPopulationTime,
      maleParentID: maleParentID,
      femaleParentID: femaleParentID,
      sendPort: receivePort.sendPort,
    );

    final isolate = await Isolate.spawn(fish.startLife, fish);
    fishMap[id] = isolate;
    fishGenders[id] = gender;

    if (gender == Gender.male) {
      maleCount++;
    } else {
      femaleCount++;
    }
    if (isstart) {
      print(
          "\nYangi baliq dunyoga keldi. Name: $name, Gender: $gender id: $id,\nId of Dad: $maleParentID ,  Id of Mum: $femaleParentID\n");
    } else {
      print(
          "\nYangi baliq dunyoga keldi. Name: $name, Gender: $gender id: $id");
    }
    receivePort.listen((message) {
      if (message == 'end') {
        isolate.kill();
        fishMap.remove(id);
        fishGenders.remove(id);
        if (gender == Gender.male) {
          maleCount--;
        } else {
          femaleCount--;
        }
        print("Baliq nobud bo'ldi. Name: $name Gender: $gender id: $id");
      } else if (message == 'life') {
        findCouple(id);
      }
    });

    if (fishMap.length > 10) {
      sharkSendPort?.send('start');
    }
  }

  int getNumber(int fishesCount) {
    if (fishesCount > 30) {
      return 1;
    } else if (fishesCount > 10 && fishesCount < 20) {
      return 2;
    } else {
      return 3;
    }
  }

  void findCouple(String id) {
    final gender = fishGenders[id]!;
    String? mateId;

    if (gender == Gender.male) {
      final femaleIds = fishGenders.keys
          .where((mateId) => fishGenders[mateId] == Gender.female)
          .toList();
      if (femaleIds.isNotEmpty) {
        mateId = femaleIds[random.nextInt(femaleIds.length)];
      }
    } else {
      final maleIds = fishGenders.keys
          .where((mateId) => fishGenders[mateId] == Gender.male)
          .toList();
      if (maleIds.isNotEmpty) {
        mateId = maleIds[random.nextInt(maleIds.length)];
      }
    }

    if (mateId != null) {
      addFish(
        maleParentID: gender == Gender.male ? id : mateId,
        femaleParentID: gender == Gender.female ? id : mateId,
      );
      isstart = true;
    } else {
      print("UShbu baliq juft topa olmadi");
    }
  }

  void aquariumInfo() {
    print(
        "Akvariumda ${fishMap.length} ta baliq bor. Male: $maleCount Female: $femaleCount");
    if (fishMap.isEmpty) {
      print("Akvariumda baliq qolmadi");
    }
    if (sharkIsolate != null) {
      sharkIsolate!.kill(priority: Isolate.immediate);
      sharkReceivePort?.close();
      print("Akula to'xtadi");
    }
    Timer.periodic(Duration(seconds: 10), (timer) {
      print(
          "Akvariumda ${fishMap.length} ta baliq bor. Male: $maleCount Female: $femaleCount");
    });
  }

  Future<void> IsolateShark() async {
    sharkReceivePort = ReceivePort();
    sharkIsolate = await Isolate.spawn(createShark, sharkReceivePort!.sendPort);
    sharkReceivePort?.listen((message) {
      if (message is SendPort) {
        sharkSendPort = message;
      } else if (message == 'kill') {
        huntFish();
      }
    });
  }

  static void createShark(SendPort sendPort) {
    final sharkSendPort = ReceivePort();
    sendPort.send(sharkSendPort.sendPort); // Send Shark's SendPort to Aquarium
    Shark(sendPort);
  }

  void killFishIsolate(String id) {
    final isolate = fishMap[id];
    final fishGender = fishGenders[id];

    if (isolate != null) {
      isolate.kill(priority: Isolate.immediate);
      fishMap.remove(id);
      fishGenders.remove(id);

      if (fishGender == Gender.male) {
        maleCount--;
      } else {
        femaleCount--;
      }

      print('Akula baliqni yedi $id, Gender: $fishGender\n');
    }
  }

  void huntFish() async {
    if (fishMap.length > 10) {
      final fishId = fishMap.keys.elementAt(random.nextInt(fishMap.length));
      killFishIsolate(fishId);
    } else {
      sharkSendPort?.send('stop');
    }
  }
}
