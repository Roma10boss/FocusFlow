import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final List<BoxShadow>? shadows;
  final bool hasGlow;
  final Color? glowColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 25.0,
    this.opacity = 0.08,
    this.padding,
    this.borderRadius,
    this.color,
    this.shadows,
    this.hasGlow = false,
    this.glowColor,
    this.width,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(24);

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: effectiveBorderRadius,
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: shadows ?? [
                // Inner light reflection
                BoxShadow(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.white.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(-1, -1),
                  spreadRadius: -2,
                ),
                // Main depth shadow
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                  spreadRadius: -8,
                ),
                // Crisp close shadow
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
                // Ambient glow
                if (hasGlow)
                  BoxShadow(
                    color: (glowColor ?? Theme.of(context).colorScheme.primary)
                        .withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 0),
                    spreadRadius: 2,
                  ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark ? [
                  Colors.white.withOpacity(opacity * 1.2),
                  Colors.white.withOpacity(opacity * 0.8),
                  Colors.white.withOpacity(opacity * 0.4),
                  Colors.white.withOpacity(opacity * 0.1),
                ] : [
                  Colors.white.withOpacity(opacity * 3.5),
                  Colors.white.withOpacity(opacity * 2.2),
                  Colors.white.withOpacity(opacity * 1.2),
                  Colors.white.withOpacity(opacity * 0.6),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Animated Glass Card for interactive elements
class AnimatedGlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Duration animationDuration;
  final double blur;

  const AnimatedGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.animationDuration = const Duration(milliseconds: 150),
    this.blur = 25.0,
  });

  @override
  State<AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}

class _AnimatedGlassCardState extends State<AnimatedGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 0.4,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.08,
      end: 0.15,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GlassCard(
              width: widget.width,
              height: widget.height,
              margin: widget.margin,
              padding: widget.padding,
              blur: widget.blur,
              opacity: _opacityAnimation.value,
              hasGlow: _glowAnimation.value > 0.1,
              glowColor: Theme.of(context).colorScheme.primary,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

// Liquid Glass Button with Premium Feel
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? color;
  final bool isPrimary;
  final double borderRadius;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.width,
    this.height,
    this.color,
    this.isPrimary = false,
    this.borderRadius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedGlassCard(
      onTap: onPressed,
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      blur: 30.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: isPrimary
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    effectiveColor.withOpacity(isDark ? 0.4 : 0.6),
                    effectiveColor.withOpacity(isDark ? 0.2 : 0.3),
                    effectiveColor.withOpacity(isDark ? 0.1 : 0.15),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                )
              : null,
        ),
        child: Center(child: child),
      ),
    );
  }
}

// Floating Glass Surface for special content
class GlassFloatingSurface extends StatelessWidget {
  final Widget child;
  final double elevation;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassFloatingSurface({
    super.key,
    required this.child,
    this.elevation = 20.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      blur: 35.0,
      opacity: 0.12,
      borderRadius: BorderRadius.circular(28),
      hasGlow: true,
      glowColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
          spreadRadius: -elevation / 2,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: elevation,
          offset: Offset(0, elevation / 2),
          spreadRadius: -elevation / 4,
        ),
      ],
      child: child,
    );
  }
}