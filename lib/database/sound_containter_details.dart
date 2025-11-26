import 'package:flutter/material.dart';

class SoundContainerDetails {
  int? soundContainerId;
  String name;
  bool shuffle;
  bool loop;
  bool transitions;
  bool fadeIn;
  bool fadeOut;
  Color? color;

  SoundContainerDetails({
    this.soundContainerId,
    required this.name,
    required this.shuffle,
    required this.loop,
    required this.transitions,
    required this.fadeIn,
    required this.fadeOut,
    required this.color,
  });

  SoundContainerDetails clone() {
    return SoundContainerDetails(
      soundContainerId: soundContainerId,
      name: name,
      shuffle: shuffle,
      loop: loop,
      transitions: transitions,
      fadeIn: fadeIn,
      fadeOut: fadeOut,
      color: color,
    );
  }

  Map<String, Object?> toMap() {
    final map = {
      "name": name,
      "shuffle": (shuffle ? "1" : "0"),
      "loop": (loop ? "1" : "0"),
      "transitions": (transitions ? "1" : "0"),
      "fadeIn": (fadeIn ? "1" : "0"),
      "fadeOut": (fadeOut ? "1" : "0"),
    };
    if (soundContainerId != null) {
      map["soundContainerId"] = soundContainerId.toString();
    }
    if (color != null) {
      map["color"] = color!.toARGB32().toRadixString(16);
    }
    return map;
  }

  factory SoundContainerDetails.fromMap(Map<String, dynamic> map) {
    return SoundContainerDetails(
      soundContainerId: map["soundContainerId"],
      name: map["name"],
      shuffle: map["shuffle"] == 1,
      loop: map["loop"] == 1,
      transitions: map["transitions"] == 1,
      fadeIn: map["fadeIn"] == 1,
      fadeOut: map["fadeOut"] == 1,
      color: (map["color"] == null ? null : Color(int.parse(map["color"], radix: 16))),
    );
  }

  @override
  String toString() {
    return "SoundContainerDetails{"
        "soundContainerId: $soundContainerId, "
        "name: $name, "
        "shuffle: $shuffle, "
        "loop: $loop, "
        "transitions: $transitions, "
        "fadeIn: $fadeIn, "
        "fadeOut: $fadeOut, "
        "color: $color}";
  }
}
