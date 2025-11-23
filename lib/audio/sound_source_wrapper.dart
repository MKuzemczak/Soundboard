import 'package:audioplayers/audioplayers.dart';
import 'package:sounboard/database/sound_mapping_details.dart';

class SoundSourceWrapper {
  final SoundMappingDetails? soundMappingDetails;
  final Source source;

  SoundSourceWrapper({required this.soundMappingDetails, required this.source});
}