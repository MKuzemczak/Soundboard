import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sounboard/database/db.dart';
import 'package:sounboard/database/sound_containter_details.dart';
import 'package:sounboard/database/sound_details.dart';
import 'package:sounboard/database/soundboard_details.dart';
import 'package:sounboard/screens/sound_container_screen.dart';
import 'package:stretch_wrap/stretch_wrap.dart';

class SoundboardViewScreen extends StatefulWidget {
  final SoundboardDetails soundboardDetails;

  const SoundboardViewScreen({super.key, required this.soundboardDetails});

  @override
  State<StatefulWidget> createState() => _SoundboardViewScreenState();
}

class _SoundboardViewScreenState extends State<SoundboardViewScreen> {
  late Future<List<SoundContainerDetails>> _soundContainersFuture;

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

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: StretchWrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    autoStretch: AutoStretch.all,
                    children: List.generate(
                      soundContainers.length,
                      (i) => ElevatedButton(
                        style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(Color.fromRGBO(0, 0, 0, 1))),
                        // onLongPress: () async {
                        //   FilePickerResult? result = await FilePicker.platform.pickFiles();
                  
                        //   if (result != null) {
                        //     print(result.files.single.path!);
                        //     final uri1 = result.files.single.path!;
                        //     String s = "$uri1 picked";
                        //     final dbHelper = DbHelper();
                        //     final soundDetails = await dbHelper.insertSound(SoundDetails(name: uri1.split("\\").last, path: uri1));
                        //     await dbHelper.insertSoundContainerToSoundMapping(soundContainers[i], soundDetails);
                        //     s = "$s and inserted!";
                        //     ScaffoldMessenger.of(context).showSnackBar(
                        //       SnackBar(content: Text(s)),
                        //     );
                        //   } else {
                        //     ScaffoldMessenger.of(context).showSnackBar(
                        //       SnackBar(content: Text("Not picked")),
                        //     );
                        //   }
                        // },
                        onLongPress: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SoundContainerScreen(
                              soundContainerId: soundContainers[i].soundContainerId!,
                              onEdit: () {
                                setState(() {
                                  _loadFutures();
                                });
                              },
                            ),
                          ),
                        ),
                        onPressed: () async {
                          final dbHelper = DbHelper();
                          final soundDetails = await dbHelper.getSounds(soundContainerId: soundContainers[i].soundContainerId!);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${List.generate(soundDetails.length, (i) => soundDetails[i].name)}")),
                          );
                        },
                        child: Text(soundContainers[i].name),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
