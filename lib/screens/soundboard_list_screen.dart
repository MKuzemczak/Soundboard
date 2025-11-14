import 'package:flutter/material.dart';
import 'package:sounboard/database/db.dart';
import 'package:sounboard/database/soundboard_details.dart';
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
                          builder: (context) { return Column(); }//=> SoundboardViewScreen()
                        )
                      ),
                      onRemoveFunc: (context) {
                        throw Exception("NOT IMPLEMENTED");
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
