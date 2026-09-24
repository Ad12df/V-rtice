import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vertice/core/constants/app_colors.dart';
import 'package:vertice/core/constants/environment.dart';
import 'package:vertice/core/utils/responsive.dart';
import 'package:vertice/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  int _telemetryIndex = 0;
  Timer? _telemetryTimer;
  Timer? _navigationTimer;

  final List<String> _telemetryMessages = [
    'INICIALIZANDO SATELITES SV...',
    'CALIBRANDO NIEBLA DE GUERRA...',
    'DESTRABANDO PROTOCOLOS DE CARTOGRAFIA...',
    'SINCRONIZANDO DESTINOS Y PUNTOS DE INTERES...',
    'ESTABLECIENDO CONEXION CON GEOTURISMO...',
  ];

  @override
  void initState() {
    super.initState();

    // Ping no bloqueante para despertar la instancia de Render en segundo plano
    _pingBackendHealth();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (mounted && _telemetryIndex < _telemetryMessages.length - 1) {
        setState(() {
          _telemetryIndex++;
        });
      }
    });

    _navigationTimer = Timer(const Duration(milliseconds: 3600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthGate(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  void _pingBackendHealth() {
    http
        .get(Uri.parse('${Environment.apiBaseUrl}/health'))
        .timeout(const Duration(seconds: 6))
        .then((_) {})
        .catchError((_) {});
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _navigationTimer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrLarger = !Responsive.isMobile(context);
    final radarBoxSize = isTabletOrLarger ? 260.0 : 200.0;
    final emblemSize = isTabletOrLarger ? 110.0 : 90.0;
    final titleFontSize = isTabletOrLarger ? 32.0 : 26.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background ambient grid & coordinates
          Positioned.fill(
            child: CustomPaint(
              painter: _SplashRadarPainter(),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTabletOrLarger ? 40 : 28,
                    vertical: isTabletOrLarger ? 32 : 20,
                  ),
                  child: Column(
                    children: [
                      // Top Status Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.turquoise,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'SYS-BOOT // V1.0',
                                style: TextStyle(
                                  color: AppColors.turquoise,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'EL SALVADOR',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              letterSpacing: 2,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Center Emblem & Scanning Ring
                      Center(
                        child: SizedBox(
                          width: radarBoxSize,
                          height: radarBoxSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Rotating Scanner Rings
                              AnimatedBuilder(
                                animation: _rotationController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _rotationController.value * 2 * 3.1415926535,
                                    child: CustomPaint(
                                      size: Size(radarBoxSize, radarBoxSize),
                                      painter: _RadarRingPainter(boxSize: radarBoxSize),
                                    ),
                                  );
                                },
                              ),
                              // Pulsing Glow & Logo Emblem
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      width: emblemSize,
                                      height: emblemSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.surfaceElevated,
                                        border: Border.all(
                                          color: AppColors.turquoise,
                                          width: 2.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.turquoise.withValues(
                                              alpha: _glowAnimation.value,
                                            ),
                                            blurRadius: 30,
                                            spreadRadius: 6,
                                          ),
                                          BoxShadow(
                                            color: AppColors.goldenOrange.withValues(alpha: 0.25),
                                            blurRadius: 15,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/logo.png',
                                          width: emblemSize,
                                          height: emblemSize,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Title Typography
                      Text(
                        'G E O T U R I S M O',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'TURISMO TACTICO & CARTOGRAFIA // SV',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const Spacer(),
                      // Bottom Telemetry Console
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: isTabletOrLarger ? 20 : 16,
                          vertical: isTabletOrLarger ? 16 : 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.surfaceBorder, width: 1),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: const LinearProgressIndicator(
                                minHeight: 3,
                                backgroundColor: AppColors.surfaceBorder,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.turquoise),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                _telemetryMessages[_telemetryIndex],
                                key: ValueKey<int>(_telemetryIndex),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.turquoise,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'COORD: 13.7942 N, 88.8965 W // GEOTURISMO CORE',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarRingPainter extends CustomPainter {
  final double boxSize;

  _RadarRingPainter({required this.boxSize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = (boxSize / 2) * 0.82;
    final arcRadius = (boxSize / 2) * 0.95;

    final outerPaint = Paint()
      ..color = AppColors.turquoise.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final dashPaint = Paint()
      ..color = AppColors.goldenOrange.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Outer circle
    canvas.drawCircle(center, outerRadius, outerPaint);

    // Segmented scanner arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      0,
      1.2,
      false,
      dashPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      3.14,
      1.2,
      false,
      dashPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarRingPainter oldDelegate) =>
      oldDelegate.boxSize != boxSize;
}

class _SplashRadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF14141E)
      ..strokeWidth = 1;

    const double step = 48.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
