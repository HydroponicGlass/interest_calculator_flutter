import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool showShadow;
  final Color? backgroundColor;
  final double borderRadius;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.showShadow = true,
    this.backgroundColor,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
    }

    return card.animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final List<Color>? gradientColors;

  const GradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ?? [AppTheme.primaryColor, const Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (gradientColors?.first ?? AppTheme.primaryColor).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
    }

    return card.animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

class IconCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;

  const IconCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (iconColor ?? AppTheme.primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 28,
              color: iconColor ?? AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}