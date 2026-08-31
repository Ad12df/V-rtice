import 'package:flutter/material.dart';

/// Breakpoints estándar para el diseño adaptativo de Vértice.
class ResponsiveBreakpoints {
  static const double mobileMax = 600.0;
  static const double tabletMax = 1024.0;
}

/// Helper utilitario para consultas de diseño responsivo y adaptativo.
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < ResponsiveBreakpoints.mobileMax;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= ResponsiveBreakpoints.mobileMax &&
        width < ResponsiveBreakpoints.tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= ResponsiveBreakpoints.tabletMax;

  /// Retorna un valor adaptado según el breakpoint de la pantalla.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  /// Retorna el ancho actual de la pantalla.
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  /// Retorna el alto actual de la pantalla.
  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;
}

/// Widget constructor para renderizar layouts específicos según el tamaño de pantalla.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.tabletMax && desktop != null) {
          return desktop!;
        }
        if (constraints.maxWidth >= ResponsiveBreakpoints.mobileMax && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}
