import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VisionMode {
  navigation,
  objectSearch,
  signLanguage,
}

final visionModeProvider = StateProvider<VisionMode>((ref) {
  return VisionMode.navigation;
});
