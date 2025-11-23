import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sounboard/audio/audio_player_bundle.dart';
import 'package:sounboard/audio/sound_source_wrapper.dart';
import 'package:sounboard/database/db.dart';
import 'package:sounboard/database/sound_containter_details.dart';
import 'package:sounboard/database/sound_mapping_details.dart';

class SoundContainerPlayer {
  SoundContainerDetails soundContainerDetails;

  PlayerState? _audioPlayer1State;
  // ignore: unused_field
  StreamSubscription? _audioPlayer1StateChangeSubscription;
  Duration? _audioPlayer1Position;
  // ignore: unused_field
  StreamSubscription? _audioPlayer1PositionSubscription;
  // ignore: unused_field
  StreamSubscription? _audioPlayer1CompleteSubscription;
  SoundMappingDetails? _currentAudioPlayer1SoundMapping;

  PlayerState? _audioPlayer2State;
  // ignore: unused_field
  StreamSubscription? _audioPlayer2StateChangeSubscription;
  Duration? _audioPlayer2Position;
  // ignore: unused_field
  StreamSubscription? _audioPlayer2PositionSubscription;
  // ignore: unused_field
  StreamSubscription? _audioPlayer2CompleteSubscription;
  SoundMappingDetails? _currentAudioPlayer2SoundMapping;

  PlayerState? _transitionAudioPlayerState;
  // ignore: unused_field
  StreamSubscription? _transitionAudioPlayerStateChangeSubscription;
  // ignore: unused_field
  Duration? _transitionAudioPlayerPosition;
  // ignore: unused_field
  StreamSubscription? _transitionAudioPlayerPositionSubscription;
  // ignore: unused_field
  StreamSubscription? _transitionAudioPlayerCompleteSubscription;

  final AudioPlayerBundle audioPlayerBundle;
  VoidCallback? onStateChanged;

  AudioPlayer? _currentPlayer;

  int? _currentSoundIndex;

  final int _startOfSwitchInMilliseconds = 2000;
  // ignore: unused_field
  final int _numberOfSwitchSteps = 6;
  final _stepsToPlayNextSound = List.generate(6, (i) => 2000 - (i * 400));
  bool _nextPlayerStarted = false;

  SoundContainerPlayer({
    required this.soundContainerDetails,
    required this.audioPlayerBundle,
  }) : _audioPlayer1State = audioPlayerBundle.audioPlayer1.state,
       _audioPlayer2State = audioPlayerBundle.audioPlayer2.state,
       _transitionAudioPlayerState =
           audioPlayerBundle.transitionAudioPlayer.state {
    audioPlayerBundle.audioPlayer1.setReleaseMode(ReleaseMode.stop);
    audioPlayerBundle.audioPlayer2.setReleaseMode(ReleaseMode.stop);
    audioPlayerBundle.transitionAudioPlayer.setReleaseMode(ReleaseMode.stop);

    audioPlayerBundle.audioPlayer1.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      ),
    );
    audioPlayerBundle.audioPlayer2.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      ),
    );
    audioPlayerBundle.transitionAudioPlayer.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      ),
    );

    audioPlayerBundle.transitionAudioPlayer.setVolume(0.25);

    _initPositions();
    _initStreams();
  }

  bool get isPlaying =>
      _audioPlayer1State == PlayerState.playing ||
      _audioPlayer2State == PlayerState.playing ||
      _transitionAudioPlayerState == PlayerState.playing;

  Duration? get _currentPlayerPosition {
    if (_currentPlayer == audioPlayerBundle.audioPlayer1) {
      return _audioPlayer1Position;
    }
    if (_currentPlayer == audioPlayerBundle.audioPlayer2) {
      return _audioPlayer2Position;
    }
    return null;
  }

  Future<void> play() async {
    if (isPlaying) {
      return;
    }

    int fadeInDelayMilliseconds = 30;

    if (soundContainerDetails.transitions) {
      fadeInDelayMilliseconds = 15;

      await _playTransition();
    }
    final soundSourceWrapper = await _getNextSource();
    if (soundSourceWrapper != null) {
      if (_currentPlayer == null) {
        _setCurrentPlayer(audioPlayerBundle.audioPlayer1);
      }

      await _startPlayer(_currentPlayer!, soundSourceWrapper, fadeInDelayMilliseconds);
    }
  }

  void pause() {}

  Future<void> stop() async {
    if (_currentPlayer != null) {
      await _stopPlayer(_currentPlayer!);
    }
    await audioPlayerBundle.audioPlayer1.stop();
    await audioPlayerBundle.audioPlayer2.stop();
    await audioPlayerBundle.transitionAudioPlayer.stop();
  }

  void setOnStateChanged(VoidCallback cb) {
    onStateChanged = cb;
  }

  void _setCurrentPlayer(AudioPlayer player) {
    _currentPlayer = player;
  }

  Future<void> _stopPlayer(AudioPlayer player) async {
    if (soundContainerDetails.fadeOut) {
      for (double v = 1; v > 0; v = v - 0.01) {
        await player.setVolume(v);
        await Future.delayed(Duration(milliseconds: 20));
      }
    }
    await player.setVolume(0);
    await player.stop();
  }

  Future<void> _playSource(AudioPlayer player, SoundSourceWrapper soundSourceWrapper) async {
    if (player == audioPlayerBundle.audioPlayer1) {
      _currentAudioPlayer1SoundMapping = soundSourceWrapper.soundMappingDetails;
    }
    else if (player == audioPlayerBundle.audioPlayer2) {
      _currentAudioPlayer2SoundMapping = soundSourceWrapper.soundMappingDetails;
    }
    await player.setSource(soundSourceWrapper.source);
    if (soundSourceWrapper.soundMappingDetails != null) {
      await player.seek(Duration(seconds: soundSourceWrapper.soundMappingDetails!.startSeconds));
    }
    await player.resume();
  }

  Future<void> _startPlayer(
    AudioPlayer player,
    SoundSourceWrapper soundSourceWrapper,
    int fadeInDelayMilliseconds,
  ) async {
    if (soundContainerDetails.fadeIn) {
      await player.setVolume(0);
      _playSource(player, soundSourceWrapper);
      for (double v = 0; v < 1; v = v + 0.01) {
        await player.setVolume(v);
        await Future.delayed(Duration(milliseconds: fadeInDelayMilliseconds));
      }
      await player.setVolume(1);
    } else {
      await player.setVolume(1);
      _playSource(player, soundSourceWrapper);
    }
  }

  Future<void> _playTransition() async {
    final rng = Random();
    final crashId = rng.nextInt(4) + 1;
    await audioPlayerBundle.transitionAudioPlayer.play(
      AssetSource("sound/cymbal_roll_$crashId.mp3"),
    );
    final crashDuration = await audioPlayerBundle.transitionAudioPlayer
        .getDuration();
    if (crashDuration != null) {
      await Future.delayed(
        Duration(seconds: (crashDuration.inSeconds / 2).toInt()),
      );
    }
  }

  Future<SoundSourceWrapper?> _getNextSource() async {
    final soundMappings = await DbHelper().getSoundMappings(
      soundContainerDetails.soundContainerId!,
    );

    if (soundMappings.isEmpty) {
      return SoundSourceWrapper(
        soundMappingDetails: null,
        source: AssetSource("sound/mia.mp3"),
      );
    }

    final soundIndex = _getNextSoundIndex(soundMappings.length);
    if (soundIndex != null) {
      return SoundSourceWrapper(
        soundMappingDetails: soundMappings[soundIndex],
        source: DeviceFileSource(soundMappings[soundIndex].soundDetails.path),
      );
    }
    return null;
  }

  int? _getNextSoundIndex(int soundsListSize) {
    int? result;
    if (soundContainerDetails.shuffle) {
      final rng = Random();
      result = rng.nextInt(soundsListSize);
      while (result == _currentSoundIndex) {
        result = rng.nextInt(soundsListSize);
      }
    } else {
      if (_currentSoundIndex == soundsListSize - 1) {
        if (soundContainerDetails.loop) {
          result = 0;
        } else {
          result = null;
        }
      } else if (_currentSoundIndex == null) {
        result = 0;
      } else {
        result = _currentSoundIndex! + 1;
      }
    }
    _currentSoundIndex = result;
    return result;
  }

  AudioPlayer _getNextPlayer() {
    if (_currentPlayer == audioPlayerBundle.audioPlayer1) {
      return audioPlayerBundle.audioPlayer2;
    }
    return audioPlayerBundle.audioPlayer1;
  }

  Future<int?> _getPlayerEndSeconds(AudioPlayer audioPlayer) async {
    if (audioPlayer == audioPlayerBundle.audioPlayer1) {
      return _currentAudioPlayer1SoundMapping?.endSeconds;
    }
    if (audioPlayer == audioPlayerBundle.audioPlayer2) {
      return _currentAudioPlayer2SoundMapping?.endSeconds;
    }
    return (await audioPlayer.getDuration())?.inSeconds;
  }

  Future<void> _handlePositionChange() async {
    if (_currentPlayer == null || _currentPlayerPosition == null) {
      return;
    }

    final currentPlayerEndSeconds = await _getPlayerEndSeconds(_currentPlayer!);
    if (currentPlayerEndSeconds == null) {
      return;
    }

    final nextPlayer = _getNextPlayer();
    final millisecondsUntilEnd =
        (currentPlayerEndSeconds * 1000) -
        _currentPlayerPosition!.inMilliseconds;
    if (millisecondsUntilEnd > _startOfSwitchInMilliseconds) {
      return;
    }

    for (var i = 0; i < _stepsToPlayNextSound.length - 1; i++) {
      if (millisecondsUntilEnd < _stepsToPlayNextSound[i] &&
          millisecondsUntilEnd >= _stepsToPlayNextSound[i + 1]) {
        if (nextPlayer.state != PlayerState.playing && !_nextPlayerStarted) {
          _nextPlayerStarted = true;
          final soundSourceWrapper = await _getNextSource();

          if (soundSourceWrapper != null) {
            await _playSource(nextPlayer, soundSourceWrapper);
          }
        }

        if (i == (_stepsToPlayNextSound.length - 2)) {
          _currentPlayer!.setVolume(0);
          await _currentPlayer!.stop();
          nextPlayer.setVolume(1);
          _setCurrentPlayer(nextPlayer);
          _nextPlayerStarted = false;
        } else {
          _currentPlayer!.setVolume(
            1.0 - (i.toDouble() / (_stepsToPlayNextSound.length - 1)),
          );
          nextPlayer.setVolume(
            i.toDouble() / (_stepsToPlayNextSound.length - 1),
          );
        }
        break;
      }
    }
  }

  void _initPositions() {
    audioPlayerBundle.audioPlayer1.getCurrentPosition().then((value) {
      _audioPlayer1Position = value;
    });
    audioPlayerBundle.audioPlayer2.getCurrentPosition().then((value) {
      _audioPlayer2Position = value;
    });
    audioPlayerBundle.transitionAudioPlayer.getCurrentPosition().then((value) {
      _transitionAudioPlayerPosition = value;
    });
  }

  void _initStreams() {
    _audioPlayer1PositionSubscription = audioPlayerBundle
        .audioPlayer1
        .onPositionChanged
        .listen((p) {
          _audioPlayer1Position = p;
          _handlePositionChange();
        });

    _audioPlayer1CompleteSubscription = audioPlayerBundle
        .audioPlayer1
        .onPlayerComplete
        .listen((event) async {
          _audioPlayer1State = PlayerState.stopped;
          _audioPlayer1Position = Duration.zero;
          await _handlePositionChange();
          _nextPlayerStarted = false;
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
          _handlePositionChange();
        });

    _audioPlayer2CompleteSubscription = audioPlayerBundle
        .audioPlayer2
        .onPlayerComplete
        .listen((event) async {
          _audioPlayer2State = PlayerState.stopped;
          _audioPlayer2Position = Duration.zero;
          await _handlePositionChange();
          _nextPlayerStarted = false;
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
          _handlePositionChange();
        });

    _transitionAudioPlayerCompleteSubscription = audioPlayerBundle
        .transitionAudioPlayer
        .onPlayerComplete
        .listen((event) async {
          _transitionAudioPlayerState = PlayerState.stopped;
          _transitionAudioPlayerPosition = Duration.zero;
          await _handlePositionChange();
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
