import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sounboard/database/db.dart';
import 'package:sounboard/database/sound_details.dart';
import 'package:sounboard/database/sound_mapping_details.dart';

class AddSoundDialogBox extends StatefulWidget {
  final int _soundContainerId;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final AudioPlayer audioPlayer;

  const AddSoundDialogBox({
    super.key,
    required int soundContainerId,
    required this.onCancel,
    required this.onSave,
    required this.audioPlayer,
  }) : _soundContainerId = soundContainerId;

  @override
  State<StatefulWidget> createState() => _AddSoundDialogBoxState();
}

class _AddSoundDialogBoxState extends State<AddSoundDialogBox> {
  String? _name;
  String? _path;
  PlayerState? _audioPlayerState;
  // ignore: unused_field
  StreamSubscription? _positionSubscription;
  // ignore: unused_field
  StreamSubscription? _durationSubscription;
  // ignore: unused_field
  StreamSubscription? _playerCompleteSubscription;
  Duration? _position;
  Duration? _duration;

  final TextEditingController _startSecondsController = TextEditingController(
    text: "0",
  );
  final TextEditingController _endSecondsController = TextEditingController();
  bool _isEndSecondsGreaterThanStartSeconds = false;

  String get _durationText => _duration?.toString().split('.').first ?? '';

  String get _positionText => _position?.toString().split('.').first ?? '';

  @override
  void initState() {
    super.initState();
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
                    child: Text(_name == null ? "Sound name" : _name!),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectSound(setState),
                    child: Text("Select sound"),
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
                              final int startSeconds = _getSeconds(value);
                              final int endSeconds = _getSeconds(_endSecondsController.text);
                              setState(() {
                                _isEndSecondsGreaterThanStartSeconds = (endSeconds > startSeconds);
                              },);
                              await widget.audioPlayer.seek(
                                Duration(seconds: startSeconds),
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
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'End seconds',
                              errorText: () {
                                if (!_isEndSecondsGreaterThanStartSeconds) {
                                  return "End <= Start!";
                                }
                                return null;
                              }(),
                            ),
                            onChanged: (value) {
                              final int startSeconds = _getSeconds(_startSecondsController.text);
                              final int endSeconds = _getSeconds(value);
                              setState(() {
                                _isEndSecondsGreaterThanStartSeconds = (endSeconds > startSeconds);
                              },);
                            },
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
                          onPressed: (_name == null || !_isEndSecondsGreaterThanStartSeconds) ? null : _save,
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

  Future<void> _selectSound(StateSetter setState) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final uri = result.files.single.path!;

      await widget.audioPlayer.stop();
      await widget.audioPlayer.setSource(DeviceFileSource(uri));

      setState(() {
        _name = uri.split("/").last.split("\\").last;
        _path = uri;
        _audioPlayerState = PlayerState.stopped;
      });
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("$_name selected!")));
    }
  }

  int _getSeconds(String text) {
    return text == "" ? 0 : int.parse(text);
  }

  Future<void> _cancel() async {
    await widget.audioPlayer.stop();
    widget.onCancel();
  }

  Future<void> _save() async {
    if (_name == null || _path == null) {
      return;
    }

    await widget.audioPlayer.stop();

    final dbHelper = DbHelper();
    final soundDetails = await dbHelper.insertSound(
      SoundDetails(name: _name!, path: _path!),
    );
    await dbHelper.insertSoundContainerToSoundMapping(
      widget._soundContainerId,
      SoundMappingDetails(
        soundDetails: soundDetails,
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
    final int startSeconds = _getSeconds(_startSecondsController.text);
    final int endSeconds = _getSeconds(_endSecondsController.text);

    if (_position!.inSeconds > endSeconds && endSeconds > startSeconds) {
      await _stopPlayer();
    }
  }

  Future<void> _handleDurationChange() async {
    int startSeconds = _getSeconds(_startSecondsController.text);
    await widget.audioPlayer.seek(Duration(seconds: startSeconds));
    setState(() {
      _endSecondsController.text = _duration!.inSeconds.toString();
      _isEndSecondsGreaterThanStartSeconds = (_duration!.inSeconds > startSeconds);
    });
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
    _playerCompleteSubscription = widget.audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _audioPlayerState = PlayerState.stopped;
        _position = Duration.zero;
      });
      _handlePositionChange();
    });
  }
}
