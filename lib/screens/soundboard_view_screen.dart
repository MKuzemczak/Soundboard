// import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sounboard/audio/audio_players_manager.dart';
import 'package:sounboard/audio/sound_container_player.dart';
import 'package:sounboard/database/db.dart';
import 'package:sounboard/database/sound_containter_details.dart';
import 'package:sounboard/database/soundboard_details.dart';
import 'package:sounboard/screens/sound_container_screen.dart';
import 'package:sounboard/utilities/add_sound_container_dialog_box.dart';
import 'package:sounboard/utilities/sound_container_button.dart';
import 'package:stretch_wrap/stretch_wrap.dart';

class SoundboardViewScreen extends StatefulWidget {
  final SoundboardDetails soundboardDetails;

  const SoundboardViewScreen({super.key, required this.soundboardDetails});

  @override
  State<StatefulWidget> createState() => _SoundboardViewScreenState();
}

class _SoundboardViewScreenState extends State<SoundboardViewScreen> {
  late Future<List<SoundContainerDetails>> _soundContainersFuture;
  final AudioPlayersManager _audioPlayersManager;

  _SoundboardViewScreenState() : _audioPlayersManager = AudioPlayersManager();

  @override
  void initState() {
    super.initState();
    _loadFutures();
  }

  void _loadFutures() {
    _soundContainersFuture = DbHelper().getSoundContainers(
      soundboardDetails: widget.soundboardDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.soundboardDetails.name),
        backgroundColor: Color.fromARGB(255, 58, 86, 67),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: _soundContainersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No sound containers found.'),
                  );
                }

                final soundContainers = snapshot.data!;

                _audioPlayersManager.rebuildAudioPlayersMap(soundContainers);

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: StretchWrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    autoStretch: AutoStretch.all,
                    children: List.generate(
                      soundContainers.length,
                      (i) => SoundContainerButton(
                        key: Key(soundContainers[i].name),
                        soundContainerDetails: soundContainers[i],
                        soundContainerPlayer: _audioPlayersManager
                            .getSoundContainerPlayerForSoundConainer(
                              soundContainers[i].soundContainerId!,
                            ),
                        onLongPress: () => _showSoundContainerLongPressDialog(
                          soundContainers[i],
                        ),
                        onStartedPlaying: () {
                          _stopPlayersOtherThan(soundContainers[i]);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSoundContainer(),
        child: Icon(Icons.add),
      ),
    );
  }

  void _addSoundContainer() {
    showDialog(
      context: context,
      builder: (context) {
        return AddSoundContainerDialogBox(
          soundboardId: widget.soundboardDetails.soundboardId!,
          onSave: () {
            Navigator.pop(context);
            setState(() {
              _loadFutures();
            });
          },
          onCancel: () => Navigator.pop(context),
          initialShuffleSwitchState: true,
          initialLoopSwitchState: true,
          initialTransitionsSwitchState: true,
          initialFadeInSwitchState: true,
          initialFadeOutSwitchState: true,
        );
      },
    );
  }

  Future<void> _deleteSoundCountainer(
    SoundContainerDetails soundContainerDetails,
  ) async {
    await DbHelper().unmapSoundContainerFromSoundboard(
      soundboardId: widget.soundboardDetails.soundboardId!,
      soundContainerId: soundContainerDetails.soundContainerId!,
    );
    setState(() {
      _loadFutures();
    });
  }

  void _showSoundContainerLongPressDialog(
    SoundContainerDetails soundContainerDetails,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        content: Text(
          'What do you want to do with ${soundContainerDetails.name}?',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
              _showSoundContainerDeleteDialog(soundContainerDetails);
            },
          ),
          TextButton(
            child: const Text('Edit'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SoundContainerScreen(
                    soundContainerId: soundContainerDetails.soundContainerId!,
                    onEdit: () => setState(() {
                      _loadFutures();
                    }),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSoundContainerDeleteDialog(
    SoundContainerDetails soundContainerDetails,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        content: Text('Delete ${soundContainerDetails.name}?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Delete'),
            onPressed: () async {
              await _deleteSoundCountainer(soundContainerDetails);
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _stopPlayersOtherThan(SoundContainerDetails soundContainerDetails) {
    _audioPlayersManager.stopAudioPlayersOtherThan(
      soundContainerDetails.soundContainerId!,
    );
  }
}
