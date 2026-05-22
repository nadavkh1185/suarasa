import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../core/providers/accessibility_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/accessible_button.dart';
import '../../../core/widgets/custom_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final FlutterTts _flutterTts = FlutterTts();
  StreamSubscription? _accelerometerSubscription;
  DateTime? _lastShakeTime;
  
  // Shake detection thresholds
  static const double shakeThreshold = 18.0; 
  static const Duration shakeCooldown = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _initTts();
    _startShakeDetection();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('id-ID'); // Indonesian language
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
  }

  void _startShakeDetection() {
    // Listen to accelerometer stream to catch sudden movements
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      final double acceleration = event.x.abs() + event.y.abs() + event.z.abs();
      
      if (acceleration > shakeThreshold) {
        final now = DateTime.now();
        if (_lastShakeTime == null || now.difference(_lastShakeTime!) > shakeCooldown) {
          _lastShakeTime = now;
          _onShakeDetected();
        }
      }
    });
  }

  void _onShakeDetected() {
    // Trigger heavy vibration
    HapticFeedback.heavyImpact();
    
    // Announce to user that system is listening
    _speak('Goyangan terdeteksi. Sistem asisten suara Suarasa siap mendengarkan.');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Goyangan terdeteksi! Mikrofon siap menerima perintah.'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(accessibilityProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suarasa Dashboard'),
        actions: [
          IconButton(
            icon: Icon(
              settings.isHighContrast ? Icons.lens : Icons.lens_outlined,
              semanticLabel: 'Ubah Kontras Tema',
            ),
            onPressed: () {
              ref.read(accessibilityProvider.notifier).toggleHighContrast();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_accessibility, semanticLabel: 'Pilih Mode Disabilitas'),
            onPressed: () => context.go(AppRouter.modeSelector),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Widget
              _buildHeaderCard(settings),
              const SizedBox(height: 16),
              
              // Dynamic Mode Layout
              Expanded(
                child: _buildLayoutForMode(settings.mode, theme),
              ),
              
              const SizedBox(height: 12),
              // Footer Configuration Card
              _buildQuickSettingsCard(settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(AccessibilitySettings settings) {
    String message = 'Halo, Selamat Datang';
    switch (settings.mode) {
      case DisabilityMode.tunanetra:
        message = 'Halo. Mode Tunanetra Aktif. Goyang ponsel untuk bantuan.';
        break;
      case DisabilityMode.tunarungu:
        message = 'Halo. Mode Tunarungu Aktif. Suara sekitar dideteksi.';
        break;
      case DisabilityMode.tunawicara:
        message = 'Halo. Mode Tunawicara Aktif. Ketuk untuk berbicara.';
        break;
      case DisabilityMode.ganda:
        message = 'Halo. Mode Disabilitas Ganda Aktif. Umpan balik haptic.';
        break;
      default:
        break;
    }

    return CustomCard(
      backgroundColor: settings.isHighContrast ? Colors.black : Colors.indigo.withValues(alpha: 0.1),
      semanticLabel: message,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          if (settings.mode == DisabilityMode.tunanetra) ...[
            const SizedBox(height: 8),
            const Text(
              'Instruksi: Goyangkan perangkat ke kiri/kanan untuk mengambil gambar dan mendeskripsikan kondisi sekitar secara otomatis.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLayoutForMode(DisabilityMode mode, ThemeData theme) {
    switch (mode) {
      case DisabilityMode.tunanetra:
        return _buildTunanetraLayout(theme);
      case DisabilityMode.tunarungu:
        return _buildTunarunguLayout(theme);
      case DisabilityMode.tunawicara:
        return _buildTunawicaraLayout(theme);
      case DisabilityMode.ganda:
        return _buildGandaLayout(theme);
      default:
        return _buildNormalLayout(theme);
    }
  }

  // --- 1. Tunanetra Layout (Giant Audio and Visual triggers) ---
  Widget _buildTunanetraLayout(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: CustomCard(
            onTap: () {
              _speak('Mengambil gambar di depan Anda. Mengirim ke Gemini AI untuk dianalisis.');
            },
            semanticLabel: 'Tombol Besar: Ambil Foto & Analisis Lingkungan',
            semanticHint: 'Klik dua kali untuk mengambil gambar sekitar dan mendengarkan penjelasan AI.',
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_enhance_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'DETEKSI SEKITAR',
                    style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text('Ketuk untuk merekam & menceritakan lingkungan Anda', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AccessibleButton(
          label: 'MULAI ASISTEN SUARA',
          onPressed: () {
            _speak('Asisten suara diaktifkan. Silakan ucapkan pertanyaan Anda setelah getaran.');
            HapticFeedback.vibrate();
          },
          icon: Icons.mic_rounded,
        ),
      ],
    );
  }

  // --- 2. Tunarungu Layout (Real-time sound level & transcription prompt) ---
  Widget _buildTunarunguLayout(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: CustomCard(
            semanticLabel: 'Indikator Kebisingan Lingkungan: Normal',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.volume_up_rounded, size: 48, color: Colors.green),
                const SizedBox(height: 12),
                Text(
                  'Kebisingan: Normal (45 dB)',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Sistem mendengarkan sirine atau alarm darurat di sekitar Anda.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 3,
          child: CustomCard(
            semanticLabel: 'Mulai Transkripsi Kalimat Bicara',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.subtitles_rounded, size: 54, color: theme.colorScheme.secondary),
                const SizedBox(height: 12),
                Text(
                  'Transkripsi Suara',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Klik tombol di bawah untuk menampilkan teks perkataan orang lain di sekitar secara langsung.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AccessibleButton(
          label: 'MULAI TRANSKRIPSI',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Memulai perekam mikrofon untuk teks real-time...')),
            );
          },
          icon: Icons.play_arrow_rounded,
        ),
      ],
    );
  }

  // --- 3. Tunawicara Layout (AAC Presets & TTS text input) ---
  Widget _buildTunawicaraLayout(ThemeData theme) {
    final TextEditingController textController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Text Input area
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Ketik apa yang ingin Anda bicarakan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: 'Suarakan teks input',
              button: true,
              child: InkWell(
                onTap: () {
                  if (textController.text.isNotEmpty) {
                    _speak(textController.text);
                  }
                },
                child: Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.volume_up_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Preset Komunikasi Cepat (AAC)',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildAacCard('Tolong bantu saya', 'Saya memerlukan pertolongan', theme),
              _buildAacCard('Di mana toilet?', 'Tolong tunjukkan lokasi kamar mandi', theme),
              _buildAacCard('Saya lapar & haus', 'Saya butuh makan atau minum', theme),
              _buildAacCard('Ya', 'Jawaban ya', theme),
              _buildAacCard('Tidak', 'Jawaban tidak', theme),
              _buildAacCard('Terima kasih banyak', 'Ungkapan terima kasih', theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAacCard(String speakText, String semanticLabel, ThemeData theme) {
    return CustomCard(
      onTap: () => _speak(speakText),
      semanticLabel: 'Tombol Bicara: $speakText. $semanticLabel',
      backgroundColor: theme.colorScheme.surface,
      child: Center(
        child: Text(
          speakText,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // --- 4. Disabilitas Ganda Layout (Haptic instructions & Tap trigger) ---
  Widget _buildGandaLayout(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: CustomCard(
            onTap: () {
              // Pulse short haptic vibration
              HapticFeedback.lightImpact();
              Future.delayed(const Duration(milliseconds: 150), () => HapticFeedback.lightImpact());
            },
            semanticLabel: 'Area Sentuh Utama. Menghasilkan Getaran Ketukan Pendek.',
            backgroundColor: Colors.grey.shade900,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.vibration_rounded, size: 80, color: Colors.amber),
                  SizedBox(height: 20),
                  Text(
                    'GETARAN DUA KETUKAN (YA)',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: CustomCard(
            onTap: () {
              HapticFeedback.heavyImpact();
            },
            semanticLabel: 'Area Sentuh Kedua. Menghasilkan Getaran Keras Panjang.',
            backgroundColor: Colors.red.shade900,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_rounded, size: 80, color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'GETARAN PANJANG (TIDAK/ALERT)',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 5. Normal standard responsive layout ---
  Widget _buildNormalLayout(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Asisten Aksesibilitas Suarasa',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Suarasa membantu menyetarakan interaksi sosial dengan teknologi pendeteksi visual Gemini AI, konversi teks suara cerdas, dan detektor sensor goyangan.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: CustomCard(
                onTap: () => ref.read(accessibilityProvider.notifier).setDisabilityMode(DisabilityMode.tunanetra),
                child: const Column(
                  children: [
                    Icon(Icons.visibility_off_rounded, size: 36, color: Colors.orange),
                    SizedBox(height: 8),
                    Text('Tunanetra', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomCard(
                onTap: () => ref.read(accessibilityProvider.notifier).setDisabilityMode(DisabilityMode.tunarungu),
                child: const Column(
                  children: [
                    Icon(Icons.hearing_disabled_rounded, size: 36, color: Colors.blue),
                    SizedBox(height: 8),
                    Text('Tunarungu', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomCard(
                onTap: () => ref.read(accessibilityProvider.notifier).setDisabilityMode(DisabilityMode.tunawicara),
                child: const Column(
                  children: [
                    Icon(Icons.record_voice_over_rounded, size: 36, color: Colors.teal),
                    SizedBox(height: 8),
                    Text('Tunawicara', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomCard(
                onTap: () => ref.read(accessibilityProvider.notifier).setDisabilityMode(DisabilityMode.ganda),
                child: const Column(
                  children: [
                    Icon(Icons.fingerprint_rounded, size: 36, color: Colors.purple),
                    SizedBox(height: 8),
                    Text('Ganda', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickSettingsCard(AccessibilitySettings settings) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skala Font: ${settings.textScaleFactor.toStringAsFixed(1)}x',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Mode: ${settings.mode.name.toUpperCase()}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  ref.read(accessibilityProvider.notifier).setTextScaleFactor(settings.textScaleFactor - 0.1);
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  ref.read(accessibilityProvider.notifier).setTextScaleFactor(settings.textScaleFactor + 0.1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
