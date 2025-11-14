import 'package:flutter/material.dart';
import 'package:sounboard/database/db.dart';
import 'package:sounboard/database/sound_containter_details.dart';
import 'package:sounboard/database/soundboard_details.dart';

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
                  return const Center(child: Text('No sound containers found.'));
                }

                final soundContainers = snapshot.data!;

                return SingleChildScrollView(
                  child: Column(
                    children: _getCountContainerButtonRows(soundContainers),
                  ),
                );
              }
            )
          )
        ],
      )
    );
  }

  List<Widget> _getCountContainerButtonRows(List<SoundContainerDetails> soundContainers) {
    List<Widget> result = [];

    for (var i = 0; i < soundContainers.length;) {
      List<Widget> rowChildren = [];
      for (var j = 0; j < 5 && i < soundContainers.length; {j++, i++}) {
        rowChildren.add(
          ElevatedButton(
            onPressed: () {},
            child: Text(soundContainers[i].name)
          )
        );
      }
      result.add(Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: rowChildren));
    }

    return result;
  }
}
