import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'text_to_speech_service.dart';

enum VoiceCommandType {
  navigation,
  objectSearch,
  signLanguage,
  frontCamera,
  backCamera,
  stop,
  unknown,
}

class VoiceCommand {
  const VoiceCommand({
    required this.type,
    required this.rawText,
    this.target,
  });

  final VoiceCommandType type;
  final String rawText;
  final String? target;

  bool get isUnknown => type == VoiceCommandType.unknown;
}

class VoiceRecognitionResult {
  const VoiceRecognitionResult({
    required this.words,
    required this.confidence,
  });

  final String words;
  final double confidence;
}

class VoiceCommandService {
  VoiceCommandService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _initialized = false;

  bool get isInitialized => _initialized;
  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    _initialized = await _speech.initialize(
      debugLogging: true,
      onStatus: (status) => debugPrint('[VoiceCommand] speech status: $status'),
      onError: (error) {
        debugPrint(
          '[VoiceCommand] speech error: ${error.errorMsg}, permanent: ${error.permanent}',
        );
      },
    );

    debugPrint('[VoiceCommand] speech initialized: $_initialized');
    debugPrint(
      '[VoiceCommand] microphone permission ${_initialized ? 'granted/available' : 'denied/unavailable'}',
    );
    return _initialized;
  }

  Future<VoiceRecognitionResult?> listenOnce({
    Duration listenFor = const Duration(seconds: 7),
    Duration pauseFor = const Duration(seconds: 2),
  }) async {
    if (!_initialized) {
      debugPrint('[VoiceCommand] listen skipped: speech not initialized');
      return null;
    }

    if (_speech.isListening) {
      await _speech.stop();
    }

    final completer = Completer<VoiceRecognitionResult?>();
    VoiceRecognitionResult? latestResult;

    debugPrint('[VoiceCommand] listening started');
    await _speech.listen(
      localeId: 'id_ID',
      listenFor: listenFor,
      pauseFor: pauseFor,
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
      onResult: (SpeechRecognitionResult result) {
        final words = result.recognizedWords.trim();
        latestResult = VoiceRecognitionResult(
          words: words,
          confidence: result.confidence,
        );
        debugPrint('[VoiceCommand] recognized words: "$words"');
        debugPrint('[VoiceCommand] confidence: ${result.confidence}');

        if (result.finalResult && !completer.isCompleted) {
          completer.complete(latestResult);
        }
      },
    );

    return completer.future.timeout(
      listenFor + const Duration(seconds: 2),
      onTimeout: () async {
        debugPrint('[VoiceCommand] listen timeout');
        await stop();
        return latestResult;
      },
    );
  }

  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  VoiceCommand parse(String text) {
    final raw = text.trim();
    final lower = raw.toLowerCase();

    if (lower.isEmpty) {
      return VoiceCommand(type: VoiceCommandType.unknown, rawText: raw);
    }

    if (_containsAny(lower, ['berhenti', 'stop', 'diam'])) {
      return VoiceCommand(type: VoiceCommandType.stop, rawText: raw);
    }

    if (_containsAny(lower, ['kamera depan', 'depan kamera'])) {
      return VoiceCommand(type: VoiceCommandType.frontCamera, rawText: raw);
    }

    if (_containsAny(lower, ['kamera belakang', 'belakang kamera'])) {
      return VoiceCommand(type: VoiceCommandType.backCamera, rawText: raw);
    }

    if (_containsAny(lower, ['analisis sekitar', 'arahkan jalan', 'lihat sekitar'])) {
      return VoiceCommand(type: VoiceCommandType.navigation, rawText: raw);
    }

    if (_containsAny(lower, ['baca isyarat', 'bahasa isyarat', 'isyarat'])) {
      return VoiceCommand(type: VoiceCommandType.signLanguage, rawText: raw);
    }

    final objectTarget = extractObjectTarget(lower);
    if (objectTarget != null && objectTarget.isNotEmpty) {
      debugPrint('[VoiceCommand] object target: $objectTarget');
      return VoiceCommand(
        type: VoiceCommandType.objectSearch,
        rawText: raw,
        target: objectTarget,
      );
    }

    return VoiceCommand(type: VoiceCommandType.unknown, rawText: raw);
  }

  bool _containsAny(String source, List<String> terms) {
    return terms.any(source.contains);
  }

  String? extractObjectTarget(String spokenText) {
    final normalized = spokenText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) return null;

    final words = normalized.split(' ');
    final intentIndex = words.indexWhere(
      (word) => word == 'cari' || word == 'carikan' || word == 'temukan',
    );
    if (intentIndex == -1) return null;

    final targetWords = words
        .skip(intentIndex + 1)
        .where((word) => word != 'tolong' && word != 'saya')
        .toList();

    final target = targetWords.join(' ').trim();
    return target.isEmpty ? null : target;
  }
}

class VoiceCommandController {
  VoiceCommandController({
    required VoiceCommandService service,
    required TextToSpeechService tts,
    required Future<void> Function(VoiceCommand command) onCommand,
    required void Function(bool isListening) onListeningChanged,
    required void Function(bool isSpeaking) onSpeakingChanged,
  })  : _service = service,
        _tts = tts,
        _onCommand = onCommand,
        _onListeningChanged = onListeningChanged,
        _onSpeakingChanged = onSpeakingChanged;

  final VoiceCommandService _service;
  final TextToSpeechService _tts;
  final Future<void> Function(VoiceCommand command) _onCommand;
  final void Function(bool isListening) _onListeningChanged;
  final void Function(bool isSpeaking) _onSpeakingChanged;

  bool _busy = false;
  bool _disposed = false;

  static const String introPrompt =
      'Suarasa aktif. Goyangkan ponsel untuk memberi perintah.';

  Future<void> announceReady() async {
    if (_disposed) return;
    await _speak(introPrompt);
  }

  Future<void> listenNow({bool withPrompt = true}) async {
    if (_disposed || _busy) return;
    if (withPrompt) {
      await _speak('Silakan ucapkan perintah.');
    }
    await _listenOnce();
  }

  Future<void> stopListening() async {
    _onListeningChanged(false);
    await _service.stop();
    debugPrint('[VoiceCommand] listening stopped');
  }

  Future<void> dispose() async {
    _disposed = true;
    await stopListening();
  }

  Future<void> _listenOnce() async {
    if (_busy || _disposed) return;
    _busy = true;
    _onListeningChanged(true);

    final result = await _service.listenOnce();
    await _service.stop();

    _onListeningChanged(false);
    _busy = false;
    debugPrint('[VoiceCommand] listening stopped');

    if (_disposed) return;

    final words = result?.words.trim() ?? '';
    if (words.isEmpty) {
      debugPrint('[VoiceCommand] no speech detected, stop listening');
      await _speak(
        'Saya belum mendengar suara. Goyangkan ponsel untuk mencoba lagi.',
      );
      return;
    }

    final command = _service.parse(words);
    debugPrint('[VoiceCommand] command matched: ${command.type.name}');

    if (command.isUnknown) {
      await _speak(
        'Perintah belum dikenali. Goyangkan ponsel untuk mencoba lagi.',
      );
      return;
    }

    await _onCommand(command);
  }

  Future<void> _speak(String text) async {
    if (_disposed) return;
    _onSpeakingChanged(true);
    try {
      await _tts.speakAndWait(text);
    } finally {
      _onSpeakingChanged(false);
    }
  }
}
