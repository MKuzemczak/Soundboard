import 'package:flutter/material.dart';
import 'package:sounboard/database/db.dart';
import 'package:sounboard/database/sound_containter_details.dart';
import 'package:sounboard/database/soundboard_details.dart';
import 'package:sounboard/screens/audioplayers_test.dart';
import 'package:sounboard/screens/soundboard_view_screen.dart';
import 'package:sounboard/utilities/soundboard_tile.dart';

class SoundboardListScreen extends StatefulWidget {
  const SoundboardListScreen({super.key});

  @override
  State<StatefulWidget> createState() => _SoundboardListScreenState();
}

class _SoundboardListScreenState extends State<SoundboardListScreen> {
  late Future<List<SoundboardDetails>> _soundboardsFuture;

  @override
  void initState() {
    super.initState();
    _loadFutures();
  }

  void _loadFutures() {
    _soundboardsFuture = DbHelper().getSoundboards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Row(
            children: [
              // ElevatedButton(
              //   onPressed: () async {
              //     final dbHelper = DbHelper();
              //     final sb = await dbHelper.insertSoundboard(
              //       SoundboardDetails(name: "DND"),
              //     );
              //     List<SoundContainerDetails> soundContainers = [];
              //     for (var i = 0; i < 13; i++) {
              //       final sc = await dbHelper.insertSoundContainer(
              //         SoundContainerDetails(
              //           name: "sc$i",
              //           shuffle: false,
              //           loop: true,
              //           transitions: true,
              //           fadeIn: true,
              //           fadeOut: true,
              //         ),
              //       );
              //       await dbHelper.insertSoundboardToSoundContainerMapping(
              //         soundboardId: sb.soundboardId!,
              //         soundContainerId: sc.soundContainerId!
              //       );
              //       soundContainers.add(sc);
              //     }
              //     setState(() {
              //       _loadFutures();
              //     });
              //   },
              //   child: Text("Insert DB data"),
              // ),
              // ElevatedButton(
              //   onPressed: () async {
              //     await DbHelper().deleteDb();
              //     setState(() {
              //       _loadFutures();
              //     });
              //   },
              //   child: Text("Delete database"),
              // ),
              
              // ElevatedButton(
              //   onPressed: () => Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) => AudioplayersTest(),
              //     ),
              //         ),
              //   child: Text("audioplayers"),
              // ),
              
            ],
          ),
          Expanded(
            child: FutureBuilder(
              future: _soundboardsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No soundboards found.'));
                }

                final soundboards = snapshot.data!;

                return ListView.builder(
                  itemCount: soundboards.length,
                  itemBuilder: (context, index) {
                    final soundboardDetails = soundboards[index];
                    return SoundboardTile(
                      soundboardDetails: soundboardDetails,
                      onEnterFunc: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SoundboardViewScreen(
                            soundboardDetails: soundboardDetails,
                          ),
                        ),
                      ),
                      onRemoveFunc: (context) {
                        throw UnimplementedError();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
