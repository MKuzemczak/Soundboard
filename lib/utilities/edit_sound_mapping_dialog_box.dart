import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sounboard/database/db.dart';
import 'package:sounboard/database/sound_mapping_details.dart';

class EditSoundMappingDialogBox extends StatefulWidget {
  final int _soundContainerId;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final AudioPlayer audioPlayer;
  final SoundMappingDetails soundMappingDetails;

  const EditSoundMappingDialogBox({
    super.key,
    required int soundContainerId,
    required this.onCancel,
    required this.onSave,
    required this.audioPlayer,
    required this.soundMappingDetails,
  }) : _soundContainerId = soundContainerId;

  @override
  State<StatefulWidget> createState() => _EditSoundMappingDialogBoxState(
    startSeconds: soundMappingDetails.startSeconds,
    endSeconds: soundMappingDetails.endSeconds,
  );
}

class _EditSoundMappingDialogBoxState extends State<EditSoundMappingDialogBox> {
  PlayerState _audioPlayerState;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  Duration? _position;
  Duration? _duration;

  final TextEditingController _startSecondsController;
  final TextEditingController _endSecondsController;

  String get _durationText => _duration?.toString().split('.').first ?? '';

  String get _positionText => _position?.toString().split('.').first ?? '';

  _EditSoundMappingDialogBoxState({required int startSeconds, required int endSeconds})
    : _startSecondsController = TextEditingController(
        text: startSeconds.toString(),
      ),
      _endSecondsController = TextEditingController(
        text: endSeconds.toString(),
      ),
      _audioPlayerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    widget.audioPlayer.setSource(
      DeviceFileSource(widget.soundMappingDetails.soundDetails.path),
    );
    _initStreams();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.7,
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  IconButton(
                    onPressed: _getOnPlayerPressedCallback(),
                    icon: Icon(
                      _audioPlayerState == PlayerState.playing
                          ? Icons.stop
                          : Icons.play_arrow,
                    ),
                  ),
                  Text(
                    _position != null
                        ? '$_positionText / $_durationText'
                        : _duration != null
                        ? _durationText
                        : '',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(widget.soundMappingDetails.soundDetails.name),
                  ),
                  Row(
                    children: [
                      Text("Start (s)"),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _startSecondsController,
                            minLines: 1,
                            maxLines: 1,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Start seconds',
                            ),
                            onChanged: (value) async {
                              if (value == "") {
                                return;
                              }
                              final int intVal = int.parse(value);
                              await widget.audioPlayer.seek(
                                Duration(seconds: intVal),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text("End (s)"),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _endSecondsController,
                            minLines: 1,
                            maxLines: 1,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'End seconds',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: _cancel,
                          child: Text("Cancel"),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: _save,
                          child: Text("Save"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _getSeconds(String text) {
    return text == "" ? 0 : int.parse(text);
  }

  Future<void> _cancel() async {
    await widget.audioPlayer.stop();
    widget.onCancel();
  }

  Future<void> _save() async {
    await widget.audioPlayer.stop();

    final dbHelper = DbHelper();
    await dbHelper.updateSoundContainerToSoundMapping(
      widget._soundContainerId,
      SoundMappingDetails(
        soundDetails: widget.soundMappingDetails.soundDetails,
        startSeconds: _getSeconds(_startSecondsController.text),
        endSeconds: _getSeconds(_endSecondsController.text),
      ),
    );
    widget.onSave();
  }

  Future<void> _stopPlayer() async {
    int startSeconds = _getSeconds(_startSecondsController.text);

    await widget.audioPlayer.pause();
    await widget.audioPlayer.seek(Duration(seconds: startSeconds));
    setState(() {
      _audioPlayerState = PlayerState.stopped;
    });
  }

  VoidCallback? _getOnPlayerPressedCallback() {
    if (widget.audioPlayer.source == null) {
      return null;
    }

    return () async {
      if (widget.audioPlayer.state == PlayerState.playing) {
        await _stopPlayer();
        return;
      }
      await widget.audioPlayer.resume();
      setState(() {
        _audioPlayerState = PlayerState.playing;
      });
    };
  }

  Future<void> _handlePositionChange() async {
    final int endSeconds = _getSeconds(_endSecondsController.text);

    final int duration = (await widget.audioPlayer.getDuration())!.inSeconds;

    if (_position!.inSeconds > (duration - endSeconds)) {
      await _stopPlayer();
    }
  }

  Future<void> _handleDurationChange() async {
    int startSeconds = _getSeconds(_startSecondsController.text);
    await widget.audioPlayer.seek(Duration(seconds: startSeconds));
  }

  void _initStreams() {
    _positionSubscription = widget.audioPlayer.onPositionChanged.listen((p) {
      setState(() {
        _position = p;
      });
      _handlePositionChange();
    });
    _durationSubscription = widget.audioPlayer.onDurationChanged.listen((
      duration,
    ) {
      setState(() => _duration = duration);
      _handleDurationChange();
    });
  }
}
