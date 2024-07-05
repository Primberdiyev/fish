import 'dart:math';

enum Gender {
  male,
  female,
}

Gender getGender() => Random().nextBool() ? Gender.male : Gender.female;
