import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sounboard/database/soundboard_details.dart';

class SoundboardTile extends StatelessWidget {
  final SoundboardDetails soundboardDetails;
  final VoidCallback onEnterFunc;
  final Function(BuildContext)? onRemoveFunc;

  const SoundboardTile({
    super.key,
    required this.soundboardDetails,
    required this.onEnterFunc,
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
            child: ElevatedButton(
              onPressed: onEnterFunc,
              child: Text(soundboardDetails.name)
            )
          )
        ],
      ),
    );
  }
}