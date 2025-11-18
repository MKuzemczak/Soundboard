import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sounboard/audio/audio_player_bundle.dart';
import 'package:sounboard/database/db.dart';
import 'package:sounboard/database/sound_containter_details.dart';

class SoundContainerButton extends StatefulWidget {
  final SoundContainerDetails soundContainerDetails;
  final AudioPlayerBundle audioPlayerBundle;
  final VoidCallback onLongPress;
  final VoidCallback onStartedPlaying;

  const SoundContainerButton({
    super.key,
    required this.soundContainerDetails,
    required this.audioPlayerBundle,
    required this.onLongPress,
    required this.onStartedPlaying,
  });

  @override
  State<StatefulWidget> createState() => _SoundContainerButtonState();
}

class _SoundContainerButtonState extends State<SoundContainerButton> {
  PlayerState? _playerState;
  Duration? _position;
  AudioPlayer transitionAudioPlayer = AudioPlayer();

  bool get _isPlaying => _playerState == PlayerState.playing;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  @override
  void initState() {
    super.initState();
    _playerState = widget.audioPlayerBundle.audioPlayer1.state;
    widget.audioPlayerBundle.audioPlayer1.getCurrentPosition().then(
      (value) => setState(() {
        _position = value;
      }),
    );
    _initStreams();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    // Subscriptions only can be closed asynchronously,
    // therefore events can occur after widget has been disposed.
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(
          _isPlaying ? Color.fromRGBO(255, 0, 0, 1) : Color.fromRGBO(0, 0, 0, 1),
        ),
      ),
      onLongPress: () => widget.onLongPress(),
      onPressed: () async {
        if (_isPlaying) {
          widget.audioPlayerBundle.audioPlayer1.stop();
        } else {
          final sounds = await DbHelper().getSounds(soundContainerId: widget.soundContainerDetails.soundContainerId!);
          if (sounds.isEmpty) {
            return;
          }
          widget.audioPlayerBundle.audioPlayer1.play(DeviceFileSource(sounds[0].path));
          widget.onStartedPlaying();
        }
      },
      child: Text(widget.soundContainerDetails.name),
    );
  }

  void _initStreams() {
    _positionSubscription = widget.audioPlayerBundle.audioPlayer1.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = widget.audioPlayerBundle.audioPlayer1.onPlayerComplete.listen((event) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    });

    _playerStateChangeSubscription = widget.audioPlayerBundle.audioPlayer1.onPlayerStateChanged.listen((
      state,
    ) {
      setState(() {
        _playerState = state;
      });
    });
  }
}
