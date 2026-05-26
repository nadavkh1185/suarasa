import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DisabilityMode {
  adaptive, // Satu mode otomatis: suara, visual, AI, dan haptic aktif bersama.
  hapticFocus,
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
          mode: DisabilityMode.adaptive,
          isHighContrast: false,
          textScaleFactor: 1.0,
        ));

  void setDisabilityMode(DisabilityMode mode) {
    double scale = 1.0;
    bool highContrast = state.isHighContrast;
    
    switch (mode) {
      case DisabilityMode.hapticFocus:
        scale = 1.4;
        highContrast = true;
        break;
      case DisabilityMode.adaptive:
        scale = 1.0;
        highContrast = false;
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

  void enableHapticFocus() {
    setDisabilityMode(DisabilityMode.hapticFocus);
  }

  void enableAdaptiveMode() {
    setDisabilityMode(DisabilityMode.adaptive);
  }

  void setTextScaleFactor(double factor) {
    state = state.copyWith(textScaleFactor: factor.clamp(1.0, 2.0));
  }
}

final accessibilityProvider =
    StateNotifierProvider<AccessibilityNotifier, AccessibilitySettings>((ref) {
  return AccessibilityNotifier();
});
