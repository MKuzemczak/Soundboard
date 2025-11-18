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

  @override
  void initState() {
    super.initState();
    widget.soundContainerPlayer.setOnStateChanged(() { setState(() {}); });
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
          widget.soundContainerPlayer.stop();
        } else {
          widget.soundContainerPlayer.play();
          widget.onStartedPlaying();
        }
      },
      child: Text(widget.soundContainerDetails.name),
    );
  }
}
