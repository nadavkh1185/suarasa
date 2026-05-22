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
    final isHc = theme.colorScheme.surface == Colors.black;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Bottom Skip Button
              Align(
                alignment: Alignment.topRight,
                child: Semantics(
                  label: 'Lewati panduan',
                  button: true,
                  child: TextButton(
                    onPressed: () => context.go(AppRouter.modeSelector),
                    child: Text(
                      'LEWATI',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontSize: isHc ? 18 : 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Slide Viewport
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
                      label: 'Panduan ${_currentPage + 1} dari ${_slides.length}. ${item.title}: ${item.description}',
                      excludeSemantics: true,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: isHc 
                                  ? Colors.black 
                                  : theme.colorScheme.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                              border: isHc 
                                  ? Border.all(color: theme.colorScheme.primary, width: 3)
                                  : null,
                            ),
                            child: Icon(
                              item.icon,
                              size: 72,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            item.title,
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item.description,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Page indicators & Next/Start Buttons
              Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                          border: isHc && _currentPage == index 
                              ? Border.all(color: Colors.white, width: 1)
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Action Button
                  AccessibleButton(
                    label: _currentPage == _slides.length - 1 ? 'MULAI SEKARANG' : 'SELANJUTNYA',
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        context.go(AppRouter.modeSelector);
                      }
                    },
                    semanticLabel: _currentPage == _slides.length - 1 
                        ? 'Lanjutkan ke Pemilihan Mode Aksesibilitas' 
                        : 'Lanjut ke halaman berikutnya',
                  ),
                ],
              ),
            ],
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
