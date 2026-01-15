import 'package:flutter/material.dart';

import 'package:capyadoo/core/services/tts_service.dart';

class TextToSpeechDemoPage extends StatefulWidget {
  const TextToSpeechDemoPage({super.key});

  @override
  State<TextToSpeechDemoPage> createState() => _TextToSpeechDemoPageState();
}

class _TextToSpeechDemoPageState extends State<TextToSpeechDemoPage> {
  final TextEditingController _controller = TextEditingController(
    text: 'สวัสดีค่ะ ลองทดสอบระบบแปลงข้อความเป็นเสียงค่ะ',
  );
  double _volume = 1.0; // 0.0 - 1.0
  double _rate = 0.5; // 0.0 - 1.0 (แล้วแต่แพลตฟอร์ม)
  double _pitch = 1.0; // 0.5 - 2.0 (แนะนำ)

  @override
  void initState() {
    super.initState();
    TtsService.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text-to-Speech Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'ข้อความที่จะอ่าน',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Controls
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ระดับเสียง: ${_volume.toStringAsFixed(2)}'),
                Slider(
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (v) async {
                    setState(() => _volume = v);
                    await TtsService.setVolume(v);
                  },
                ),
                SizedBox(height: 8),
                Text('ความเร็ว: ${_rate.toStringAsFixed(2)}'),
                Slider(
                  value: _rate,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (v) async {
                    setState(() => _rate = v);
                    await TtsService.setSpeechRate(v);
                  },
                ),
                SizedBox(height: 8),
                Text('ความสูงเสียง (Pitch): ${_pitch.toStringAsFixed(2)}'),
                Slider(
                  value: _pitch,
                  min: 0.5,
                  max: 2.0,
                  onChanged: (v) async {
                    setState(() => _pitch = v);
                    await TtsService.setPitch(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await TtsService.speak(_controller.text.trim());
                    },
                    child: const Text('อ่านออกเสียง'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await TtsService.stop();
                    },
                    child: const Text('หยุด'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
