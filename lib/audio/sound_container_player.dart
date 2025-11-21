import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sounboard/audio/audio_player_bundle.dart';
import 'package:sounboard/database/db.dart';
import 'package:sounboard/database/sound_containter_details.dart';

class SoundContainerPlayer {
  SoundContainerDetails soundContainerDetails;

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
  }) : this.soundContainerDetails = soundContainerDetails,
       _audioPlayer1State = audioPlayerBundle.audioPlayer1.state,
       _audioPlayer2State = audioPlayerBundle.audioPlayer2.state,
       _transitionAudioPlayerState =
           audioPlayerBundle.transitionAudioPlayer.state {
    audioPlayerBundle.audioPlayer1.setReleaseMode(ReleaseMode.stop);
    audioPlayerBundle.audioPlayer2.setReleaseMode(ReleaseMode.stop);
    audioPlayerBundle.transitionAudioPlayer.setReleaseMode(ReleaseMode.stop);

    audioPlayerBundle.audioPlayer1.setAudioContext(AudioContext(android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none)));
    audioPlayerBundle.audioPlayer2.setAudioContext(AudioContext(android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none)));
    audioPlayerBundle.transitionAudioPlayer.setAudioContext(AudioContext(android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none)));

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
    
    final sounds = await DbHelper().getSounds(soundContainerId: soundContainerDetails.soundContainerId!);
    Source? source;
    if (sounds.isEmpty) {
      source = AssetSource("sound/mia.mp3");
    }
    else {
      source = DeviceFileSource(sounds[0].path);
    }

    int fadeInDelayMilliseconds = 30;

    if (soundContainerDetails.transitions) {
      fadeInDelayMilliseconds = 15;

      final rng = Random();
      final crashId = rng.nextInt(4) + 1;
      await audioPlayerBundle.transitionAudioPlayer.play(AssetSource("sound/cymbal_roll_$crashId.mp3"));
      await audioPlayerBundle.transitionAudioPlayer.setVolume(0.25);
      final crashDuration = await audioPlayerBundle.transitionAudioPlayer.getDuration();
      if (crashDuration != null)
      {
        await Future.delayed(Duration(seconds: (crashDuration.inSeconds / 2).toInt()));
      }
    }

    if (soundContainerDetails.fadeIn) {
      await audioPlayerBundle.audioPlayer1.setVolume(0);
      audioPlayerBundle.audioPlayer1.play(source);
      for (double v = 0; v < 1; v = v + 0.01) {
        await audioPlayerBundle.audioPlayer1.setVolume(v);
        await Future.delayed(Duration(milliseconds: fadeInDelayMilliseconds));
      }
      await audioPlayerBundle.audioPlayer1.setVolume(1);
    }
    else {
      await audioPlayerBundle.audioPlayer1.setVolume(1);
      audioPlayerBundle.audioPlayer1.play(source);
    }
  }

  void pause() {}

  Future<void> stop() async {
    if (soundContainerDetails.fadeOut && isPlaying) {
      for (double v = 1; v > 0; v = v - 0.01) {
        await audioPlayerBundle.audioPlayer1.setVolume(v);
        await Future.delayed(Duration(milliseconds: 20));
      }
    }
    await audioPlayerBundle.audioPlayer1.setVolume(0);
    await audioPlayerBundle.audioPlayer1.stop();
    await audioPlayerBundle.audioPlayer2.stop();
    await audioPlayerBundle.transitionAudioPlayer.stop();
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
