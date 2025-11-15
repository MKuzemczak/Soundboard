import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sounboard/database/sound_details.dart';

class SoundTile extends StatelessWidget{
  final SoundDetails soundDetails;
  final VoidCallback onTapFunc;
  final Function(BuildContext) onRemoveFunc;

  const SoundTile({
    super.key,
    required this.soundDetails,
    required this.onTapFunc,
    required this.onRemoveFunc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5.0, right: 5.0, top: 5.0),
      child: Column(
        children: [
          Slidable(
            endActionPane: ActionPane(
              motion: StretchMotion(),
              children: [
                SlidableAction(
                  onPressed: onRemoveFunc,
                  icon: Icons.delete,
                  borderRadius: BorderRadius.circular(5.0)
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(Color.fromRGBO(0, 0, 0, 1))),
                  onPressed: onTapFunc,
                  child: Text(soundDetails.name)
                ),
              ],
            )
          )
        ],
      ),
    );
  }
}