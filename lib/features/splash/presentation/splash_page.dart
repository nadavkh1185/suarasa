import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Navigate to Onboarding after a short delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go(AppRouter.onboarding);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHc = theme.colorScheme.surface == Colors.black;

    return Scaffold(
      body: Semantics(
        label: 'Halaman Memuat Aplikasi Suarasa',
        hint: 'Aplikasi sedang mempersiapkan sistem komunikasi inklusif.',
        focused: true,
        excludeSemantics: true,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: isHc
                ? null
                : LinearGradient(
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            color: isHc ? Colors.black : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Dynamic visual glow branding for normal dark mode, high contrast block style for high contrast
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isHc 
                            ? Colors.black 
                            : theme.colorScheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: isHc 
                            ? Border.all(color: theme.colorScheme.primary, width: 4)
                            : null,
                      ),
                      child: Icon(
                        Icons.settings_voice_rounded,
                        size: 80,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Suarasa',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Text(
                        'Komunikasi Inklusif Tanpa Batas',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isHc ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              SpinKitDoubleBounce(
                color: theme.colorScheme.secondary,
                size: 60.0,
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
