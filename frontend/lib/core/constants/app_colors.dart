import 'package:flutter/material.dart';

/// Paleta de colores oficial para la interfaz de GeoTurismo.
/// Diseno visual organico y turistico moderno inspirado en la cartografia y naturaleza de El Salvador.
class AppColors {
  // --- PALETA OFICIAL GEOTURISMO ------------------------------------------
  /// Azul Ubicacion: Punteros, mapas y acentos primarios de navegacion
  static const Color locationBlue = Color(0xFF2A73B5);

  /// Verde Turquesa: Bordes, marca e identidad visual costera/natural
  static const Color turquoise = Color(0xFF218B8D);

  /// Naranja Dorado: Caminos, rutas tacticas, eventos y destacados
  static const Color goldenOrange = Color(0xFFF39C12);

  /// Verde Volcan: Naturaleza, cordilleras, badges y estado activo
  static const Color volcanoGreen = Color(0xFF1E5A5A);

  /// Azul Marino: Texto principal, contraste, sombras y elegancia
  static const Color navyBlue = Color(0xFF1B365D);

  /// Fondo Neutro: Pantallas y tarjetas en modo claro
  static const Color neutralLight = Color(0xFFF8F9FA);

  /// Fondo Oscuro Tactico Organico: Base para modo oscuro inmersivo
  static const Color darkOrganic = Color(0xFF0D1B2A);

  // --- BACKGROUNDS Y SUPERFICIES (MODO OSCURO TACTICO ORGANICO) -----------
  static const Color background = Color(0xFF0D1B2A); // Fondo Oscuro Tactico Organico
  static const Color surface = Color(0xFF132235); // Superficie organica profunda
  static const Color surfaceElevated = Color(0xFF1A2E44); // Superficie elevada suave
  static const Color surfaceBorder = Color(0x59218B8D); // Verde Turquesa (35% opacidad)
  static const Color surfaceBorderSubtle = Color(0x26218B8D); // Verde Turquesa (15% opacidad)
  static const Color surfaceBorderGold = Color(0x59F39C12); // Naranja Dorado suave

  // --- MODO CLARO / EXTERIORES (FONDO NEUTRO Y CONTRASTE AZUL MARINO) -----
  static const Color lightBackground = Color(0xFFF8F9FA); // Fondo Neutro oficial
  static const Color lightSurface = Color(0xFFFFFFFF); // Blanco puro para tarjetas
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightSurfaceBorder = Color(0x33218B8D); // Borde turquesa suave
  static const Color lightSurfaceBorderSubtle = Color(0x1A218B8D);
  static const Color lightCyan = Color(0xFF2A73B5); // Azul Ubicacion
  static const Color lightGold = Color(0xFFF39C12); // Naranja Dorado
  static const Color lightTextPrimary = Color(0xFF1B365D); // Azul Marino
  static const Color lightTextSecondary = Color(0xFF4A5568);
  static const Color lightTextMuted = Color(0xFF718096);

  // --- ALIAS DE COMPATIBILIDAD CON NUEVA IDENTIDAD ORGANICA ---------------
  // Reemplazan el neon estridente por los nuevos acentos organicos
  static const Color cyan = Color(0xFF2A73B5); // Ahora mapeado al Azul Ubicacion
  static const Color cyanDim = Color(0xFF1E5A8A);
  static const Color cyanGlow = Color(0x332A73B5); // Sombra suave sin saturacion neon

  static const Color gold = Color(0xFFF39C12); // Ahora mapeado al Naranja Dorado
  static const Color goldDim = Color(0xFFC87F0D);
  static const Color goldGlow = Color(0x33F39C12);

  // --- TIPOGRAFIA Y ESTADOS -----------------------------------------------
  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLink = Color(0xFF2A73B5);

  static const Color error = Color(0xFFE74C3C);
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);

  // --- SOMBRAS SUAVES Y PROFESIONALES (ELEVACION ORGANICA) ----------------
  static List<BoxShadow> softShadow({
    double blur = 14,
    double spread = 0,
    double opacity = 0.12,
    Offset offset = const Offset(0, 4),
  }) {
    return [
      BoxShadow(
        color: const Color(0xFF000000).withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: spread,
        offset: offset,
      ),
    ];
  }

  static List<BoxShadow> cyanGlowShadow({
    double blur = 12,
    double spread = 0,
    double opacity = 0.22,
    Offset offset = const Offset(0, 3),
  }) {
    return [
      BoxShadow(
        color: locationBlue.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: spread,
        offset: offset,
      ),
    ];
  }

  static List<BoxShadow> goldGlowShadow({
    double blur = 12,
    double spread = 0,
    double opacity = 0.22,
    Offset offset = const Offset(0, 3),
  }) {
    return [
      BoxShadow(
        color: goldenOrange.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: spread,
        offset: offset,
      ),
    ];
  }
}
