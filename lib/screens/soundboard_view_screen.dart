// import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sounboard/audio/audio_players_manager.dart';
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addSoundContainer(),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            opacity: 0.2,
            image: _getBackgroundAssetImage(),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                      child: Column(
                        children: _getSections(soundContainers),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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
          initialColor: Color.fromARGB(255, 50, 75, 47),
          isUpdate: false,
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
                    soundboardId: widget.soundboardDetails.soundboardId!,
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
              // ignore: use_build_context_synchronously
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

  AssetImage _getBackgroundAssetImage() {
    final rng = Random();
    final imgId = rng.nextInt(9);
    return AssetImage("assets/images/bg-$imgId.jpg");
  }

  Map<String, List<SoundContainerDetails>> _getSectionNameToSoundContainersMap(List<SoundContainerDetails> soundContainers) {
    Map<String, List<SoundContainerDetails>> result = {};

    for (var sc in soundContainers) {
      result.putIfAbsent(sc.section, () => <SoundContainerDetails>[]).add(sc);
    }

    return result;
  }

  Widget _getSectionDivider(String sectionName) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Text(sectionName, style: TextStyle(color: Color(0x99ffffff)),),
        ),
        Expanded(child: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Divider(color: Color(0x99ffffff),),
        )),
      ],
    );
  }

  SoundContainerButton _getSoundContainerButton(SoundContainerDetails soundContainerDetails) {
    return SoundContainerButton(
      key: Key(soundContainerDetails.name),
      soundContainerDetails: soundContainerDetails,
      soundContainerPlayer: _audioPlayersManager
          .getSoundContainerPlayerForSoundConainer(
            soundContainerDetails.soundContainerId!,
          ),
      onLongPress: () =>
          _showSoundContainerLongPressDialog(soundContainerDetails),
      onStartedPlaying: () {
        _stopPlayersOtherThan(soundContainerDetails);
      },
    );
  }

  List<Widget> _getSections(List<SoundContainerDetails> soundContainers) {
    List<Widget> result = [];

    for (var nameAndSCList in _getSectionNameToSoundContainersMap(soundContainers).entries) {
      result.add(
        Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
          child: _getSectionDivider(nameAndSCList.key),
        )
      );

      List<Widget> stretchWrapChildren = [];

      for (var soundContainerDetails in nameAndSCList.value) {
        stretchWrapChildren.add(_getSoundContainerButton(soundContainerDetails));
      }

      result.add(
        StretchWrap(
          spacing: 4.0,
          runSpacing: 0.0,
          autoStretch: AutoStretch.all,
          children: stretchWrapChildren,
        ),
      );
    }

    result.add(SizedBox(height: 100, width: 2,));

    return result;
  }
}
