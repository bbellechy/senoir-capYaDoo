import 'package:flutter/material.dart';
import '../service/voice_recorder.dart';
import '../controller/voice_controller.dart';

class VoiceButton extends StatefulWidget {
  const VoiceButton({super.key});

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton> {
  final recorder = VoiceRecorder();
  String? path;

  @override
  Widget build(BuildContext context) {
    final controller = VoiceController(context);

    return GestureDetector(
      onLongPressStart: (_) async {
        path = await recorder.startRecord();
      },
      onLongPressEnd: (_) async {
        final p = await recorder.stopRecord();
        if (p != null) {
          controller.sendAndHandle(p);
        }
      },
      child: const Icon(Icons.mic, size: 40),
    );
  }
}
