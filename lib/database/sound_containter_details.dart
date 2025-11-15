class SoundContainerDetails {
  int? soundContainerId;
  String name;
  bool shuffle;
  bool loop;

  SoundContainerDetails({
    this.soundContainerId,
    required this.name,
    required this.shuffle,
    required this.loop,
  });

  SoundContainerDetails clone() {
    return SoundContainerDetails(
      soundContainerId: soundContainerId,
      name: name,
      shuffle: shuffle,
      loop: loop,
    );
  }

  Map<String, Object?> toMap() {
    final map = {
      "name": name,
      "shuffle": (shuffle ? "1" : "0"),
      "loop": (loop ? "1" : "0"),
    };
    if (soundContainerId != null) {
      map["soundContainerId"] = soundContainerId.toString();
    }
    return map;
  }

  factory SoundContainerDetails.fromMap(Map<String, dynamic> map) {
    return SoundContainerDetails(
      soundContainerId: map["soundContainerId"],
      name: map["name"],
      shuffle: map["shuffle"] == 1,
      loop: map["loop"] == 1,
    );
  }

  @override
  String toString() {
    return "SoundContainerDetails{soundContainerId: $soundContainerId, name: $name, shuffle: $shuffle, loop: $loop}";
  }
}
