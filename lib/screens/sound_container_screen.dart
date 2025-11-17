import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sounboard/database/db.dart';
import 'package:sounboard/database/sound_containter_details.dart';
import 'package:sounboard/database/sound_details.dart';
import 'package:sounboard/utilities/sound_tile.dart';

class SoundContainerScreen extends StatefulWidget {
  final int soundContainerId;
  final VoidCallback onEdit;

  const SoundContainerScreen({
    super.key,
    required this.soundContainerId,
    required this.onEdit,
  });

  @override
  State<StatefulWidget> createState() => _SoundContainerScreenState();
}

class _SoundContainerScreenState extends State<SoundContainerScreen> {
  late Future<SoundContainerDetails?> _soundContainerFuture;
  late Future<List<SoundDetails>> _soundsFuture;

  @override
  void initState() {
    super.initState();
    _loadFutures();
  }

  void _loadFutures() {
    final dbHelper = DbHelper();
    _soundsFuture = dbHelper.getSounds(
      soundContainerId: widget.soundContainerId,
    );
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

        return Scaffold(
          appBar: AppBar(
            title: Text(soundContainerDetails.name),
            backgroundColor: Color.fromARGB(255, 58, 86, 67),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await _updateSoundContainer();
                  },
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: (soundContainerDetails.shuffle
                            ? const Color.fromRGBO(108, 12, 186, 1)
                            : const Color.fromRGBO(100, 100, 100, 1.0)),
                      ),
                      onPressed: () async =>
                          await _toggleShuffle(soundContainerDetails),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.loop,
                        color: (soundContainerDetails.loop
                            ? const Color.fromRGBO(108, 12, 186, 1)
                            : const Color.fromRGBO(100, 100, 100, 1.0)),
                      ),
                      onPressed: () async =>
                          await _toggleLoop(soundContainerDetails),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.waves,
                        color: (soundContainerDetails.transitions
                            ? const Color.fromRGBO(108, 12, 186, 1)
                            : const Color.fromRGBO(100, 100, 100, 1.0)),
                      ),
                      onPressed: () async =>
                          await _toggleTransitions(soundContainerDetails),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.trending_up,
                        color: (soundContainerDetails.fadeIn
                            ? const Color.fromRGBO(108, 12, 186, 1)
                            : const Color.fromRGBO(100, 100, 100, 1.0)),
                      ),
                      onPressed: () async =>
                          await _toggleFadeIn(soundContainerDetails),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.trending_down,
                        color: (soundContainerDetails.fadeOut
                            ? const Color.fromRGBO(108, 12, 186, 1)
                            : const Color.fromRGBO(100, 100, 100, 1.0)),
                      ),
                      onPressed: () async =>
                          await _toggleFadeOut(soundContainerDetails),
                    ),
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

                    final sounds = snapshot.data!;

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView.builder(
                        itemCount: sounds.length,
                        itemBuilder: (context, index) {
                          final soundDetails = sounds[index];

                          return SoundTile(
                            soundDetails: soundDetails,
                            onTapFunc: () {},
                            onRemoveFunc: (context) => showDialog(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                content: Text('Delete ${soundDetails.name}?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () async {
                                      await _deleteSound(soundDetails.soundId!);
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

  Future<void> _updateSoundContainer() async {
    throw UnimplementedError();
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

  Future<void> _toggleTransitions(SoundContainerDetails soundContainerDetails) async {
    soundContainerDetails.transitions = !soundContainerDetails.transitions;
    await DbHelper().updateSoundContainer(soundContainerDetails);
    setState(() {
      _loadFutures();
    });
    widget.onEdit();
  }

  Future<void> _toggleFadeIn(SoundContainerDetails soundContainerDetails) async {
    soundContainerDetails.fadeIn = !soundContainerDetails.fadeIn;
    await DbHelper().updateSoundContainer(soundContainerDetails);
    setState(() {
      _loadFutures();
    });
    widget.onEdit();
  }

  Future<void> _toggleFadeOut(SoundContainerDetails soundContainerDetails) async {
    soundContainerDetails.fadeOut = !soundContainerDetails.fadeOut;
    await DbHelper().updateSoundContainer(soundContainerDetails);
    setState(() {
      _loadFutures();
    });
    widget.onEdit();
  }

  Future<void> _deleteSound(int soundId) async {
    await DbHelper().unmapSoundFromSoundContainer(
      soundContainerId: widget.soundContainerId,
      soundId: soundId,
    );
    setState(() {
      _loadFutures();
    });
    widget.onEdit();
  }

  Future<void> _addSound() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final uri1 = result.files.single.path!;
      final dbHelper = DbHelper();
      final soundDetails = await dbHelper.insertSound(
        SoundDetails(name: uri1.split("\\").last, path: uri1),
      );
      await dbHelper.insertSoundContainerToSoundMapping(
        widget.soundContainerId,
        soundDetails,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("$uri1 added!")));
      setState(() {
        _loadFutures();
      });
      widget.onEdit();
    }
  }
}
