import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:vibration/vibration.dart';

import '../../../core/providers/accessibility_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/ai_demo_service.dart';
import '../../../core/widgets/accessible_button.dart';
import '../../../core/widgets/custom_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AiDemoService _aiDemo = const AiDemoService();
  final TextEditingController _quickTextController = TextEditingController();

  CameraController? _cameraController;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  bool _speechReady = false;
  bool _isListening = false;
  bool _isCameraReady = false;
  bool _isRecordingVideo = false;
  bool _hasVibrator = false;
  double _motionLevel = 0;
  int _hapticSignals = 0;
  String _spokenCommand = 'Ucapkan nama menu atau kebutuhan.';
  String _aiMessage =
      'AI demo siap membantu memilih aksi dari suara, kamera, dan sensor gerak.';
  String _mediaStatus = 'Kamera belum aktif';
  DateTime? _lastShakeTime;

  static const Duration _shakeCooldown = Duration(seconds: 2);
  static const double _shakeThreshold = 21;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
    _initHaptic();
    _initCamera();
    _startMotionDetection();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('id-ID');
    await _tts.setPitch(1);
    await _tts.setSpeechRate(0.48);
  }

  Future<void> _initSpeech() async {
    final ready = await _speech.initialize();
    if (mounted) {
      setState(() => _speechReady = ready);
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
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _mediaStatus = 'Kamera tidak ditemukan');
        return;
      }

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
        _mediaStatus = 'Kamera siap untuk foto dan video demo';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _mediaStatus = 'Kamera perlu izin perangkat');
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
        if (_lastShakeTime == null ||
            now.difference(_lastShakeTime!) > _shakeCooldown) {
          _lastShakeTime = now;
          _onShakeDetected();
        }
      }
    });
  }

  Future<void> _onShakeDetected() async {
    ref.read(accessibilityProvider.notifier).enableHapticFocus();
    await _playHapticPattern([0, 120, 90, 240]);
    await _speak(
      'Goyangan terdeteksi. Mode haptic fokus aktif. Ucapkan menu yang ingin dibuka.',
    );
    if (!_isListening) {
      await _listenForCommand();
    }
  }

  Future<void> _listenForCommand() async {
    if (!_speechReady) {
      await _speak('Perekam suara belum siap. Periksa izin mikrofon.');
      return;
    }

    setState(() => _isListening = true);
    await _playHapticPattern([0, 80]);
    await _speech.listen(
      localeId: 'id_ID',
      listenMode: stt.ListenMode.confirmation,
      onResult: (result) async {
        if (!result.finalResult) return;
        final text = result.recognizedWords.trim();
        if (text.isEmpty) return;
        await _handleCommand(text);
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  Future<void> _handleCommand(String text) async {
    await _stopListening();
    final result = _aiDemo.understandCommand(text);
    setState(() {
      _spokenCommand = text;
      _aiMessage = result.message;
    });
    await _playHapticPattern(result.hapticPattern);
    await _speak(result.message);

    final lower = text.toLowerCase();
    if (lower.contains('kamera') ||
        lower.contains('foto') ||
        lower.contains('gambar') ||
        lower.contains('lihat')) {
      await _takePictureDemo();
    } else if (lower.contains('video') || lower.contains('rekam')) {
      await _toggleVideoRecording();
    }
  }

  Future<void> _takePictureDemo() async {
    final controller = _cameraController;
    if (controller == null || !_isCameraReady || controller.value.isTakingPicture) {
      final result = _aiDemo.describeScene(hasCameraFrame: false);
      setState(() => _aiMessage = result.message);
      await _speak(result.message);
      return;
    }

    try {
      final file = await controller.takePicture();
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
    final controller = _cameraController;
    if (controller == null || !_isCameraReady) {
      setState(() => _mediaStatus = 'Video perlu kamera aktif');
      return;
    }

    try {
      if (_isRecordingVideo) {
        final file = await controller.stopVideoRecording();
        setState(() {
          _isRecordingVideo = false;
          _mediaStatus = 'Video demo tersimpan: ${file.name}';
        });
        await _playHapticPattern([0, 70, 70, 70]);
        await _speak('Rekaman video demo selesai.');
      } else {
        await controller.startVideoRecording();
        setState(() {
          _isRecordingVideo = true;
          _mediaStatus = 'Sedang merekam video demo';
        });
        await _playHapticPattern([0, 180]);
        await _speak('Rekaman video demo dimulai.');
      }
    } catch (_) {
      setState(() => _mediaStatus = 'Rekam video belum berhasil');
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
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _cameraController?.dispose();
    _quickTextController.dispose();
    _speech.stop();
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
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEAF7FF), Color(0xFFCDEBFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHero(theme),
              const SizedBox(height: 14),
              _buildSignalGrid(theme),
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
    );
  }

  Widget _buildHero(ThemeData theme) {
    return CustomCard(
      semanticLabel: 'Dashboard Suarasa terpadu',
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.settings_voice_rounded,
              color: theme.colorScheme.primary,
              size: 42,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bantuan adaptif aktif',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Suara, kamera, AI, dan getaran bekerja dalam satu layar.',
                  style: theme.textTheme.bodyMedium,
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.08,
      children: [
        _ActionTile(
          icon: _isListening ? Icons.hearing_rounded : Icons.mic_rounded,
          label: _isListening ? 'Mendengar' : 'Perintah',
          value: _speechReady ? 'Siap' : 'Izin mic',
          onTap: _isListening ? _stopListening : _listenForCommand,
        ),
        _ActionTile(
          icon: Icons.photo_camera_rounded,
          label: 'Foto',
          value: _isCameraReady ? 'Siap' : 'Izin kamera',
          onTap: _takePictureDemo,
        ),
        _ActionTile(
          icon: _isRecordingVideo ? Icons.stop_circle_rounded : Icons.videocam_rounded,
          label: 'Video',
          value: _isRecordingVideo ? 'Rekam' : 'Demo',
          onTap: _toggleVideoRecording,
        ),
        _ActionTile(
          icon: Icons.vibration_rounded,
          label: 'Haptic',
          value: 'Gerak $motionText',
          onTap: () => _playHapticPattern([0, 100, 80, 220]),
        ),
      ],
    );
  }

  Widget _buildCameraDemo(ThemeData theme) {
    final controller = _cameraController;
    return CustomCard(
      semanticLabel: 'Demo kamera. $_mediaStatus',
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: controller != null && _isCameraReady
                  ? CameraPreview(controller)
                  : Container(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiPanel(ThemeData theme) {
    return CustomCard(
      semanticLabel: 'Panel AI. Perintah terakhir: $_spokenCommand',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                'AI demo',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '$_hapticSignals sinyal',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _spokenCommand,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(_aiMessage, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildQuickSpeak(ThemeData theme) {
    return CustomCard(
      semanticLabel: 'Alat bicara cepat',
      child: Column(
        children: [
          TextField(
            controller: _quickTextController,
            decoration: const InputDecoration(
              hintText: 'Ketik kalimat untuk dibacakan',
              border: OutlineInputBorder(),
            ),
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      semanticLabel: '$label, $value',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 42, color: theme.colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
