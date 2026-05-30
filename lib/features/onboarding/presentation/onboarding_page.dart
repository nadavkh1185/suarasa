import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/accessible_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _slides = [
    const OnboardingItem(
      icon: Icons.graphic_eq_rounded,
      title: 'Suara & Getaran',
      description: 'Dengarkan percakapan lewat teks, atau ketik teks untuk dilafalkan keras oleh sistem kami.',
    ),
    const OnboardingItem(
      icon: Icons.edgesensor_high_rounded,
      title: 'Deteksi Goyang',
      description: 'Goyangkan ponsel Anda kapan saja untuk langsung mengaktifkan asisten AI suara otomatis.',
    ),
    const OnboardingItem(
      icon: Icons.remove_red_eye_rounded,
      title: 'Analisis Visual Gemini',
      description: 'Ponsel Anda akan menjadi mata kedua Anda. Mengidentifikasi barang, teks, dan situasi sekitar.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHc = theme.colorScheme.primary.value == const Color(0xFF062947).value;

    return Scaffold(
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
              final horizontalPadding = constraints.maxWidth >= 720 ? 32.0 : 20.0;
              final iconSize = constraints.maxHeight < 640 ? 52.0 : 64.0;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 14,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Semantics(
                        label: 'Lewati panduan',
                        button: true,
                        child: TextButton(
                          onPressed: () => context.go(AppRouter.home),
                          child: Text(
                            'LEWATI',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontSize: isHc ? 16 : 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: _slides.length,
                        itemBuilder: (context, index) {
                          final item = _slides[index];
                          return Semantics(
                            label:
                                'Panduan ${_currentPage + 1} dari ${_slides.length}. ${item.title}: ${item.description}',
                            excludeSemantics: true,
                            child: SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: max(280.0, constraints.maxHeight - 190),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(22),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0.95),
                                            theme.colorScheme.primary.withValues(alpha: 0.10),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        border: isHc
                                            ? Border.all(
                                                color: theme.colorScheme.primary,
                                                width: 2,
                                              )
                                            : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.primary.withValues(alpha: 0.10),
                                            blurRadius: 22,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        item.icon,
                                        size: iconSize,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    Text(
                                      item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.displaySmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: theme.colorScheme.primary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      item.description,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: _currentPage == index ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: isHc && _currentPage == index
                                ? Border.all(color: Colors.white, width: 1)
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AccessibleButton(
                      label: _currentPage == _slides.length - 1
                          ? 'MULAI SEKARANG'
                          : 'SELANJUTNYA',
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          context.go(AppRouter.home);
                        }
                      },
                      semanticLabel: _currentPage == _slides.length - 1
                          ? 'Lanjutkan ke dashboard Suarasa'
                          : 'Lanjut ke halaman berikutnya',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class OnboardingItem {
  final IconData icon;
  final String title;
  final String description;

  const OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
