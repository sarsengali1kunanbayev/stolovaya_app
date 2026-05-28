import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? glowColor;
  final double borderRadius;
  final bool shimmerBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.glowColor,
    this.borderRadius = 16,
    this.shimmerBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final glow = glowColor ?? AppColors.neonCyan;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: AppGradients.cardGlow,
          border: Border.all(
            color:
                shimmerBorder ? glow.withOpacity(0.4) : AppColors.borderSubtle,
            width: shimmerBorder ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            if (shimmerBorder)
              BoxShadow(
                color: glow.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: -2,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Маленький бейдж ─────────────────────────────────────────────────────────
class NeonBadge extends StatelessWidget {
  final String text;
  final Color color;

  const NeonBadge(
      {super.key, required this.text, this.color = AppColors.neonCyan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5),
      ),
    );
  }
}

// ─── Неон-кнопка ─────────────────────────────────────────────────────────────
class NeonButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool isLoading;
  final bool outlined;

  const NeonButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color = AppColors.neonCyan,
    this.isLoading = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
          boxShadow: outlined
              ? []
              : [
                  BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: -4)
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: outlined ? color : AppColors.bgDeep,
                ),
              )
            else ...[
              if (icon != null) ...[
                Icon(icon,
                    size: 18, color: outlined ? color : AppColors.bgDeep),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: outlined ? color : AppColors.bgDeep,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
