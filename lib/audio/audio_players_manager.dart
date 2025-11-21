import 'package:audioplayers/audioplayers.dart';
import 'package:sounboard/audio/audio_player_bundle.dart';
import 'package:sounboard/audio/sound_container_player.dart';
import 'package:sounboard/database/sound_containter_details.dart';

class AudioPlayersManager {
  static final AudioPlayersManager _singleton = AudioPlayersManager._internal(
    {},
  );
  final Map<int, SoundContainerPlayer>
  _soundContainerIdToSoundContainerPlayer;

  factory AudioPlayersManager() {
    return _singleton;
  }

  AudioPlayersManager._internal(this._soundContainerIdToSoundContainerPlayer);

  void rebuildAudioPlayersMap(List<SoundContainerDetails> soundContainers) {
    _soundContainerIdToSoundContainerPlayer.removeWhere((
      soundContainerId,
      soundContainerPlayer,
    ) {
      final shouldRemove = !soundContainers.any(
        (element) => element.soundContainerId == soundContainerId,
      );
      if (shouldRemove) {
        soundContainerPlayer.stop();
      }
      return shouldRemove;
    });

    for (var soundContainerDetails in soundContainers) {
      if (_soundContainerIdToSoundContainerPlayer.keys.contains(
        soundContainerDetails.soundContainerId!,
      )) {
        _soundContainerIdToSoundContainerPlayer[soundContainerDetails.soundContainerId!]?.soundContainerDetails = soundContainerDetails;
        continue;
      }

      _soundContainerIdToSoundContainerPlayer[soundContainerDetails
          .soundContainerId!] = SoundContainerPlayer(
        soundContainerDetails: soundContainerDetails,
        audioPlayerBundle: AudioPlayerBundle(
          audioPlayer1: AudioPlayer(),
          audioPlayer2: AudioPlayer(),
          transitionAudioPlayer: AudioPlayer(),
        ),
      );
    }
  }

  SoundContainerPlayer getSoundContainerPlayerForSoundConainer(int soundContainerId) {
    return _soundContainerIdToSoundContainerPlayer[soundContainerId]!;
  }

  void stopAudioPlayersOtherThan(int soundContainerId) {
    _soundContainerIdToSoundContainerPlayer.forEach((id, soundContainerPlayer) {
      if (soundContainerId != id) {
        soundContainerPlayer.stop();
      }
    });
  }
}
