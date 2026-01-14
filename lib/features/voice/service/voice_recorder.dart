import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class VoiceRecorder {
  final AudioRecorder recorder = AudioRecorder();

  Future<String> startRecord() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice.wav';

    await recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );

    return path;
  }

  Future<String?> stopRecord() async {
    return await recorder.stop();
  }
}
