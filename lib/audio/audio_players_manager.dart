import 'package:audioplayers/audioplayers.dart';
import 'package:sounboard/database/sound_containter_details.dart';

class AudioPlayersManager {
  static final AudioPlayersManager _singleton = AudioPlayersManager._internal({});
  final Map<int, AudioPlayer> _soundContainerIdToAudioPlayer;
  
  factory AudioPlayersManager() {
    return _singleton;
  }
  
  AudioPlayersManager._internal(this._soundContainerIdToAudioPlayer);

  void rebuildAudioPlayersMap(List<SoundContainerDetails> soundContainers) {
    _soundContainerIdToAudioPlayer.removeWhere((soundContainerId, audioPlayer) { 
      final shouldRemove = !soundContainers.any((element) => element.soundContainerId == soundContainerId);
      if (shouldRemove) {
        audioPlayer.stop();
      }
      return shouldRemove;
    });
    
    for (var soundContainerDetails in soundContainers) {
      if (_soundContainerIdToAudioPlayer.keys.contains(soundContainerDetails.soundContainerId!)) {
        continue;
      }

      _soundContainerIdToAudioPlayer[soundContainerDetails.soundContainerId!] = AudioPlayer();
    }
  }

  AudioPlayer getAudioPlayerForSoundConainer(int soundContainerId) {
    return _soundContainerIdToAudioPlayer[soundContainerId]!;
  }
}