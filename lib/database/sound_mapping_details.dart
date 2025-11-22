import 'package:sounboard/database/sound_details.dart';

class SoundMappingDetails {
  final SoundDetails soundDetails;
  final int startSeconds;
  final int endSeconds;

  SoundMappingDetails({required this.soundDetails, required this.startSeconds, required this.endSeconds});
}