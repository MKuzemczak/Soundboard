class SoundDetails {
  int? soundId;
  String name;
  String path;

  SoundDetails({
    this.soundId,
    required this.name,
    required this.path,
  });

  SoundDetails clone() {
    return SoundDetails(
      soundId: soundId,
      name: name,
      path: path,
    );
  }

  Map<String, Object?> toMap() {
    final map = {"name": name, "path": path};
    if (soundId != null) {
      map['soundId'] = soundId.toString();
    }
    return map;
  }

  factory SoundDetails.fromMap(Map<String, dynamic> map) {
    return SoundDetails(
      soundId: map['soundId'],
      name: map['name'],
      path: map['path'],
    );
  }

  @override
  String toString() {
    return 'SoundDetails{soundId: $soundId, name: $name, path: $path}';
  }
}
