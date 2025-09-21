import 'package:flutter/material.dart';
import 'dart:math' as math;

class DynamicBackground extends StatefulWidget {
  final Widget child;
  final Color? primaryColor;
  final Color? secondaryColor;
  final bool enableParticles;
  final int particleCount;

  const DynamicBackground({
    super.key,
    required this.child,
    this.primaryColor,
    this.secondaryColor,
    this.enableParticles = true,
    this.particleCount = 12,
  });

  @override
  State<DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<DynamicBackground>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _particleController;
  late List<FloatingParticle> _particles;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    if (widget.enableParticles) {
      _generateParticles();
    }
  }

  void _generateParticles() {
    _particles = List.generate(widget.particleCount, (index) {
      return FloatingParticle(
        initialX: math.Random().nextDouble(),
        initialY: math.Random().nextDouble(),
        size: 20 + math.Random().nextDouble() * 80,
        speed: 0.1 + math.Random().nextDouble() * 0.3,
        opacity: 0.03 + math.Random().nextDouble() * 0.07,
      );
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = widget.primaryColor ?? Theme.of(context).colorScheme.primary;
    final secondary = widget.secondaryColor ?? Theme.of(context).colorScheme.secondary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0A0A0F),
                  const Color(0xFF1A1B2E),
                  const Color(0xFF16213E),
                  const Color(0xFF0F1419),
                ]
              : [
                  const Color(0xFFF8FAFC),
                  const Color(0xFFEEF2FF),
                  const Color(0xFFE0E7FF),
                  const Color(0xFFF1F5F9),
                ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Animated gradient orbs
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: BackgroundOrbsPainter(
                  animation: _backgroundController,
                  primaryColor: primary,
                  secondaryColor: secondary,
                  isDark: isDark,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Floating particles
          if (widget.enableParticles)
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlesPainter(
                    animation: _particleController,
                    particles: _particles,
                    isDark: isDark,
                  ),
                  size: Size.infinite,
                );
              },
            ),

          // Content
          widget.child,
        ],
      ),
    );
  }
}

class FloatingParticle {
  final double initialX;
  final double initialY;
  final double size;
  final double speed;
  final double opacity;

  FloatingParticle({
    required this.initialX,
    required this.initialY,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class BackgroundOrbsPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  BackgroundOrbsPainter({
    required this.animation,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Primary orb
    final primaryPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(isDark ? 0.15 : 0.08),
          primaryColor.withOpacity(isDark ? 0.05 : 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.2 + math.sin(animation.value * 2 * math.pi) * 50,
          size.height * 0.3 + math.cos(animation.value * 2 * math.pi) * 30,
        ),
        radius: 200,
      ));

    canvas.drawCircle(
      Offset(
        size.width * 0.2 + math.sin(animation.value * 2 * math.pi) * 50,
        size.height * 0.3 + math.cos(animation.value * 2 * math.pi) * 30,
      ),
      200,
      primaryPaint,
    );

    // Secondary orb
    final secondaryPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          secondaryColor.withOpacity(isDark ? 0.12 : 0.06),
          secondaryColor.withOpacity(isDark ? 0.04 : 0.015),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.8 + math.cos(animation.value * 2 * math.pi * 0.7) * 40,
          size.height * 0.7 + math.sin(animation.value * 2 * math.pi * 0.7) * 60,
        ),
        radius: 150,
      ));

    canvas.drawCircle(
      Offset(
        size.width * 0.8 + math.cos(animation.value * 2 * math.pi * 0.7) * 40,
        size.height * 0.7 + math.sin(animation.value * 2 * math.pi * 0.7) * 60,
      ),
      150,
      secondaryPaint,
    );

    // Tertiary accent orb
    final accentPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? Colors.purple : Colors.indigo).withOpacity(isDark ? 0.08 : 0.04),
          (isDark ? Colors.purple : Colors.indigo).withOpacity(isDark ? 0.02 : 0.01),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(
          size.width * 0.6 + math.sin(animation.value * 2 * math.pi * 1.3) * 30,
          size.height * 0.1 + math.cos(animation.value * 2 * math.pi * 1.3) * 20,
        ),
        radius: 100,
      ));

    canvas.drawCircle(
      Offset(
        size.width * 0.6 + math.sin(animation.value * 2 * math.pi * 1.3) * 30,
        size.height * 0.1 + math.cos(animation.value * 2 * math.pi * 1.3) * 20,
      ),
      100,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(BackgroundOrbsPainter oldDelegate) {
    return animation != oldDelegate.animation ||
           primaryColor != oldDelegate.primaryColor ||
           secondaryColor != oldDelegate.secondaryColor ||
           isDark != oldDelegate.isDark;
  }
}

class ParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final List<FloatingParticle> particles;
  final bool isDark;

  ParticlesPainter({
    required this.animation,
    required this.particles,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final progress = (animation.value * particle.speed) % 1.0;
      final x = (particle.initialX + progress * 0.1) % 1.0 * size.width;
      final y = (particle.initialY + progress * 0.05) % 1.0 * size.height;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(particle.opacity),
            Colors.white.withOpacity(particle.opacity * 0.5),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(x, y),
          radius: particle.size,
        ));

      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return animation != oldDelegate.animation ||
           particles != oldDelegate.particles ||
           isDark != oldDelegate.isDark;
  }
}

// Subtle parallax effect widget
class ParallaxContainer extends StatefulWidget {
  final Widget child;
  final double intensity;

  const ParallaxContainer({
    super.key,
    required this.child,
    this.intensity = 0.02,
  });

  @override
  State<ParallaxContainer> createState() => _ParallaxContainerState();
}

class _ParallaxContainerState extends State<ParallaxContainer> {
  double _offsetX = 0.0;
  double _offsetY = 0.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        final size = MediaQuery.of(context).size;
        setState(() {
          _offsetX = (event.position.dx - size.width / 2) * widget.intensity;
          _offsetY = (event.position.dy - size.height / 2) * widget.intensity;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(_offsetX, _offsetY, 0),
        child: widget.child,
      ),
    );
  }
}