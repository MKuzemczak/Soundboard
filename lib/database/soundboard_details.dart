class SoundboardDetails {
  int? soundboardId;
  String name;

  SoundboardDetails({this.soundboardId, required this.name});

  SoundboardDetails clone() {
    return SoundboardDetails(soundboardId: soundboardId, name: name);
  }

  Map<String, Object?> toMap() {
    final map = {"name": name};
    if (soundboardId != null) {
      map['soundboardId'] = soundboardId.toString();
    }
    return map;
  }

  factory SoundboardDetails.fromMap(Map<String, dynamic> map) {
    return SoundboardDetails(
      soundboardId: map['soundboardId'],
      name: map['name'],
    );
  }

  @override
  String toString() {
    return 'SoundboardDetails{soundboardId: $soundboardId, name: $name}';
  }
}
