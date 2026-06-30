import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cosmic Awakening Splash
//
// Architecture fix: a splashReadyProvider gate prevents the router from
// navigating away until the full 2.6s animation has played. Settings loading
// happens in parallel — whichever finishes last allows navigation.
//
// Timeline  (master: 2600ms)
//   0.0s  Black screen — one tiny star in center
//   0.3s  Star field fades in
//   0.6s  Purple-blue nebula glow blooms
//   0.9s  FocusFlow logo scales in
//   1.2s  Tagline character-reveal: "One mission at a time."
//   1.6s  Shooting star crosses screen
//   2.0s  Background zoom begins
//   2.3s  Screen fades out → router navigates
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _totalMs = 2600;

  late final AnimationController _master;

  // ── Stage animations (all driven off _master via Interval) ──────────
  late final Animation<double> _firstStarFade; // 0.00–0.12
  late final Animation<double> _starFieldFade; // 0.12–0.38
  late final Animation<double> _nebulaFade; // 0.26–0.52
  late final Animation<double> _logoFade; // 0.40–0.62
  late final Animation<double> _logoScale; // 0.40–0.62
  late final Animation<double> _taglineFade; // 0.58–0.74
  late final Animation<double> _shootingStarT; // 0.68–0.84
  late final Animation<double> _bgZoom; // 0.76–1.00
  late final Animation<double> _screenFadeOut; // 0.86–1.00

  // Pre-generated star field (same every launch)
  static final List<_Star> _stars = _generateStars(130);

  bool _hasSetReady = false;

  @override
  void initState() {
    super.initState();

    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );

    _firstStarFade = _iv(0.00, 0.12, Curves.easeIn);
    _starFieldFade = _iv(0.12, 0.38, Curves.easeOut);
    _nebulaFade = _iv(0.26, 0.52, Curves.easeOut);
    _logoFade = _iv(0.40, 0.62, Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(_iv(0.40, 0.62, Curves.easeOutCubic));
    _taglineFade = _iv(0.58, 0.74, Curves.easeOut);
    _shootingStarT = _iv(0.68, 0.84, Curves.easeInOut);
    _bgZoom = Tween<double>(begin: 1.0, end: 1.07)
        .animate(_iv(0.76, 1.00, Curves.easeIn));
    _screenFadeOut = Tween<double>(begin: 1.0, end: 0.0)
        .animate(_iv(0.86, 1.00, Curves.easeIn));

    // When the animation completes, unlock the router gate.
    _master.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasSetReady) {
        _hasSetReady = true;
        // Use addPostFrameCallback so we never mutate provider mid-build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(splashReadyProvider.notifier).state = true;
          }
        });
      }
    });

    // Start immediately — no delays, no waiting for anything.
    _master.forward();
  }

  Animation<double> _iv(double start, double end, Curve curve) =>
      CurvedAnimation(
        parent: _master,
        curve: Interval(start, end, curve: curve),
      );

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _master,
        builder: (_, __) => FadeTransition(
          opacity: _screenFadeOut,
          child: ScaleTransition(
            scale: _bgZoom,
            child: SizedBox.expand(
              child: Stack(
                children: [
                  // ── 1. Deep space gradient ────────────────────────────
                  const _CosmicBg(),

                  // ── 2. Nebula glow ────────────────────────────────────
                  Opacity(
                    opacity: _nebulaFade.value.clamp(0.0, 1.0),
                    child: const _Nebula(),
                  ),

                  // ── 3. Star field ─────────────────────────────────────
                  Opacity(
                    opacity: _starFieldFade.value.clamp(0.0, 1.0),
                    child: CustomPaint(
                      size: size,
                      painter: _StarPainter(stars: _stars),
                    ),
                  ),

                  // ── 4. Seed star (center) ─────────────────────────────
                  Center(
                    child: Opacity(
                      opacity: _firstStarFade.value.clamp(0.0, 1.0),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.white,
                                blurRadius: 10,
                                spreadRadius: 3),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── 5. Shooting star ──────────────────────────────────
                  CustomPaint(
                    size: size,
                    painter: _ShootingPainter(
                      progress: _shootingStarT.value.clamp(0.0, 1.0),
                    ),
                  ),

                  // ── 6. Logo + tagline (center) ────────────────────────
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Opacity(
                          opacity: _logoFade.value.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: const _Logo(),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Tagline
                        Opacity(
                          opacity: _taglineFade.value.clamp(0.0, 1.0),
                          child: _Tagline(
                            progress: _taglineFade.value.clamp(0.0, 1.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Deep-space radial gradient background
// ─────────────────────────────────────────────────────────────────────────────

class _CosmicBg extends StatelessWidget {
  const _CosmicBg();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.15),
          radius: 1.4,
          colors: [
            Color(0xFF0E0B2E), // deep indigo
            Color(0xFF060311), // near-black
            Color(0xFF000000), // pure black edges
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nebula — 3 overlapping radial gradients
// ─────────────────────────────────────────────────────────────────────────────

class _Nebula extends StatelessWidget {
  const _Nebula();
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Purple bloom — top-left
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.45, -0.38),
              radius: 0.75,
              colors: [
                const Color(0xFF7C3AED).withValues(alpha: 0.38), // violet-600
                const Color(0xFF4C1D95).withValues(alpha: 0.14), // violet-900
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
      // Blue bloom — lower-right
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.55, 0.28),
              radius: 0.60,
              colors: [
                const Color(0xFF1D4ED8).withValues(alpha: 0.28), // blue-700
                const Color(0xFF1E3A8A).withValues(alpha: 0.10),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
      // Teal center glow
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.42,
              colors: [
                const Color(0xFF00695C).withValues(alpha: 0.14),
                Colors.transparent,
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Star field
// ─────────────────────────────────────────────────────────────────────────────

class _Star {
  final double x, y, r, b;
  _Star(this.x, this.y, this.r, this.b);
}

List<_Star> _generateStars(int n) {
  final rng = math.Random(42);
  return List.generate(
      n,
      (_) => _Star(
            rng.nextDouble(),
            rng.nextDouble(),
            rng.nextDouble() * 1.3 + 0.25,
            rng.nextDouble() * 0.55 + 0.45,
          ));
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  _StarPainter({required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final cx = s.x * size.width;
      final cy = s.y * size.height;
      // Glow
      p.color = Colors.white.withValues(alpha: s.b * 0.22);
      canvas.drawCircle(Offset(cx, cy), s.r * 2.8, p);
      // Core
      p.color = Colors.white.withValues(alpha: s.b);
      canvas.drawCircle(Offset(cx, cy), s.r, p);
    }
  }

  @override
  bool shouldRepaint(_StarPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shooting star
// ─────────────────────────────────────────────────────────────────────────────

class _ShootingPainter extends CustomPainter {
  final double progress;
  _ShootingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final sx = size.width * 0.82;
    final sy = size.height * 0.16;
    final ex = size.width * 0.20;
    final ey = size.height * 0.50;

    final cx = sx + (ex - sx) * progress;
    final cy = sy + (ey - sy) * progress;
    final angle = math.atan2(ey - sy, ex - sx);
    const tail = 90.0;
    final tx = cx - math.cos(angle) * tail;
    final ty = cy - math.sin(angle) * tail;

    // Opacity: ramp in first 20%, full middle, ramp out last 20%
    final op = progress < 0.2
        ? progress / 0.2
        : progress > 0.8
            ? (1.0 - progress) / 0.2
            : 1.0;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.45 * op),
          Colors.white.withValues(alpha: op),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromPoints(Offset(tx, ty), Offset(cx, cy)));

    canvas.drawLine(Offset(tx, ty), Offset(cx, cy), paint);

    // Head glow
    canvas.drawCircle(
      Offset(cx, cy),
      3.0,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85 * op)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
    // Head core
    canvas.drawCircle(
      Offset(cx, cy),
      1.5,
      Paint()..color = Colors.white.withValues(alpha: op),
    );
  }

  @override
  bool shouldRepaint(_ShootingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// FocusFlow logo
// ─────────────────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glowing teal circle icon
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFF00897B), Color(0xFF004D40)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF26A69A).withValues(alpha: 0.55),
                blurRadius: 32,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: const Color(0xFF26A69A).withValues(alpha: 0.18),
                blurRadius: 72,
                spreadRadius: 12,
              ),
            ],
          ),
          child: const Icon(Icons.check_circle_rounded,
              size: 46, color: Colors.white),
        ),

        const SizedBox(height: 20),

        // App name with teal text glow
        const Text(
          'FocusFlow',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
            shadows: [
              Shadow(color: Color(0xFF26A69A), blurRadius: 20),
              Shadow(color: Color(0xFF26A69A), blurRadius: 40),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tagline character-reveal
// ─────────────────────────────────────────────────────────────────────────────

class _Tagline extends StatelessWidget {
  final double progress; // 0.0 → 1.0

  const _Tagline({required this.progress});

  static const _text = 'One mission at a time.';

  @override
  Widget build(BuildContext context) {
    final count =
        ((_text.length + 1) * progress).floor().clamp(0, _text.length);
    final visible = _text.substring(0, count);
    final typing = count < _text.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          visible,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w300,
            color: Colors.white.withValues(alpha: 0.78),
            letterSpacing: 1.4,
          ),
        ),
        // Blinking cursor while still typing
        if (typing)
          Text(
            '|',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF26A69A).withValues(alpha: 0.85),
              fontWeight: FontWeight.w200,
            ),
          ),
      ],
    );
  }
}
