import 'package:audioplayers/audioplayers.dart';

class AudioPlayerBundle {
  final AudioPlayer audioPlayer1;
  final AudioPlayer audioPlayer2;
  final AudioPlayer transitionAudioPlayer;

  AudioPlayerBundle({required this.audioPlayer1, required this.audioPlayer2, required this.transitionAudioPlayer});

  void stopAllPlayers() {
    audioPlayer1.stop();
    audioPlayer2.stop();
    transitionAudioPlayer.stop();
  }
}