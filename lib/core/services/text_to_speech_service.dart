import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  TextToSpeechService({FlutterTts? engine}) : _engine = engine ?? FlutterTts();

  final FlutterTts _engine;

  Future<void> initialize() async {
    await _engine.setLanguage('id-ID');
    await _engine.setPitch(1);
    await _engine.setSpeechRate(0.48);
  }

  Future<void> speak(String text) async {
    await _engine.stop();
    await _engine.speak(text);
  }

  Future<void> stop() => _engine.stop();
}
