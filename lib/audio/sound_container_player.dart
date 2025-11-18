import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sounboard/audio/audio_player_bundle.dart';
import 'package:sounboard/database/db.dart';
import 'package:sounboard/database/sound_containter_details.dart';

class SoundContainerPlayer {
  final SoundContainerDetails _soundContainerDetails;

  PlayerState? _audioPlayer1State;
  StreamSubscription? _audioPlayer1StateChangeSubscription;
  Duration? _audioPlayer1Position;
  StreamSubscription? _audioPlayer1PositionSubscription;
  StreamSubscription? _audioPlayer1CompleteSubscription;

  PlayerState? _audioPlayer2State;
  StreamSubscription? _audioPlayer2StateChangeSubscription;
  Duration? _audioPlayer2Position;
  StreamSubscription? _audioPlayer2PositionSubscription;
  StreamSubscription? _audioPlayer2CompleteSubscription;

  PlayerState? _transitionAudioPlayerState;
  StreamSubscription? _transitionAudioPlayerStateChangeSubscription;
  Duration? _transitionAudioPlayerPosition;
  StreamSubscription? _transitionAudioPlayerPositionSubscription;
  StreamSubscription? _transitionAudioPlayerCompleteSubscription;

  final AudioPlayerBundle audioPlayerBundle;
  VoidCallback? onStateChanged;

  SoundContainerPlayer({
    required SoundContainerDetails soundContainerDetails,
    required this.audioPlayerBundle,
  }) : _soundContainerDetails = soundContainerDetails,
       _audioPlayer1State = audioPlayerBundle.audioPlayer1.state,
       _audioPlayer2State = audioPlayerBundle.audioPlayer2.state,
       _transitionAudioPlayerState =
           audioPlayerBundle.transitionAudioPlayer.state {
    _initPositions();
    _initStreams();
  }

  bool get isPlaying =>
      _audioPlayer1State == PlayerState.playing ||
      _audioPlayer2State == PlayerState.playing ||
      _transitionAudioPlayerState == PlayerState.playing;

  Future<void> play() async {
    if (isPlaying) {
      return;
    }
    
    final sounds = await DbHelper().getSounds(soundContainerId: _soundContainerDetails.soundContainerId!);
    if (sounds.isEmpty) {
      return;
    }
    audioPlayerBundle.audioPlayer1.play(DeviceFileSource(sounds[0].path));
  }

  void pause() {}

  void stop() {
    audioPlayerBundle.audioPlayer1.stop();
  }

  void setOnStateChanged(VoidCallback cb) {
    onStateChanged = cb;
  }

  void _initPositions() {
    audioPlayerBundle.audioPlayer1.getCurrentPosition().then((value) {
      _audioPlayer1Position = value;
    });
  }

  void _initStreams() {
    _audioPlayer1PositionSubscription = audioPlayerBundle
        .audioPlayer1
        .onPositionChanged
        .listen((p) {
          _audioPlayer1Position = p;
          onStateChanged?.call();
        });

    _audioPlayer1CompleteSubscription = audioPlayerBundle
        .audioPlayer1
        .onPlayerComplete
        .listen((event) {
          _audioPlayer1State = PlayerState.stopped;
          _audioPlayer1Position = Duration.zero;
          onStateChanged?.call();
        });

    _audioPlayer1StateChangeSubscription = audioPlayerBundle
        .audioPlayer1
        .onPlayerStateChanged
        .listen((state) {
          _audioPlayer1State = state;
          onStateChanged?.call();
        });

    
    _audioPlayer2PositionSubscription = audioPlayerBundle
        .audioPlayer2
        .onPositionChanged
        .listen((p) {
          _audioPlayer2Position = p;
          onStateChanged?.call();
        });

    _audioPlayer2CompleteSubscription = audioPlayerBundle
        .audioPlayer2
        .onPlayerComplete
        .listen((event) {
          _audioPlayer2State = PlayerState.stopped;
          _audioPlayer2Position = Duration.zero;
          onStateChanged?.call();
        });

    _audioPlayer2StateChangeSubscription = audioPlayerBundle
        .audioPlayer2
        .onPlayerStateChanged
        .listen((state) {
          _audioPlayer2State = state;
          onStateChanged?.call();
        });

    
    _transitionAudioPlayerPositionSubscription = audioPlayerBundle
        .transitionAudioPlayer
        .onPositionChanged
        .listen((p) {
          _transitionAudioPlayerPosition = p;
          onStateChanged?.call();
        });

    _transitionAudioPlayerCompleteSubscription = audioPlayerBundle
        .transitionAudioPlayer
        .onPlayerComplete
        .listen((event) {
          _transitionAudioPlayerState = PlayerState.stopped;
          _transitionAudioPlayerPosition = Duration.zero;
          onStateChanged?.call();
        });

    _transitionAudioPlayerStateChangeSubscription = audioPlayerBundle
        .transitionAudioPlayer
        .onPlayerStateChanged
        .listen((state) {
          _transitionAudioPlayerState = state;
          onStateChanged?.call();
        });
  }
}
