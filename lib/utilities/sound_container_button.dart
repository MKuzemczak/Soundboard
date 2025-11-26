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
      if (widget.soundContainerDetails.soundContainerId != 5 ||
          widget.soundContainerPlayer.isPlaying == isP) {
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
        side: WidgetStateProperty.all<BorderSide>(
          BorderSide(width: 3.0, color: _getBorderColor()),
        ),
        backgroundColor: WidgetStateProperty.all<Color>(_getButtonColor()),
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
      child: Text(widget.soundContainerDetails.name, style: TextStyle(color: _getTextColor()),),
    );
  }

  Color _getNegativeColor(Color color) {
    int a = (255 * color.a).toInt();
    int r = (255 * (1.0 - color.r)).toInt();
    int g = (255 * (1.0 - color.g)).toInt();
    int b = (255 * (1.0 - color.b)).toInt();
    return Color.fromARGB(a, r, g, b);
  }

  Color _getBorderColor() {
    if (widget.soundContainerDetails.color == null) {
      if (widget.soundContainerPlayer.isPlaying) {
        return Color.fromRGBO(255, 0, 0, 1);
      }
      return Color.fromRGBO(0, 0, 0, 1);
    }

    if (widget.soundContainerPlayer.isPlaying) {
      return _getNegativeColor(widget.soundContainerDetails.color!);
    }

    return widget.soundContainerDetails.color!;
  }

  Color _getButtonColor() {
    if (widget.soundContainerDetails.color == null) {
      return Color.fromRGBO(0, 0, 0, 1);
    }

    return widget.soundContainerDetails.color!;
  }

  Color _getTextColor() {
    if (widget.soundContainerDetails.color == null) {
      return Color.fromARGB(255, 71, 120, 66);
    }

    var negativeColor = HSLColor.fromColor(_getNegativeColor(widget.soundContainerDetails.color!));
    final luminance = widget.soundContainerDetails.color!.computeLuminance();
    if (luminance < 0.2) {
      return negativeColor.withLightness((1.0 - negativeColor.lightness) * 0.5 + negativeColor.lightness).toColor();
    }

    return negativeColor.withLightness(negativeColor.lightness * 0.3).toColor();
  }
}
