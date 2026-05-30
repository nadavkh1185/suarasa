import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

import '../../../core/providers/accessibility_provider.dart';
import '../../../core/providers/vision_mode_provider.dart';
import '../../../core/providers/voice_command_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/ai_demo_service.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/services/gemini_vision_service.dart';
import '../../../core/services/text_to_speech_service.dart';
import '../../../core/services/voice_command_service.dart';
import '../../../core/widgets/accessible_button.dart';
import '../../../core/widgets/custom_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final CameraService _cameraService = CameraService();
  final GeminiVisionService _geminiVisionService = GeminiVisionService();
  final TextToSpeechService _tts = TextToSpeechService();
  final VoiceCommandService _voiceCommandService = VoiceCommandService();
  final AiDemoService _aiDemo = const AiDemoService();
  final TextEditingController _quickTextController = TextEditingController();
  final TextEditingController _targetController = TextEditingController(text: 'kunci');
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  VoiceCommandController? _voiceCommandController;
  Timer? _shakeResolutionTimer;

  bool _speechReady = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isProcessingCommand = false;
  bool _isCameraReady = false;
  bool _isRecordingVideo = false;
  bool _isAnalyzingVision = false;
  bool _hasVibrator = false;
  double _motionLevel = 0;
  int _hapticSignals = 0;
  String _spokenCommand = 'Ucapkan nama menu atau kebutuhan.';
  String _aiMessage =
      'Gemini Vision siap untuk navigasi, pencarian objek, dan baca isyarat.';
  String _mediaStatus = 'Kamera belum aktif';
  String _visionStatus = 'Pilih Analisis sekitar, Cari objek, atau Baca isyarat.';
  DateTime? _lastShakeTime;
  int _shakeCount = 0;

  static const Duration _shakeDebounce = Duration(milliseconds: 1200);
  static const Duration _doubleShakeWindow = Duration(milliseconds: 2600);
  static const double _shakeThreshold = 21;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
    _initHaptic();
    _initCamera();
    _startMotionDetection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startVoiceCommandFlow();
    });
  }

  Future<void> _initTts() async {
    await _tts.initialize();
  }

  Future<void> _initSpeech() async {
    final ready = await _voiceCommandService.initialize();
    if (mounted) {
      setState(() => _speechReady = ready);
      ref.read(voiceCommandProvider.notifier).setInitialized(ready);
    }
  }

  Future<void> _initHaptic() async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (mounted) {
      setState(() => _hasVibrator = hasVibrator);
    }
  }

  Future<void> _initCamera() async {
    try {
      await _cameraService.initialize();

      setState(() {
        _isCameraReady = true;
        _mediaStatus = '${_cameraService.cameraLabel} siap';
      });
    } on CameraException catch (error) {
      if (mounted) {
        setState(() => _mediaStatus = error.description ?? 'Kamera perlu izin perangkat');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _mediaStatus = 'Kamera gagal dibuka: $error');
      }
    }
  }

  void _startMotionDetection() {
    _accelerometerSubscription =
        accelerometerEventStream().listen((AccelerometerEvent event) {
      final level = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (mounted) {
        setState(() => _motionLevel = level);
      }

      if (level > _shakeThreshold) {
        final now = DateTime.now();
        if (_lastShakeTime != null && now.difference(_lastShakeTime!) < _shakeDebounce) {
          return;
        }
        _lastShakeTime = now;
        _registerShakeDetected();
      }
    });
  }

  void _registerShakeDetected() {
    debugPrint('[Shake] detected');
    if (_isSpeaking || _isProcessingCommand || _isListening) {
      debugPrint('[Shake] ignored: system busy');
      return;
    }

    ref.read(accessibilityProvider.notifier).enableHapticFocus();
    _shakeCount += 1;
    _playHapticPattern([0, 80]);

    _shakeResolutionTimer?.cancel();
    _shakeResolutionTimer = Timer(_doubleShakeWindow, () async {
      final count = _shakeCount;
      _shakeCount = 0;
      if (!mounted) return;

      if (count >= 2) {
        debugPrint('[VoiceCommand] double shake matched: analyze navigation');
        await _playHapticPattern([0, 220, 80, 220]);
        await _analyzeNavigation();
      } else {
        debugPrint('[VoiceCommand] activated by shake');
        await _playHapticPattern([0, 120]);
        await _voiceCommandController?.listenNow(withPrompt: true);
      }
    });
  }

  Future<void> _listenForCommand() async {
    await _voiceCommandController?.listenNow(withPrompt: true);
  }

  Future<void> _stopListening() async {
    await _voiceCommandController?.stopListening();
    if (mounted) {
      setState(() => _isListening = false);
      ref.read(voiceCommandProvider.notifier).setListening(false);
    }
  }

  Future<void> _startVoiceCommandFlow() async {
    await _tts.initialize();
    _voiceCommandController ??= VoiceCommandController(
      service: _voiceCommandService,
      tts: _tts,
      onCommand: _executeVoiceCommand,
      onListeningChanged: (isListening) {
        if (!mounted) return;
        setState(() => _isListening = isListening);
        ref.read(voiceCommandProvider.notifier).setListening(isListening);
      },
      onSpeakingChanged: (isSpeaking) {
        if (!mounted) return;
        setState(() => _isSpeaking = isSpeaking);
      },
    );

    if (!_speechReady) {
      final ready = await _voiceCommandService.initialize();
      if (!mounted) return;
      setState(() => _speechReady = ready);
      ref.read(voiceCommandProvider.notifier).setInitialized(ready);
      if (!ready) {
        await _tts.speakAndWait('Izin mikrofon belum aktif. Periksa izin aplikasi Suarasa.');
        return;
      }
    }

    await _speak(VoiceCommandController.introPrompt);
  }

  Future<void> _executeVoiceCommand(VoiceCommand command) async {
    debugPrint('[VoiceCommand] executing command: ${command.type.name}');
    setState(() => _isProcessingCommand = true);
    setState(() {
      _spokenCommand = command.rawText;
    });

    try {
      switch (command.type) {
        case VoiceCommandType.navigation:
          await _analyzeNavigation();
          break;
        case VoiceCommandType.objectSearch:
          if (command.target != null && command.target!.isNotEmpty) {
            debugPrint('[VoiceCommand] object target: ${command.target}');
            _targetController.text = command.target!;
          }
          await _searchObject();
          break;
        case VoiceCommandType.signLanguage:
          await _readSignLanguage();
          break;
        case VoiceCommandType.frontCamera:
          await _useCamera(CameraLensDirection.front);
          await _speak('Kamera depan aktif.');
          break;
        case VoiceCommandType.backCamera:
          await _useCamera(CameraLensDirection.back);
          await _speak('Kamera belakang aktif.');
          break;
        case VoiceCommandType.stop:
          await _voiceCommandController?.stopListening();
          await _speak('Suarasa berhenti mendengarkan.');
          break;
        case VoiceCommandType.unknown:
          await _speak('Perintah belum dikenali. Goyangkan ponsel untuk mencoba lagi.');
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingCommand = false);
      }
    }
  }

  Future<void> _takePictureDemo() async {
    if (!_cameraService.isReady) {
      final result = _aiDemo.describeScene(hasCameraFrame: false);
      setState(() => _aiMessage = result.message);
      await _speak(result.message);
      return;
    }

    try {
      final file = await _cameraService.captureImage();
      final result = _aiDemo.describeScene(hasCameraFrame: true);
      setState(() {
        _mediaStatus = 'Foto demo tersimpan: ${file.name}';
        _aiMessage = result.message;
      });
      await _playHapticPattern(result.hapticPattern);
      await _speak(result.message);
    } catch (_) {
      setState(() => _mediaStatus = 'Foto demo belum berhasil');
    }
  }

  Future<void> _toggleVideoRecording() async {
    if (!_cameraService.isReady) {
      setState(() => _mediaStatus = 'Video perlu kamera aktif');
      return;
    }

    try {
      if (_isRecordingVideo) {
        final file = await _cameraService.startOrStopVideo();
        setState(() {
          _isRecordingVideo = false;
          _mediaStatus = 'Video demo tersimpan: ${file.name}';
        });
        await _playHapticPattern([0, 70, 70, 70]);
        await _speak('Rekaman video demo selesai.');
      } else {
        await _cameraService.startOrStopVideo();
      }
    } on CameraException catch (error) {
      if (error.code == 'recording_started') {
        setState(() {
          _isRecordingVideo = true;
          _mediaStatus = 'Sedang merekam video demo';
        });
        await _playHapticPattern([0, 180]);
        await _speak('Rekaman video demo dimulai.');
      } else {
        setState(() => _mediaStatus = error.description ?? 'Rekam video belum berhasil');
      }
    } catch (_) {
      setState(() => _mediaStatus = 'Rekam video belum berhasil');
    }
  }

  Future<void> _switchCamera() async {
    if (_isAnalyzingVision || _isRecordingVideo) return;

    try {
      setState(() {
        _isCameraReady = false;
        _mediaStatus = 'Mengganti kamera...';
      });
      await _cameraService.switchCamera();
      if (!mounted) return;
      setState(() {
        _isCameraReady = _cameraService.isReady;
        _mediaStatus = '${_cameraService.cameraLabel} siap';
      });
      await _playHapticPattern([0, 70]);
    } on CameraException catch (error) {
      setState(() => _mediaStatus = error.description ?? 'Gagal mengganti kamera');
    } catch (error) {
      setState(() => _mediaStatus = 'Gagal mengganti kamera: $error');
    }
  }

  Future<void> _useCamera(CameraLensDirection direction) async {
    if (_isAnalyzingVision || _isRecordingVideo) return;

    try {
      setState(() {
        _isCameraReady = false;
        _mediaStatus = 'Mengganti kamera...';
      });
      await _cameraService.useLens(direction);
      if (!mounted) return;
      setState(() {
        _isCameraReady = _cameraService.isReady;
        _mediaStatus = '${_cameraService.cameraLabel} siap';
      });
      await _playHapticPattern([0, 70]);
    } on CameraException catch (error) {
      setState(() => _mediaStatus = error.description ?? 'Gagal mengganti kamera');
    } catch (error) {
      setState(() => _mediaStatus = 'Gagal mengganti kamera: $error');
    }
  }

  Future<void> _analyzeNavigation() async {
    ref.read(visionModeProvider.notifier).state = VisionMode.navigation;
    await _runGeminiVision(
      mode: GeminiVisionMode.navigation,
      loadingMessage: 'Menganalisis jalan di sekitar...',
    );
  }

  Future<void> _searchObject() async {
    ref.read(visionModeProvider.notifier).state = VisionMode.objectSearch;
    await _runGeminiVision(
      mode: GeminiVisionMode.objectSearch,
      loadingMessage: 'Mencari ${_targetController.text.trim()}...',
    );
  }

  Future<void> _readSignLanguage() async {
    ref.read(visionModeProvider.notifier).state = VisionMode.signLanguage;
    if (_cameraService.lensDirection != CameraLensDirection.front) {
      await _cameraService.useLens(CameraLensDirection.front);
      if (mounted) {
        setState(() {
          _isCameraReady = _cameraService.isReady;
          _mediaStatus = '${_cameraService.cameraLabel} siap untuk isyarat';
        });
      }
    }
    await _runGeminiVision(
      mode: GeminiVisionMode.signLanguage,
      loadingMessage: 'Membaca gestur bahasa isyarat...',
    );
  }

  Future<void> _runGeminiVision({
    required GeminiVisionMode mode,
    required String loadingMessage,
  }) async {
    if (_isAnalyzingVision) return;
    if (!_cameraService.isReady) {
      await _initCamera();
      if (!_cameraService.isReady) {
        await _speak('Kamera belum siap. Periksa izin kamera.');
        return;
      }
    }

    setState(() {
      _isAnalyzingVision = true;
      _visionStatus = loadingMessage;
      _aiMessage = loadingMessage;
    });

    try {
      final image = await _cameraService.captureImage();
      final GeminiVisionResult result;
      switch (mode) {
        case GeminiVisionMode.navigation:
          result = await _geminiVisionService.analyzeNavigation(image);
          break;
        case GeminiVisionMode.objectSearch:
          result = await _geminiVisionService.searchObject(
            image: image,
            target: _targetController.text,
          );
          break;
        case GeminiVisionMode.signLanguage:
          result = await _geminiVisionService.readSignLanguage(image);
          break;
      }

      if (!mounted) return;
      setState(() {
        _mediaStatus = 'Frame dianalisis dari ${_cameraService.cameraLabel}';
        _visionStatus = _labelForMode(mode);
        _aiMessage = result.text;
      });
      await _playHapticPattern(result.isUrgent ? [0, 250, 90, 250] : [0, 90, 60, 90]);
      await _speak(result.text);
    } on StateError catch (error) {
      final message = error.message;
      setState(() {
        _visionStatus = 'Gemini belum siap';
        _aiMessage = message;
      });
      await _speak(message);
    } on CameraException catch (error) {
      final message = error.description ?? 'Kamera gagal mengambil gambar.';
      setState(() {
        _visionStatus = 'Kamera bermasalah';
        _aiMessage = message;
      });
      await _speak(message);
    } catch (error) {
      final message = 'Analisis gagal. Periksa koneksi internet dan coba lagi.';
      setState(() {
        _visionStatus = 'Analisis gagal';
        _aiMessage = '$message ($error)';
      });
      await _speak(message);
    } finally {
      if (mounted) {
        setState(() => _isAnalyzingVision = false);
      }
    }
  }

  String _labelForMode(GeminiVisionMode mode) {
    switch (mode) {
      case GeminiVisionMode.navigation:
        return 'Navigasi tunanetra';
      case GeminiVisionMode.objectSearch:
        return 'Pencarian objek';
      case GeminiVisionMode.signLanguage:
        return 'Baca bahasa isyarat';
    }
  }

  Future<void> _playHapticPattern(List<int> pattern) async {
    setState(() => _hapticSignals += 1);
    if (_hasVibrator) {
      await Vibration.vibrate(pattern: pattern);
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _speak(String text) async {
    if (mounted) {
      setState(() => _isSpeaking = true);
    }
    try {
      await _tts.speakAndWait(text);
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _shakeResolutionTimer?.cancel();
    _voiceCommandController?.dispose();
    _cameraService.dispose();
    _quickTextController.dispose();
    _targetController.dispose();
    _voiceCommandService.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(accessibilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suarasa'),
        actions: [
          IconButton(
            tooltip: 'Kalibrasi',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.go(AppRouter.modeSelector),
          ),
          IconButton(
            tooltip: 'Haptic fokus',
            icon: Icon(
              settings.mode == DisabilityMode.hapticFocus
                  ? Icons.vibration_rounded
                  : Icons.vibration_outlined,
            ),
            onPressed: () {
              final notifier = ref.read(accessibilityProvider.notifier);
              if (settings.mode == DisabilityMode.hapticFocus) {
                notifier.enableAdaptiveMode();
              } else {
                notifier.enableHapticFocus();
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF7FF), Color(0xFFCDEBFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 720 ? 24.0 : 16.0;
              final maxContentWidth = constraints.maxWidth >= 980 ? 920.0 : double.infinity;

              return ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 14,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Column(
                        children: [
                          _buildHero(theme),
                          const SizedBox(height: 14),
                          _buildSignalGrid(theme),
                          const SizedBox(height: 14),
                          _buildVisionActions(theme),
                          const SizedBox(height: 14),
                          _buildCameraDemo(theme),
                          const SizedBox(height: 14),
                          _buildAiPanel(theme),
                          const SizedBox(height: 14),
                          _buildQuickSpeak(theme),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHero(ThemeData theme) {
    return CustomCard(
      semanticLabel: 'Dashboard Suarasa terpadu',
      gradient: const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFE8F8FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.16),
                  theme.colorScheme.secondary.withValues(alpha: 0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.settings_voice_rounded,
              color: theme.colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bantuan adaptif aktif',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Suara, kamera, AI, dan getaran bekerja dalam satu layar.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalGrid(ThemeData theme) {
    final motionText = _motionLevel.toStringAsFixed(1);
    final actions = [
      _ActionTileData(
        icon: _isListening ? Icons.hearing_rounded : Icons.mic_rounded,
        label: _isListening ? 'Mendengar' : 'Perintah',
        value: _speechReady ? 'Siap' : 'Izin mic',
        colors: const [Color(0xFFFFF4D8), Color(0xFFFFE7A3)],
        onTap: _isListening ? _stopListening : _listenForCommand,
      ),
      _ActionTileData(
        icon: Icons.photo_camera_rounded,
        label: 'Foto',
        value: _isCameraReady ? 'Siap' : 'Izin kamera',
        colors: const [Color(0xFFE5F5FF), Color(0xFFBFE7FF)],
        onTap: _takePictureDemo,
      ),
      _ActionTileData(
        icon: _isRecordingVideo ? Icons.stop_circle_rounded : Icons.videocam_rounded,
        label: 'Video',
        value: _isRecordingVideo ? 'Rekam' : 'Demo',
        colors: const [Color(0xFFEAFBEF), Color(0xFFC6F2D7)],
        onTap: _toggleVideoRecording,
      ),
      _ActionTileData(
        icon: Icons.vibration_rounded,
        label: 'Haptic',
        value: 'Gerak $motionText',
        colors: const [Color(0xFFF3ECFF), Color(0xFFDCCBFF)],
        onTap: () => _playHapticPattern([0, 100, 80, 220]),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = constraints.maxWidth >= 600 ? 14.0 : 12.0;
        final columnCount = constraints.maxWidth >= 840 ? 4 : 2;
        final itemWidth =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in actions)
              SizedBox(
                width: itemWidth,
                child: _ActionTile(
                  icon: action.icon,
                  label: action.label,
                  value: action.value,
                  colors: action.colors,
                  onTap: action.onTap,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildVisionActions(ThemeData theme) {
    final visionMode = ref.watch(visionModeProvider);

    return CustomCard(
      semanticLabel: 'Kontrol Gemini Vision untuk navigasi dan bahasa isyarat',
      gradient: const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFEAF8FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.center_focus_strong_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gemini Vision',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _visionStatus,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Ganti kamera depan atau belakang',
                onPressed: _isAnalyzingVision ? null : _switchCamera,
                icon: const Icon(Icons.cameraswitch_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _targetController,
            enabled: !_isAnalyzingVision,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Target objek, contoh: kunci, pintu, kursi',
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 12),
          if (_isAnalyzingVision)
            LinearProgressIndicator(
              minHeight: 6,
              borderRadius: BorderRadius.circular(99),
            ),
          if (_isAnalyzingVision) const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final buttonWidth =
                  isWide ? (constraints.maxWidth - 20) / 3 : constraints.maxWidth;
              final buttons = [
                _VisionButtonData(
                  label: 'Analisis sekitar',
                  icon: Icons.directions_walk_rounded,
                  active: visionMode == VisionMode.navigation,
                  onPressed: _analyzeNavigation,
                ),
                _VisionButtonData(
                  label: 'Cari objek',
                  icon: Icons.manage_search_rounded,
                  active: visionMode == VisionMode.objectSearch,
                  onPressed: _searchObject,
                ),
                _VisionButtonData(
                  label: 'Baca isyarat',
                  icon: Icons.sign_language_rounded,
                  active: visionMode == VisionMode.signLanguage,
                  onPressed: _readSignLanguage,
                ),
              ];

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final button in buttons)
                    SizedBox(
                      width: buttonWidth,
                      child: AccessibleButton(
                        label: button.label,
                        icon: button.icon,
                        minHeight: 50,
                        backgroundColor: button.active
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                        onPressed: _isAnalyzingVision ? () {} : button.onPressed,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCameraDemo(ThemeData theme) {
    final controller = _cameraService.controller;
    return CustomCard(
      semanticLabel: 'Demo kamera. $_mediaStatus',
      gradient: const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFEAF8FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image_search_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _mediaStatus,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _cameraService.cameraLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final aspectRatio = constraints.maxWidth < 520 ? 4 / 3 : 16 / 9;

              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: controller != null && _cameraService.isReady
                      ? CameraPreview(controller)
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withValues(alpha: 0.08),
                                theme.colorScheme.secondary.withValues(alpha: 0.12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAiPanel(ThemeData theme) {
    return CustomCard(
      semanticLabel: 'Panel AI. Perintah terakhir: $_spokenCommand',
      gradient: const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF4F0FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI demo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$_hapticSignals sinyal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _spokenCommand,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _aiMessage,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSpeak(ThemeData theme) {
    return CustomCard(
      semanticLabel: 'Alat bicara cepat',
      gradient: const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFEFFBF8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          TextField(
            controller: _quickTextController,
            decoration: const InputDecoration(
              hintText: 'Ketik kalimat untuk dibacakan',
            ),
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          AccessibleButton(
            label: 'BACAKAN',
            icon: Icons.volume_up_rounded,
            onPressed: () {
              final text = _quickTextController.text.trim();
              if (text.isNotEmpty) {
                _speak(text);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      semanticLabel: '$label, $value',
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: 22,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.70),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTileData {
  const _ActionTileData({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<Color> colors;
  final VoidCallback onTap;
}

class _VisionButtonData {
  const _VisionButtonData({
    required this.label,
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;
}
