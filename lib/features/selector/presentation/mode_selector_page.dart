import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/accessibility_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/accessible_button.dart';
import '../../../core/widgets/custom_card.dart';

class ModeSelectorPage extends ConsumerWidget {
  const ModeSelectorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(accessibilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalibrasi Akses'),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Suarasa menyesuaikan bantuan secara otomatis.',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _SignalCard(
                        icon: Icons.mic_rounded,
                        label: 'Suara',
                        onTap: () => HapticFeedback.lightImpact(),
                      ),
                      _SignalCard(
                        icon: Icons.camera_alt_rounded,
                        label: 'Visual',
                        onTap: () => HapticFeedback.mediumImpact(),
                      ),
                      _SignalCard(
                        icon: Icons.vibration_rounded,
                        label: 'Haptic',
                        onTap: () {
                          ref.read(accessibilityProvider.notifier).enableHapticFocus();
                          HapticFeedback.heavyImpact();
                        },
                        active: settings.mode == DisabilityMode.hapticFocus,
                      ),
                      _SignalCard(
                        icon: Icons.auto_awesome_rounded,
                        label: 'AI',
                        onTap: () => HapticFeedback.selectionClick(),
                      ),
                    ],
                  ),
                ),
                AccessibleButton(
                  label: 'MASUK DASHBOARD',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => context.go(AppRouter.home),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomCard(
      onTap: onTap,
      semanticLabel: '$label siap digunakan',
      backgroundColor:
          active ? theme.colorScheme.primary.withValues(alpha: 0.12) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 46, color: theme.colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
