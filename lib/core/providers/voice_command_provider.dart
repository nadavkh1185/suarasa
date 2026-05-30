import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoiceCommandState {
  const VoiceCommandState({
    this.isInitialized = false,
    this.isListening = false,
    this.lastWords = '',
    this.lastConfidence = 0,
  });

  final bool isInitialized;
  final bool isListening;
  final String lastWords;
  final double lastConfidence;

  VoiceCommandState copyWith({
    bool? isInitialized,
    bool? isListening,
    String? lastWords,
    double? lastConfidence,
  }) {
    return VoiceCommandState(
      isInitialized: isInitialized ?? this.isInitialized,
      isListening: isListening ?? this.isListening,
      lastWords: lastWords ?? this.lastWords,
      lastConfidence: lastConfidence ?? this.lastConfidence,
    );
  }
}

class VoiceCommandNotifier extends StateNotifier<VoiceCommandState> {
  VoiceCommandNotifier() : super(const VoiceCommandState());

  void setInitialized(bool value) {
    state = state.copyWith(isInitialized: value);
  }

  void setListening(bool value) {
    state = state.copyWith(isListening: value);
  }
}

final voiceCommandProvider =
    StateNotifierProvider<VoiceCommandNotifier, VoiceCommandState>((ref) {
  return VoiceCommandNotifier();
});
