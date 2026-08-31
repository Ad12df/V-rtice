import 'package:flutter/material.dart';
import 'package:vertice/core/constants/app_colors.dart';
import 'package:vertice/core/utils/responsive.dart';
import 'package:vertice/features/auth/presentation/widgets/custom_button.dart';

class MapScreen extends StatelessWidget {
  final bool isGuest;

  const MapScreen({
    super.key,
    this.isGuest = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTabletOrLarger = !Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('VÉRTICE // MAPA'),
        actions: [
          IconButton(
            tooltip: 'Cerrar Sesión',
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Cuadrícula y radar de fondo estilo Animus
          Positioned.fill(
            child: CustomPaint(
              painter: _RadarGridPainter(),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTabletOrLarger ? 40 : 24,
                    vertical: isTabletOrLarger ? 28 : 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge de estado de sincronización
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTabletOrLarger ? 16 : 12,
                          vertical: isTabletOrLarger ? 8 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isGuest ? AppColors.gold : AppColors.cyan,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isGuest ? AppColors.gold : AppColors.cyan,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isGuest
                                  ? 'MODO INVITADO // SINCRONIZACIÓN LIMITADA'
                                  : 'AGENTE ACTIVO // CONEXIÓN ESTABLE',
                              style: TextStyle(
                                color: isGuest ? AppColors.gold : AppColors.cyan,
                                fontSize: isTabletOrLarger ? 11 : 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Panel HUD central adaptativo
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Container(
                            padding: EdgeInsets.all(isTabletOrLarger ? 32 : 24),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.surfaceBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.explore_outlined,
                                  size: isTabletOrLarger ? 56 : 48,
                                  color: isGuest ? AppColors.gold : AppColors.cyan,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'NIEBLA DE GUERRA ACTIVA',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: isTabletOrLarger ? 18 : 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'El territorio de El Salvador se encuentra oculto. Explora rutas, descubre puntos de sincronización y despeja el mapa.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: isTabletOrLarger ? 14 : 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                CustomButton(
                                  text: 'INICIAR EXPLORACIÓN',
                                  variant: isGuest
                                      ? ButtonVariant.outline
                                      : ButtonVariant.primary,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: AppColors.surfaceElevated,
                                        content: Text(
                                          'Inicializando GPS y módulos de cartografía...',
                                          style: TextStyle(color: AppColors.cyan),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Telemetría inferior (Coordenadas El Salvador)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LAT: 13.7942° N  |  LON: 88.8965° W',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: isTabletOrLarger ? 12 : 11,
                              letterSpacing: 1.1,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            'SECTOR: SV-CENTRAL',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: isTabletOrLarger ? 12 : 11,
                              letterSpacing: 1.1,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
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

class _RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF14141E)
      ..strokeWidth = 1;

    const double step = 40.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Círculos concéntricos de radar
    final center = Offset(size.width / 2, size.height / 2);
    final circlePaint = Paint()
      ..color = AppColors.cyan.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, 80, circlePaint);
    canvas.drawCircle(center, 160, circlePaint);
    canvas.drawCircle(center, 240, circlePaint);
    canvas.drawCircle(center, 340, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
