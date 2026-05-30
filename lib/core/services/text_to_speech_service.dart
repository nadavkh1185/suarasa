import 'dart:async';

import 'package:flutter/foundation.dart';
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

  Future<void> speakAndWait(
    String text, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final completer = Completer<void>();

    _engine.setCompletionHandler(() {
      debugPrint('[TTS] completed');
      if (!completer.isCompleted) completer.complete();
    });
    _engine.setErrorHandler((message) {
      debugPrint('[TTS] error: $message');
      if (!completer.isCompleted) completer.complete();
    });

    await _engine.stop();
    final result = await _engine.speak(text);
    debugPrint('[TTS] speak result: $result');

    await completer.future.timeout(
      timeout,
      onTimeout: () {
        debugPrint('[TTS] completion timeout, continuing to listener');
      },
    );
  }

  Future<void> stop() => _engine.stop();
}
