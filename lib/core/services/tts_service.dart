import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;
  static final List<String> _queue = <String>[];
  static bool _isPlayingQueue = false;

  static Future<void> init() async {
    if (_initialized) return;

    await _tts.setLanguage('th-TH');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // ลด latency โดยเริ่มพูดเป็นช่วง ๆ และพูดต่อเมื่อจบช่วงก่อนหน้า
    await _tts.awaitSpeakCompletion(false);
    _tts.setCompletionHandler(() async {
      await _playNextFromQueue();
    });
    _tts.setCancelHandler(() {
      _queue.clear();
      _isPlayingQueue = false;
    });

    _initialized = true;
  }

  static Future<void> speak(String text) async {
    await init();
    await stop();

    final chunks = _chunkText(text);
    if (chunks.isEmpty) return;

    _queue
      ..clear()
      ..addAll(chunks);

    _isPlayingQueue = true;
    await _playNextFromQueue();
  }

  static Future<void> stop() async {
    _queue.clear();
    _isPlayingQueue = false;
    await _tts.stop();
  }

  static Future<void> setVolume(double volume) async {
    await _tts.setVolume(volume);
  }

  static Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  static Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch);
  }

  static Future<void> _playNextFromQueue() async {
    if (!_isPlayingQueue) return;
    if (_queue.isEmpty) {
      _isPlayingQueue = false;
      return;
    }

    // พูด chunk แรกทันที → ลดเวลารอสำหรับข้อความยาว
    final next = _queue.removeAt(0);
    if (next.trim().isEmpty) {
      await _playNextFromQueue();
      return;
    }

    await _tts.speak(next);
  }

  static List<String> _chunkText(String input) {
    final text = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return [];

    // ปรับให้ chunk แรกเริ่มเร็ว (engine สังเคราะห์สั้น ๆ ก่อน)
    const int maxLen = 200;
    const String splitChars = '.,!?;:\n';

    final chunks = <String>[];
    int start = 0;
    while (start < text.length) {
      int end = (start + maxLen < text.length) ? start + maxLen : text.length;

      // พยายามตัดที่เครื่องหมายวรรคตอน/ช่องว่าง เพื่อไม่ให้คำขาด
      int cut = -1;
      for (int i = end - 1; i > start; i--) {
        final ch = text[i];
        if (splitChars.contains(ch) || ch == ' ') {
          cut = i + 1;
          break;
        }
      }
      if (cut == -1) cut = end;

      chunks.add(text.substring(start, cut).trim());
      start = cut;
    }

    // กันกรณีมี empty chunk
    return chunks.where((c) => c.trim().isNotEmpty).toList();
  }
}
