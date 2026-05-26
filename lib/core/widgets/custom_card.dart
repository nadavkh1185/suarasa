import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;
  final Color? backgroundColor;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry padding;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
    this.backgroundColor,
    this.height,
    this.width,
    this.padding = const EdgeInsets.all(20.0),
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
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: border,
        boxShadow: isHc
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
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
        borderRadius: BorderRadius.circular(8),
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
