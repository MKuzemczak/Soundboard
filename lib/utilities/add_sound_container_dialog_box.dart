import 'package:flutter/material.dart';
import 'package:sounboard/database/db.dart';
import 'package:sounboard/database/sound_containter_details.dart';

class AddSoundContainerDialogBox extends StatefulWidget {
  final TextEditingController nameController = TextEditingController();
  final int soundboardId;
  final bool initialShuffleSwitchState;
  final bool initialLoopSwitchState;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  AddSoundContainerDialogBox({
    super.key,
    required this.soundboardId,
    required this.onSave,
    required this.onCancel,
    required this.initialShuffleSwitchState,
    required this.initialLoopSwitchState,
  });

  @override
  _AddSoundContainerDialogBoxState createState() =>
      _AddSoundContainerDialogBoxState(
        shuffleSwitchState: initialShuffleSwitchState,
        loopSwitchState: initialLoopSwitchState,
      );
}

class _AddSoundContainerDialogBoxState
    extends State<AddSoundContainerDialogBox> {
  bool shuffleSwitchState;
  bool loopSwitchState;

  _AddSoundContainerDialogBoxState({
    required this.shuffleSwitchState,
    required this.loopSwitchState,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.7,
            height: MediaQuery.sizeOf(context).height * 0.3,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: TextField(
                      controller: widget.nameController,
                      minLines: 1,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Sound container name',
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
                            child: IconButton(
                              icon: Icon(
                                Icons.shuffle,
                                color: (shuffleSwitchState
                                    ? const Color.fromRGBO(108, 12, 186, 1)
                                    : const Color.fromRGBO(100, 100, 100, 1.0)),
                              ),
                              onPressed: () async => setState(() {
                                shuffleSwitchState = !shuffleSwitchState;
                              }),
                            ),
                          ),
                          Text(
                            "Shuffle",
                            style: TextStyle(
                              color: (shuffleSwitchState
                                  ? const Color.fromRGBO(108, 12, 186, 1)
                                  : const Color.fromRGBO(100, 100, 100, 1.0)),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
                            child: IconButton(
                              icon: Icon(
                                Icons.loop,
                                color: (loopSwitchState
                                    ? const Color.fromRGBO(108, 12, 186, 1)
                                    : const Color.fromRGBO(100, 100, 100, 1.0)),
                              ),
                              onPressed: () async => setState(() {
                                loopSwitchState = !loopSwitchState;
                              }),
                            ),
                          ),
                          Text(
                            "Loop",
                            style: TextStyle(
                              color: (loopSwitchState
                                  ? const Color.fromRGBO(108, 12, 186, 1)
                                  : const Color.fromRGBO(100, 100, 100, 1.0)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                Color.fromRGBO(0, 0, 0, 1),
                              ),
                            ),
                            onPressed: () {
                              widget.nameController.clear();
                              widget.onCancel();
                            },
                            child: Text('Cancel'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                Color.fromRGBO(0, 0, 0, 1),
                              ),
                            ),
                            onPressed: _saveSoundContainer,
                            child: Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveSoundContainer() async {
    final soundContainerDetails = SoundContainerDetails(
      name: widget.nameController.text,
      shuffle: shuffleSwitchState,
      loop: loopSwitchState,
    );

    final dbHelper = DbHelper();
    final inserted = await dbHelper.insertSoundContainer(soundContainerDetails);
    await dbHelper.insertSoundboardToSoundContainerMapping(
      soundboardId: widget.soundboardId,
      soundContainerId: inserted.soundContainerId!,
    );

    widget.onSave();
  }
}
