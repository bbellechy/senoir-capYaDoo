import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();

  static Future<void> init() async {
    await _tts.setLanguage('th-TH');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  static Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  static Future<void> stop() async {
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
}
