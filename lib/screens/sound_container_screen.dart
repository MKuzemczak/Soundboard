import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sounboard/database/db.dart';
import 'package:sounboard/database/sound_containter_details.dart';
import 'package:sounboard/database/sound_mapping_details.dart';
import 'package:sounboard/utilities/add_sound_container_dialog_box.dart';
import 'package:sounboard/utilities/add_sound_dialog_box.dart';
import 'package:sounboard/utilities/edit_sound_mapping_dialog_box.dart';
import 'package:sounboard/utilities/sound_tile.dart';

class SoundContainerScreen extends StatefulWidget {
  final int soundContainerId;
  final int soundboardId;
  final VoidCallback onEdit;

  const SoundContainerScreen({
    super.key,
    required this.soundContainerId,
    required this.onEdit,
    required this.soundboardId,
  });

  @override
  State<StatefulWidget> createState() => _SoundContainerScreenState();
}

class _SoundContainerScreenState extends State<SoundContainerScreen> {
  late Future<SoundContainerDetails?> _soundContainerFuture;
  late Future<List<SoundMappingDetails>> _soundsFuture;

  @override
  void initState() {
    super.initState();
    _loadFutures();
  }

  void _loadFutures() {
    final dbHelper = DbHelper();
    _soundsFuture = dbHelper.getSoundMappings(widget.soundContainerId);
    _soundContainerFuture = dbHelper.getSoundContainer(widget.soundContainerId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _soundContainerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('Sound container not found.'));
        }

        final soundContainerDetails = snapshot.data!;
        final appBarItemColor = _getAppBarItemColor(soundContainerDetails);

        return Scaffold(
          appBar: AppBar(
            iconTheme: IconThemeData(color: appBarItemColor),
            title: Text(
              soundContainerDetails.name,
              style: TextStyle(
                color: appBarItemColor,
              ),
            ),
            backgroundColor: soundContainerDetails.color,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await _updateSoundContainer(soundContainerDetails);
                  },
                  color: appBarItemColor,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 12.0,
                          right: 12.0,
                          top: 8.0,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.shuffle,
                            color: (soundContainerDetails.shuffle
                                ? const Color.fromARGB(255, 175, 113, 227)
                                : const Color.fromRGBO(100, 100, 100, 1.0)),
                          ),
                          onPressed: () async =>
                              await _toggleShuffle(soundContainerDetails),
                        ),
                      ),
                      Text(
                        "Shuffle",
                        style: TextStyle(
                          color: (soundContainerDetails.shuffle
                              ? const Color.fromARGB(255, 175, 113, 227)
                              : const Color.fromRGBO(100, 100, 100, 1.0)),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 12.0,
                          right: 12.0,
                          top: 8.0,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.loop,
                            color: (soundContainerDetails.loop
                                ? const Color.fromARGB(255, 175, 113, 227)
                                : const Color.fromRGBO(100, 100, 100, 1.0)),
                          ),
                          onPressed: () async =>
                              await _toggleLoop(soundContainerDetails),
                        ),
                      ),
                      Text(
                        "Loop",
                        style: TextStyle(
                          color: (soundContainerDetails.loop
                              ? const Color.fromARGB(255, 175, 113, 227)
                              : const Color.fromRGBO(100, 100, 100, 1.0)),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 15.0,
                          right: 15.0,
                          top: 8.0,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.waves,
                            color: (soundContainerDetails.transitions
                                ? const Color.fromARGB(255, 175, 113, 227)
                                : const Color.fromRGBO(100, 100, 100, 1.0)),
                          ),
                          onPressed: () async =>
                              await _toggleTransitions(soundContainerDetails),
                        ),
                      ),
                      Text(
                        "Transitions",
                        style: TextStyle(
                          color: (soundContainerDetails.transitions
                              ? const Color.fromARGB(255, 175, 113, 227)
                              : const Color.fromRGBO(100, 100, 100, 1.0)),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 12.0,
                          right: 12.0,
                          top: 8.0,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.trending_up,
                            color: (soundContainerDetails.fadeIn
                                ? const Color.fromARGB(255, 175, 113, 227)
                                : const Color.fromRGBO(100, 100, 100, 1.0)),
                          ),
                          onPressed: () async =>
                              await _toggleFadeIn(soundContainerDetails),
                        ),
                      ),
                      Text(
                        "Fade in",
                        style: TextStyle(
                          color: (soundContainerDetails.fadeIn
                              ? const Color.fromARGB(255, 175, 113, 227)
                              : const Color.fromRGBO(100, 100, 100, 1.0)),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 12.0,
                          right: 12.0,
                          top: 8.0,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.trending_down,
                            color: (soundContainerDetails.fadeOut
                                ? const Color.fromARGB(255, 175, 113, 227)
                                : const Color.fromRGBO(100, 100, 100, 1.0)),
                          ),
                          onPressed: () async =>
                              await _toggleFadeOut(soundContainerDetails),
                        ),
                      ),
                      Text(
                        "Fade out",
                        style: TextStyle(
                          color: (soundContainerDetails.fadeOut
                              ? const Color.fromARGB(255, 175, 113, 227)
                              : const Color.fromRGBO(100, 100, 100, 1.0)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: FutureBuilder(
                  future: _soundsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No sounds found.'));
                    }

                    final soundMappings = snapshot.data!;

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView.builder(
                        itemCount: soundMappings.length,
                        itemBuilder: (context, index) {
                          final soundMappingDetails = soundMappings[index];

                          return SoundTile(
                            soundDetails: soundMappingDetails.soundDetails,
                            onTapFunc: () => _editSound(soundMappingDetails),
                            onRemoveFunc: (context) => showDialog(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                content: Text(
                                  'Delete ${soundMappingDetails.soundDetails.name}?',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () async {
                                      await _deleteSoundMapping(
                                        soundMappingDetails
                                            .soundDetails
                                            .soundId!,
                                      );
                                      // ignore: use_build_context_synchronously
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Delete'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addSound(),
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }

  Color _getNegativeColor(Color color) {
    int a = (255 * color.a).toInt();
    int r = (255 * (1.0 - color.r)).toInt();
    int g = (255 * (1.0 - color.g)).toInt();
    int b = (255 * (1.0 - color.b)).toInt();
    return Color.fromARGB(a, r, g, b);
  }

  Color _getAppBarItemColor(SoundContainerDetails soundContainerDetails) {
    if (soundContainerDetails.color == null) {
      return Color.fromARGB(255, 71, 120, 66);
    }

    var negativeColor = HSLColor.fromColor(
      _getNegativeColor(soundContainerDetails.color!),
    );
    final luminance = soundContainerDetails.color!.computeLuminance();
    if (luminance < 0.2) {
      return negativeColor
          .withLightness(
            (1.0 - negativeColor.lightness) * 0.5 + negativeColor.lightness,
          )
          .toColor();
    }

    return negativeColor.withLightness(negativeColor.lightness * 0.3).toColor();
  }

  Future<void> _updateSoundContainer(
    SoundContainerDetails soundContainerDetails,
  ) async {
    showDialog(
      context: context,
      builder: (context) {
        return AddSoundContainerDialogBox(
          soundboardId: widget.soundboardId,
          onSave: () {
            Navigator.pop(context);
            setState(() {
              _loadFutures();
            });
            widget.onEdit();
          },
          onCancel: () => Navigator.pop(context),
          initialShuffleSwitchState: soundContainerDetails.shuffle,
          initialLoopSwitchState: soundContainerDetails.loop,
          initialTransitionsSwitchState: soundContainerDetails.transitions,
          initialFadeInSwitchState: soundContainerDetails.fadeIn,
          initialFadeOutSwitchState: soundContainerDetails.fadeOut,
          initialColor: soundContainerDetails.color == null
              ? Color.fromARGB(255, 255, 255, 255)
              : soundContainerDetails.color!,
          isUpdate: true,
          soundContainerId: soundContainerDetails.soundContainerId!,
          initialName: soundContainerDetails.name,
        );
      },
    );
  }

  Future<void> _toggleShuffle(
    SoundContainerDetails soundContainerDetails,
  ) async {
    soundContainerDetails.shuffle = !soundContainerDetails.shuffle;
    await DbHelper().updateSoundContainer(soundContainerDetails);
    setState(() {
      _loadFutures();
    });
    widget.onEdit();
  }

  Future<void> _toggleLoop(SoundContainerDetails soundContainerDetails) async {
    soundContainerDetails.loop = !soundContainerDetails.loop;
    await DbHelper().updateSoundContainer(soundContainerDetails);
    setState(() {
      _loadFutures();
    });
    widget.onEdit();
  }

  Future<void> _toggleTransitions(
    SoundContainerDetails soundContainerDetails,
  ) async {
    soundContainerDetails.transitions = !soundContainerDetails.transitions;
    await DbHelper().updateSoundContainer(soundContainerDetails);
    setState(() {
      _loadFutures();
    });
    widget.onEdit();
  }

  Future<void> _toggleFadeIn(
    SoundContainerDetails soundContainerDetails,
  ) async {
    soundContainerDetails.fadeIn = !soundContainerDetails.fadeIn;
    await DbHelper().updateSoundContainer(soundContainerDetails);
    setState(() {
      _loadFutures();
    });
    widget.onEdit();
  }

  Future<void> _toggleFadeOut(
    SoundContainerDetails soundContainerDetails,
  ) async {
    soundContainerDetails.fadeOut = !soundContainerDetails.fadeOut;
    await DbHelper().updateSoundContainer(soundContainerDetails);
    setState(() {
      _loadFutures();
    });
    widget.onEdit();
  }

  Future<void> _deleteSoundMapping(int soundId) async {
    await DbHelper().unmapSoundFromSoundContainer(
      soundContainerId: widget.soundContainerId,
      soundId: soundId,
    );
    setState(() {
      _loadFutures();
    });
    widget.onEdit();
  }

  void _addSound() {
    final AudioPlayer audioPlayer = AudioPlayer()
      ..setReleaseMode(ReleaseMode.stop);
    showDialog(
      context: context,
      builder: (context) {
        return AddSoundDialogBox(
          soundContainerId: widget.soundContainerId,
          onCancel: () {
            Navigator.pop(context);
          },
          onSave: () {
            Navigator.pop(context);
            setState(() {
              _loadFutures();
            });
          },
          audioPlayer: audioPlayer,
        );
      },
    ).then((_) {
      audioPlayer.stop();
    });
  }

  Future<void> _editSound(SoundMappingDetails soundMappingDetails) async {
    final AudioPlayer audioPlayer = AudioPlayer()
      ..setReleaseMode(ReleaseMode.stop);
    showDialog(
      context: context,
      builder: (context) {
        return EditSoundMappingDialogBox(
          soundContainerId: widget.soundContainerId,
          onCancel: () {
            Navigator.pop(context);
          },
          onSave: () {
            Navigator.pop(context);
            setState(() {
              _loadFutures();
            });
            widget.onEdit();
          },
          audioPlayer: audioPlayer,
          soundMappingDetails: soundMappingDetails,
        );
      },
    ).then((_) {
      audioPlayer.stop();
    });
  }
}
