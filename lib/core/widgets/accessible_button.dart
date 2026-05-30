import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccessibleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final String? semanticLabel;
  final String? semanticHint;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double minHeight;
  final bool isFullWidth;
  final bool isSecondary;

  const AccessibleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.semanticHint,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.minHeight = 52.0,
    this.isFullWidth = true,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHc = theme.colorScheme.primary.value == const Color(0xFF062947).value;

    Color buttonColor;
    Color contentColor;

    if (isSecondary) {
      buttonColor = Colors.transparent;
      contentColor = isHc ? theme.colorScheme.primary : theme.colorScheme.onSurface;
    } else {
      buttonColor = backgroundColor ?? theme.colorScheme.primary;
      contentColor = textColor ?? theme.colorScheme.onPrimary;
    }

    final BorderSide borderSide = isSecondary || isHc
        ? BorderSide(
            color: isHc
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withValues(alpha: 0.35),
            width: isHc ? 2.0 : 1.5,
          )
        : BorderSide.none;

    Widget buttonChild = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: contentColor,
              size: 22,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: contentColor,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    // Enforce minimum accessible height and width
    Widget buttonWidget = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minHeight,
      ),
      child: SizedBox(
        width: isFullWidth ? double.infinity : null,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: buttonColor,
            side: borderSide,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: isHc ? 0 : 1,
            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.18),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () {
            HapticFeedback.mediumImpact();
            onPressed();
          },
          child: buttonChild,
        ),
      ),
    );

    // Accessibility Semantics
    return Semantics(
      label: semanticLabel ?? label,
      hint: semanticHint ??
          (isSecondary ? 'Klik dua kali untuk memilih opsi alternatif' : 'Klik dua kali untuk mengaktifkan'),
      button: true,
      enabled: true,
      excludeSemantics: true, // Hide internal text widgets from screen readers so they only hear the unified label
      child: buttonWidget,
    );
  }
}
