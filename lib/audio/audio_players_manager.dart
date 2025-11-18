import 'package:audioplayers/audioplayers.dart';
import 'package:sounboard/audio/audio_player_bundle.dart';
import 'package:sounboard/database/sound_containter_details.dart';

class AudioPlayersManager {
  static final AudioPlayersManager _singleton = AudioPlayersManager._internal({});
  final Map<int, AudioPlayerBundle> _soundContainerIdToAudioPlayer;
  
  factory AudioPlayersManager() {
    return _singleton;
  }
  
  AudioPlayersManager._internal(this._soundContainerIdToAudioPlayer);

  void rebuildAudioPlayersMap(List<SoundContainerDetails> soundContainers) {
    _soundContainerIdToAudioPlayer.removeWhere((soundContainerId, audioPlayerBundle) { 
      final shouldRemove = !soundContainers.any((element) => element.soundContainerId == soundContainerId);
      if (shouldRemove) {
        audioPlayerBundle.stopAllPlayers();
      }
      return shouldRemove;
    });
    
    for (var soundContainerDetails in soundContainers) {
      if (_soundContainerIdToAudioPlayer.keys.contains(soundContainerDetails.soundContainerId!)) {
        continue;
      }

      _soundContainerIdToAudioPlayer[soundContainerDetails.soundContainerId!] = AudioPlayerBundle(
        audioPlayer1: AudioPlayer(),
        audioPlayer2: AudioPlayer(),
        transitionAudioPlayer: AudioPlayer(),
      );
    }
  }

  AudioPlayerBundle getAudioPlayerBundleForSoundConainer(int soundContainerId) {
    return _soundContainerIdToAudioPlayer[soundContainerId]!;
  }
}