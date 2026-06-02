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
  bool _stopHitBeforePlayersStarted = false;

  // True between a `play()` call and the matching `stop()` call. Used by the
  // onPlayerComplete fallback to decide whether to auto-advance to the next
  // sound when a track ends without a crossfade having started (e.g. when the
  // app is in the background and the crossfade window was missed).
  bool _playRequested = false;

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

    // Media-playback audio context. `stayAwake: true` holds a partial wake
    // lock while playing so the CPU does not sleep while the screen is off.
    // `usageType: media` + `contentType: music` mark the stream as media so
    // Android's mediaPlayback foreground service rules apply and the
    // onPositionChanged / onPlayerComplete callbacks keep firing while the
    // app is backgrounded.
    //
    // `audioFocus: none` is kept on purpose - several players in a single
    // SoundContainerPlayer are layered (crossfade + transition cymbal) and
    // requesting focus per-player would make them stomp on each other.
    final mediaContext = AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none,
      ),
    );

    audioPlayerBundle.audioPlayer1.setAudioContext(mediaContext);
    audioPlayerBundle.audioPlayer2.setAudioContext(mediaContext);
    audioPlayerBundle.transitionAudioPlayer.setAudioContext(mediaContext);

    // Drive `onPositionChanged` from a periodic Timer instead of the default
    // `FramePositionUpdater`. FramePositionUpdater piggy-backs on Flutter's
    // frame callbacks, which stop firing as soon as the app is backgrounded
    // and the OS pauses rendering - so position updates (and therefore the
    // crossfade window in `_handlePositionChange`) silently stop, and the
    // next sound never starts. A plain `Timer.periodic` keeps firing while
    // the flutter_background foreground service is alive.
    _useTimerPositionUpdater(audioPlayerBundle.audioPlayer1);
    _useTimerPositionUpdater(audioPlayerBundle.audioPlayer2);
    _useTimerPositionUpdater(audioPlayerBundle.transitionAudioPlayer);

    audioPlayerBundle.transitionAudioPlayer.setVolume(0.25);

    _initPositions();
    _initStreams();
  }

  void _useTimerPositionUpdater(AudioPlayer player) {
    player.positionUpdater = TimerPositionUpdater(
      interval: const Duration(milliseconds: 200),
      getPosition: player.getCurrentPosition,
    );
  }

  bool get isPlaying =>
      _audioPlayer1State == PlayerState.playing ||
      _audioPlayer2State == PlayerState.playing ||
      _transitionAudioPlayerState == PlayerState.playing;

  String? get currentSoundName {
    if (!isPlaying) {
      return null;
    }
    if (_currentPlayer == audioPlayerBundle.audioPlayer1) {
      return _currentAudioPlayer1SoundMapping?.soundDetails.name;
    }
    if (_currentPlayer == audioPlayerBundle.audioPlayer2) {
      return _currentAudioPlayer2SoundMapping?.soundDetails.name;
    }
    return null;
  }

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
    _stopHitBeforePlayersStarted = false;
    _playRequested = true;
    final soundSourceWrapper = await _getNextSource();

    if (isPlaying || soundSourceWrapper == null) {
      return;
    }

    int fadeInDelayMilliseconds = 30;

    if (soundContainerDetails.transitions) {
      fadeInDelayMilliseconds = 15;

      await _playTransition();
    }
    if (_currentPlayer == null) {
      _setCurrentPlayer(audioPlayerBundle.audioPlayer1);
    }

    await _startPlayer(
      _currentPlayer!,
      soundSourceWrapper,
      fadeInDelayMilliseconds,
    );
  }

  void pause() {}

  Future<void> stop() async {
    _playRequested = false;
    if (_currentPlayer != null) {
      await _stopPlayer(_currentPlayer!);
    }
    if (_transitionAudioPlayerState == PlayerState.playing &&
        (_audioPlayer1State != PlayerState.playing ||
            _audioPlayer2State != PlayerState.playing)) {
      _stopHitBeforePlayersStarted = true;
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

  Future<void> _playSource(
    AudioPlayer player,
    SoundSourceWrapper soundSourceWrapper,
  ) async {
    if (player == audioPlayerBundle.audioPlayer1) {
      _currentAudioPlayer1SoundMapping = soundSourceWrapper.soundMappingDetails;
    } else if (player == audioPlayerBundle.audioPlayer2) {
      _currentAudioPlayer2SoundMapping = soundSourceWrapper.soundMappingDetails;
    }
    await player.setSource(soundSourceWrapper.source);
    if (soundSourceWrapper.soundMappingDetails != null) {
      // final soundLength =
      //     soundSourceWrapper.soundMappingDetails!.endSeconds -
      //     soundSourceWrapper.soundMappingDetails!.startSeconds;
      // if (soundLength > 1800) {
      //   final rng = Random();
      //   final randomizedStartSeconds =
      //       rng.nextInt((soundLength / 2).toInt()) +
      //       soundSourceWrapper.soundMappingDetails!.startSeconds;
      //   await player.seek(Duration(seconds: randomizedStartSeconds));
      // } else {
      //   await player.seek(
      //     Duration(
      //       seconds: soundSourceWrapper.soundMappingDetails!.startSeconds,
      //     ),
      //   );
      // }
      await player.seek(
        Duration(seconds: soundSourceWrapper.soundMappingDetails!.startSeconds),
      );
    }
    if (_stopHitBeforePlayersStarted) {
      _stopHitBeforePlayersStarted = false;
      return;
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

  /// Safety net for the case where a track ended naturally without a
  /// crossfade having been started (e.g. the app was backgrounded and the
  /// position-update timer was throttled enough that the 2-second crossfade
  /// window in `_handlePositionChange` was missed). If the user hasn't
  /// stopped the container and no other player picked up playback, we start
  /// the next sound from scratch on the same player slot so the queue keeps
  /// advancing instead of going silent.
  Future<void> _autoAdvanceIfStranded(AudioPlayer completedPlayer) async {
    if (!_playRequested) {
      return;
    }
    if (isPlaying) {
      return;
    }

    final next = await _getNextSource();
    if (next == null) {
      _playRequested = false;
      return;
    }

    _setCurrentPlayer(completedPlayer);
    await _startPlayer(completedPlayer, next, 30);
  }

  Future<SoundSourceWrapper?> _getNextSource() async {
    final soundMappings = await DbHelper().getSoundMappings(
      soundContainerDetails.soundContainerId!,
    );

    if (soundMappings.isNotEmpty) {
      final soundIndex = _getNextSoundIndex(soundMappings.length);
      if (soundIndex != null) {
        return SoundSourceWrapper(
          soundMappingDetails: soundMappings[soundIndex],
          source: DeviceFileSource(soundMappings[soundIndex].soundDetails.path),
        );
      }
    }

    return null;
  }

  int? _getNextSoundIndex(int soundsListSize) {
    int? result;
    if (soundsListSize == 0) {
      return null;
    }
    if (soundContainerDetails.shuffle) {
      final rng = Random();
      result = rng.nextInt(soundsListSize);

      if (soundsListSize > 1) {
        while (result == _currentSoundIndex) {
          result = rng.nextInt(soundsListSize);
        }
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
          await _autoAdvanceIfStranded(audioPlayerBundle.audioPlayer1);
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
          await _autoAdvanceIfStranded(audioPlayerBundle.audioPlayer2);
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
