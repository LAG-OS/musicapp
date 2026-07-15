import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class AudioSlider extends StatefulWidget {
  final Duration? position;
  final Duration? duration;
  final Function(double) onSeek;

  const AudioSlider({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<AudioSlider> createState() => _AudioSliderState();
}

class _AudioSliderState extends State<AudioSlider> {
  // Esta variable guardará el valor temporal solo mientras arrastramos el dedo
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    // Calculamos el valor real de la canción (de 0.0 a 1.0)
    final positionMs = widget.position?.inMilliseconds.toDouble() ?? 0.0;
    final durationMs =
        widget.duration?.inMilliseconds.toDouble() ??
        1.0; // Evitamos división por 0

    // clamp asegura que el valor nunca se pase de 0.0 o 1.0
    final realValue = (positionMs / durationMs).clamp(0.0, 1.0);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Pallete.whiteColor,
            inactiveTrackColor: Pallete.whiteColor.withAlpha(30),
            thumbColor: Pallete.whiteColor,
            trackHeight: 4,
            overlayColor: Pallete.whiteColor.withAlpha(50),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
          ),
          child: Slider(
            // Si _dragValue tiene un valor (estamos arrastrando), usamos ese.
            // Si es null, usamos la posición real de la canción.
            value: _dragValue ?? realValue,
            min: 0,
            max: 1,
            onChanged: (val) {
              // Esto SOLO redibuja este pequeño componente
              setState(() {
                _dragValue = val;
              });
            },
            onChangeEnd: (val) {
              widget.onSeek(val); // Llamamos a la función de tu Notifier
              setState(() {
                _dragValue =
                    null; // Soltamos el dedo, volvemos a seguir la canción real
              });
            },
          ),
        ),
        Row(
          children: [
            Text(
              '${widget.position?.inMinutes ?? 0}:${((widget.position?.inSeconds ?? 0) % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Pallete.subtitleText,
                fontSize: 13,
                fontWeight: FontWeight.w300,
              ),
            ),
            const Expanded(child: SizedBox()),
            Text(
              '${widget.duration?.inMinutes ?? 0}:${((widget.duration?.inSeconds ?? 0) % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Pallete.subtitleText,
                fontSize: 13,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
