import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DisabilityMode {
  normal,      // Standard responsive UI
  tunanetra,   // Visually Impaired: Large text, voice alerts, shake to activate AI vision
  tunarungu,   // Hearing Impaired: Audio level alerts, high-readability transcription
  tunawicara,  // Speech Impaired: Quick AAC presets + Text-to-Speech tool
  ganda        // Deaf-Blind / Double: Specialized haptic guides & Morse input
}

class AccessibilitySettings {
  final DisabilityMode mode;
  final bool isHighContrast;
  final double textScaleFactor;

  const AccessibilitySettings({
    required this.mode,
    required this.isHighContrast,
    required this.textScaleFactor,
  });

  AccessibilitySettings copyWith({
    DisabilityMode? mode,
    bool? isHighContrast,
    double? textScaleFactor,
  }) {
    return AccessibilitySettings(
      mode: mode ?? this.mode,
      isHighContrast: isHighContrast ?? this.isHighContrast,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
    );
  }
}

class AccessibilityNotifier extends StateNotifier<AccessibilitySettings> {
  AccessibilityNotifier()
      : super(const AccessibilitySettings(
          mode: DisabilityMode.normal,
          isHighContrast: false,
          textScaleFactor: 1.0,
        ));

  void setDisabilityMode(DisabilityMode mode) {
    double scale = 1.0;
    bool highContrast = state.isHighContrast;
    
    // Auto-configure optimal settings based on mode
    switch (mode) {
      case DisabilityMode.tunanetra:
        scale = 1.3;
        highContrast = true; // Auto-enable high contrast for visually impaired
        break;
      case DisabilityMode.tunarungu:
        scale = 1.2;
        break;
      case DisabilityMode.tunawicara:
        scale = 1.1;
        break;
      case DisabilityMode.ganda:
        scale = 1.4;
        highContrast = true;
        break;
      case DisabilityMode.normal:
        scale = 1.0;
        break;
    }

    state = state.copyWith(
      mode: mode,
      textScaleFactor: scale,
      isHighContrast: highContrast,
    );
  }

  void toggleHighContrast() {
    state = state.copyWith(isHighContrast: !state.isHighContrast);
  }

  void setTextScaleFactor(double factor) {
    state = state.copyWith(textScaleFactor: factor.clamp(1.0, 2.0));
  }
}

final accessibilityProvider =
    StateNotifierProvider<AccessibilityNotifier, AccessibilitySettings>((ref) {
  return AccessibilityNotifier();
});
