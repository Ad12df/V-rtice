abstract class Environment {
  /// Token de acceso para la API y SDK de Mapbox
  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: 'TU_MAPBOX_TOKEN_AQUI',
  );
}
