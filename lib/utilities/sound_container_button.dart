import 'package:flutter/material.dart';
import 'package:sounboard/audio/sound_container_player.dart';
import 'package:sounboard/database/sound_containter_details.dart';

class SoundContainerButton extends StatefulWidget {
  final SoundContainerDetails soundContainerDetails;
  final SoundContainerPlayer soundContainerPlayer;
  final VoidCallback onLongPress;
  final VoidCallback onStartedPlaying;

  const SoundContainerButton({
    super.key,
    required this.soundContainerDetails,
    required this.soundContainerPlayer,
    required this.onLongPress,
    required this.onStartedPlaying,
  });

  @override
  State<StatefulWidget> createState() => _SoundContainerButtonState();
}

class _SoundContainerButtonState extends State<SoundContainerButton> {
  bool? isP;

  @override
  void initState() {
    super.initState();
    widget.soundContainerPlayer.setOnStateChanged(() {
      setState(() {});
      if (widget.soundContainerDetails.soundContainerId != 5 || widget.soundContainerPlayer.isPlaying == isP) {
        return;
      }
      isP = widget.soundContainerPlayer.isPlaying;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(
          widget.soundContainerPlayer.isPlaying ? Color.fromRGBO(255, 0, 0, 1) : Color.fromRGBO(0, 0, 0, 1),
        ),
      ),
      onLongPress: () => widget.onLongPress(),
      onPressed: () async {
        if (widget.soundContainerPlayer.isPlaying) {
          await widget.soundContainerPlayer.stop();
        } else {
          widget.soundContainerPlayer.play();
          widget.onStartedPlaying();
        }
      },
      child: Text(widget.soundContainerDetails.name),
    );
  }
}
