import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sounboard/screens/logger.dart';
import 'package:sounboard/utilities/player_widget.dart';

class AudioplayersTest extends StatefulWidget {
  const AudioplayersTest({super.key});

  @override
  State<StatefulWidget> createState() => _AudioplayersTestState();
}

class _AudioplayersTestState extends State<AudioplayersTest> {
  AudioPlayer audioPlayer1 = AudioPlayer();


  @override
  void initState() {

    super.initState();
    _loadFutures();

    audioPlayer1.setReleaseMode(ReleaseMode.stop);
    audioPlayer1.setSource(AssetSource("sound/mia.mp3"));
  }

  void _loadFutures() {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("audioplayers test"),
        backgroundColor: Color.fromARGB(255, 58, 86, 67),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles();

              if (result != null) {
                final uri1 = result.files.single.path!;
                audioPlayer1.setSource(DeviceFileSource(uri1));
              }
            },
            child: Text("Select")
          ),
          PlayerWidget(player: audioPlayer1),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoggerTab(player: audioPlayer1),
              ),
                  ),
            child: Text("audioplayers"),
          ),
          
        ],
      ),
    );
  }
}