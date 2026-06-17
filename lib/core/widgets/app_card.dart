import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum CardVariant { elevated, outlined, gradient }

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final CardVariant variant;
  final Gradient? gradient;
  final EdgeInsetsGeometry? contentPadding;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.backgroundColor,
    this.variant = CardVariant.elevated,
    this.gradient,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? 16;
    Color bg;
    BoxDecoration decoration;
    switch (variant) {
      case CardVariant.outlined:
        bg = backgroundColor ?? (isDark ? AppColors.darkCard : Colors.white);
        decoration = BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade200),
        );
      case CardVariant.gradient:
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          gradient: gradient ?? LinearGradient(colors: [AppColors.sunsetBright, AppColors.sunset]),
          boxShadow: [BoxShadow(color: AppColors.sunsetBright.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        );
      default:
        bg = backgroundColor ?? (isDark ? AppColors.darkCard : Colors.white);
        decoration = BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(r),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04), blurRadius: 12, offset: const Offset(0, 2))],
        );
    }

    final card = Container(
      padding: contentPadding ?? padding ?? const EdgeInsets.all(16),
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(r),
          child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(r), child: card)),
      );
    }

    return Padding(padding: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: card);
  }
}

class AppListItem extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const AppListItem({super.key, required this.leading, required this.title, this.subtitle, this.trailing, this.onTap, this.margin});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      child: Row(children: [
        leading,
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))],
        ])),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ]),
    );
  }
}

class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const AppStatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3)),
    );
  }
}

class AppInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const AppInfoRow({super.key, required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) ...[Icon(icon, size: 16, color: Colors.grey.shade500), const SizedBox(width: 8)],
        SizedBox(width: icon != null ? null : 110,
          child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
