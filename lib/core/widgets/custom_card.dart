import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final Color? backgroundColor;
  final Gradient? gradient;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.backgroundColor,
    this.gradient,
    this.height,
    this.width,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHc = theme.colorScheme.primary.value == const Color(0xFF062947).value;

    final cardColor = backgroundColor ?? theme.cardTheme.color ?? theme.colorScheme.surface;

    final border = isHc
        ? Border.all(color: theme.colorScheme.primary, width: 2.0)
        : Border.all(color: theme.dividerColor.withValues(alpha: 0.05), width: 1.0);

    Widget cardContent = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? cardColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(isHc ? 16 : borderRadius),
        border: border,
        boxShadow: isHc
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F4C81).withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.75),
                  blurRadius: 8,
                  offset: const Offset(-2, -2),
                ),
              ],
      ),
      child: child,
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        borderRadius: BorderRadius.circular(isHc ? 16 : borderRadius),
        child: cardContent,
      );
    }

    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        hint: semanticHint ?? (onTap != null ? 'Klik dua kali untuk memilih item ini' : null),
        container: true,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
