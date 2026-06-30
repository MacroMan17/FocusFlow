import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cosmic Awakening Splash Screen
//
// Timeline:
//   0.0s  Black screen, silence, one tiny star in center
//   0.3s  More stars fade in (random field)
//   0.6s  Nebula glow begins
//   0.9s  FocusFlow logo fades in
//   1.2s  Tagline types in: "One mission at a time."
//   1.6s  Shooting star crosses screen
//   2.0s  Background gently zooms → home screen fades in (router handles nav)
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // ── One master controller drives every stage (total 2.4 s) ──────────
  late final AnimationController _master;

  // Stage animations keyed to intervals of the master
  late final Animation<double> _firstStarOpacity; // 0.0 → 0.15
  late final Animation<double> _starFieldOpacity; // 0.15 → 0.40
  late final Animation<double> _nebulaOpacity; // 0.30 → 0.55
  late final Animation<double> _logoOpacity; // 0.45 → 0.65
  late final Animation<double> _logoScale; // 0.45 → 0.65
  late final Animation<double> _taglineOpacity; // 0.60 → 0.75
  late final Animation<double> _shootingStarT; // 0.72 → 0.88
  late final Animation<double> _bgZoom; // 0.80 → 1.00
  late final Animation<double> _screenFadeOut; // 0.88 → 1.00

  // ── Shooting star ─────────────────────────────────────────────────────
  final _shootingStartFrac = 0.72;
  final _shootingEndFrac = 0.88;

  // ── Star field (generated once) ───────────────────────────────────────
  final List<_Star> _stars = _generateStars(120);

  @override
  void initState() {
    super.initState();

    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _firstStarOpacity = _interval(0.00, 0.15, curve: Curves.easeIn);
    _starFieldOpacity = _interval(0.15, 0.40, curve: Curves.easeOut);
    _nebulaOpacity = _interval(0.28, 0.55, curve: Curves.easeOut);
    _logoOpacity = _interval(0.42, 0.65, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.88, end: 1.0)
        .animate(_interval(0.42, 0.65, curve: Curves.easeOutCubic));
    _taglineOpacity = _interval(0.60, 0.76, curve: Curves.easeOut);
    _shootingStarT = _interval(_shootingStartFrac, _shootingEndFrac,
        curve: Curves.easeInOut);
    _bgZoom = Tween<double>(begin: 1.0, end: 1.06)
        .animate(_interval(0.78, 1.00, curve: Curves.easeIn));
    _screenFadeOut = Tween<double>(begin: 1.0, end: 0.0)
        .animate(_interval(0.88, 1.00, curve: Curves.easeIn));

    // Start immediately
    _master.forward();

    // Watch settings — router will navigate once ready
    // (we just let the master run and the router's redirect fires)
  }

  // Helper: create an Animation<double> 0→1 over [start,end] of master
  Animation<double> _interval(double start, double end,
      {Curve curve = Curves.linear}) {
    return CurvedAnimation(
      parent: _master,
      curve: Interval(start, end, curve: curve),
    );
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep settings loading (router redirect fires when done)
    ref.watch(settingsNotifierProvider);

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _master,
        builder: (context, _) {
          return FadeTransition(
            opacity: _screenFadeOut,
            child: ScaleTransition(
              scale: _bgZoom,
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    // ── 1. Deep space gradient background ────────────────
                    const _CosmicBackground(),

                    // ── 2. Nebula glow ────────────────────────────────────
                    Opacity(
                      opacity: _nebulaOpacity.value,
                      child: const _NebulaGlow(),
                    ),

                    // ── 3. Star field ─────────────────────────────────────
                    Opacity(
                      opacity: _starFieldOpacity.value,
                      child: CustomPaint(
                        size: size,
                        painter: _StarFieldPainter(stars: _stars),
                      ),
                    ),

                    // ── 4. First center star (seed star) ──────────────────
                    Center(
                      child: Opacity(
                        opacity: _firstStarOpacity.value,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white,
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── 5. Shooting star ──────────────────────────────────
                    if (_master.value >= _shootingStartFrac &&
                        _master.value <= _shootingEndFrac + 0.02)
                      CustomPaint(
                        size: size,
                        painter: _ShootingStarPainter(
                          progress: _shootingStarT.value,
                        ),
                      ),

                    // ── 6. Logo + tagline ─────────────────────────────────
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: const _CosmicLogo(),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Tagline — character reveal
                          Opacity(
                            opacity: _taglineOpacity.value,
                            child: _TaglineReveal(
                              progress: _taglineOpacity.value,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Deep space background gradient
// ─────────────────────────────────────────────────────────────────────────────

class _CosmicBackground extends StatelessWidget {
  const _CosmicBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.2),
          radius: 1.4,
          colors: [
            Color(0xFF0D0B2A), // deep indigo-black center
            Color(0xFF060412), // near-black mid
            Color(0xFF000000), // pure black edges
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nebula glow — layered radial gradients for purple-blue effect
// ─────────────────────────────────────────────────────────────────────────────

class _NebulaGlow extends StatelessWidget {
  const _NebulaGlow();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Purple nebula — upper left
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.5, -0.4),
                radius: 0.8,
                colors: [
                  const Color(0xFF6B21A8).withValues(alpha: 0.35), // purple-800
                  const Color(0xFF4C1D95).withValues(alpha: 0.15), // violet-900
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // Blue nebula — lower right
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.6, 0.3),
                radius: 0.65,
                colors: [
                  const Color(0xFF1D4ED8).withValues(alpha: 0.25), // blue-700
                  const Color(0xFF1E3A8A).withValues(alpha: 0.10), // blue-900
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // Teal accent — center bloom
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.45,
                colors: [
                  const Color(0xFF00695C).withValues(alpha: 0.12), // teal
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Star field CustomPainter
// ─────────────────────────────────────────────────────────────────────────────

class _Star {
  final double x; // 0.0 → 1.0 (fraction of screen)
  final double y;
  final double radius;
  final double brightness; // 0.4 → 1.0
  _Star(this.x, this.y, this.radius, this.brightness);
}

List<_Star> _generateStars(int count) {
  final rng = math.Random(42); // fixed seed → same layout every time
  return List.generate(count, (_) {
    return _Star(
      rng.nextDouble(),
      rng.nextDouble(),
      rng.nextDouble() * 1.4 + 0.3, // 0.3 – 1.7 px radius
      rng.nextDouble() * 0.6 + 0.4, // 0.4 – 1.0 brightness
    );
  });
}

class _StarFieldPainter extends CustomPainter {
  final List<_Star> stars;
  _StarFieldPainter({required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      paint.color = Colors.white.withValues(alpha: s.brightness);
      final cx = s.x * size.width;
      final cy = s.y * size.height;
      canvas.drawCircle(Offset(cx, cy), s.radius, paint);
      // Tiny glow
      paint.color = Colors.white.withValues(alpha: s.brightness * 0.25);
      canvas.drawCircle(Offset(cx, cy), s.radius * 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shooting star CustomPainter
// ─────────────────────────────────────────────────────────────────────────────

class _ShootingStarPainter extends CustomPainter {
  final double progress; // 0 → 1

  _ShootingStarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    // Path: starts at top-right, crosses to lower-left
    final startX = size.width * 0.85;
    final startY = size.height * 0.18;
    final endX = size.width * 0.22;
    final endY = size.height * 0.52;

    final currentX = startX + (endX - startX) * progress;
    final currentY = startY + (endY - startY) * progress;

    // Tail length: 80px behind the head
    const tailLen = 80.0;
    final angle = math.atan2(endY - startY, endX - startX);
    final tailX = currentX - math.cos(angle) * tailLen;
    final tailY = currentY - math.sin(angle) * tailLen;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    // Opacity: fade in at start, fade out at end
    final opacity = progress < 0.2
        ? progress / 0.2
        : progress > 0.8
            ? (1.0 - progress) / 0.2
            : 1.0;

    paint.shader = LinearGradient(
      colors: [
        Colors.transparent,
        Colors.white.withValues(alpha: 0.5 * opacity),
        Colors.white.withValues(alpha: opacity),
      ],
      stops: const [0.0, 0.6, 1.0],
    ).createShader(Rect.fromPoints(
      Offset(tailX, tailY),
      Offset(currentX, currentY),
    ));

    canvas.drawLine(
      Offset(tailX, tailY),
      Offset(currentX, currentY),
      paint,
    );

    // Head glow
    canvas.drawCircle(
      Offset(currentX, currentY),
      2.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(_ShootingStarPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Cosmic Logo — glowing teal circle + FocusFlow text
// ─────────────────────────────────────────────────────────────────────────────

class _CosmicLogo extends StatelessWidget {
  const _CosmicLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon container with teal glow
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFF00897B), // teal-600
                Color(0xFF004D40), // teal-900
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF26A69A).withValues(alpha: 0.5),
                blurRadius: 28,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: const Color(0xFF26A69A).withValues(alpha: 0.2),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 18),

        // App name
        const Text(
          'FocusFlow',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
            shadows: [
              Shadow(
                color: Color(0xFF26A69A),
                blurRadius: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tagline character-reveal widget
// ─────────────────────────────────────────────────────────────────────────────

class _TaglineReveal extends StatelessWidget {
  final double progress; // 0.0 → 1.0 (controls how many chars are visible)

  const _TaglineReveal({required this.progress});

  static const _full = 'One mission at a time.';

  @override
  Widget build(BuildContext context) {
    final charCount = (_full.length * progress).round().clamp(0, _full.length);
    final visible = _full.substring(0, charCount);
    // Blinking cursor only while typing
    final cursor = charCount < _full.length ? '|' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          visible,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.75),
            letterSpacing: 1.2,
          ),
        ),
        if (cursor.isNotEmpty)
          Text(
            cursor,
            style: TextStyle(
              fontSize: 15,
              color: const Color(0xFF26A69A).withValues(alpha: 0.9),
              fontWeight: FontWeight.w300,
            ),
          ),
      ],
    );
  }
}
