import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/accessibility_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/accessible_button.dart';

class ModeSelectorPage extends ConsumerWidget {
  const ModeSelectorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentSettings = ref.watch(accessibilityProvider);
    final isHc = currentSettings.isHighContrast;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Mode Akses'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sesuaikan Suarasa',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: isHc ? 30 : 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih opsi yang paling membantu cara Anda berkomunikasi.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _buildModeCard(
                      context,
                      ref: ref,
                      mode: DisabilityMode.tunanetra,
                      icon: Icons.visibility_off_rounded,
                      title: 'Tunanetra',
                      description: 'Kontras tinggi otomatis, instruksi berbasis suara, dan asisten kamera AI.',
                      isActive: currentSettings.mode == DisabilityMode.tunanetra,
                    ),
                    const SizedBox(height: 16),
                    _buildModeCard(
                      context,
                      ref: ref,
                      mode: DisabilityMode.tunarungu,
                      icon: Icons.hearing_disabled_rounded,
                      title: 'Tunarungu',
                      description: 'Transkripsi audio real-time dan peringatan getar saat ada bahaya sekitar.',
                      isActive: currentSettings.mode == DisabilityMode.tunarungu,
                    ),
                    const SizedBox(height: 16),
                    _buildModeCard(
                      context,
                      ref: ref,
                      mode: DisabilityMode.tunawicara,
                      icon: Icons.record_voice_over_rounded,
                      title: 'Tunawicara',
                      description: 'Ketik cepat atau pilih kata preset agar sistem melafalkannya untuk Anda.',
                      isActive: currentSettings.mode == DisabilityMode.tunawicara,
                    ),
                    const SizedBox(height: 16),
                    _buildModeCard(
                      context,
                      ref: ref,
                      mode: DisabilityMode.ganda,
                      icon: Icons.fingerprint_rounded,
                      title: 'Disabilitas Ganda',
                      description: 'Navigasi getaran penuh (haptic guides) & kode ketukan untuk deaf-blind.',
                      isActive: currentSettings.mode == DisabilityMode.ganda,
                    ),
                    const SizedBox(height: 16),
                    _buildModeCard(
                      context,
                      ref: ref,
                      mode: DisabilityMode.normal,
                      icon: Icons.accessibility_new_rounded,
                      title: 'Mode Umum',
                      description: 'Antarmuka standar yang responsif dan bersih dengan dukungan dark mode.',
                      isActive: currentSettings.mode == DisabilityMode.normal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AccessibleButton(
                label: 'SELESAI & MASUK',
                onPressed: () {
                  context.go(AppRouter.home);
                },
                semanticLabel: 'Selesai memilih mode, masuk ke halaman utama',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required WidgetRef ref,
    required DisabilityMode mode,
    required IconData icon,
    required String title,
    required String description,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final isHc = theme.colorScheme.surface == Colors.black;



    return CustomCard(
      onTap: () {
        ref.read(accessibilityProvider.notifier).setDisabilityMode(mode);
      },
      backgroundColor: isActive
          ? (isHc ? Colors.black : theme.colorScheme.primary.withOpacity(0.08))
          : null,
      semanticLabel: '$title. ${isActive ? 'Sedang aktif.' : ''} $description',
      semanticHint: 'Klik dua kali untuk memilih mode ini',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: isActive ? (isHc ? Colors.black : Colors.white) : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    if (isActive)
                      Icon(
                        Icons.check_circle_rounded,
                        color: theme.colorScheme.secondary,
                        size: 24,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
