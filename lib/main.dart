import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/accessibility_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: SuarasaApp(),
    ),
  );
}

class SuarasaApp extends ConsumerWidget {
  const SuarasaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(accessibilityProvider);
    
    // Choose correct theme based on settings
    ThemeData appTheme;
    if (settings.isHighContrast) {
      appTheme = AppTheme.highContrastTheme;
    } else {
      // Default to dark theme for energy conservation and high legibility, light theme otherwise
      appTheme = AppTheme.darkTheme;
    }

    return MaterialApp.router(
      title: 'Suarasa',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      theme: appTheme,
      
      // Inject global font scaling for accessibility
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        
        // Combine system text scaler with Suarasa's custom accessibility scaler multiplier
        final customTextScaler = _ScaledTextScaler(
          mediaQueryData.textScaler,
          settings.textScaleFactor,
        );
        
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: customTextScaler,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _ScaledTextScaler extends TextScaler {
  const _ScaledTextScaler(this.baseScaler, this.multiplier);
  final TextScaler baseScaler;
  final double multiplier;

  @override
  double scale(double fontSize) {
    return baseScaler.scale(fontSize) * multiplier;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ScaledTextScaler &&
        other.baseScaler == baseScaler &&
        other.multiplier == multiplier;
  }

  @override
  int get hashCode => Object.hash(baseScaler, multiplier);
}
