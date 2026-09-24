# 🧭 GeoTurismo — Aplicación Móvil Flutter

Aplicación multiplataforma de turismo táctico y cartografía para El Salvador, construida con **Flutter 3.x** y **Dart 3.x**. Integra renderizado interactivo de mapas sobre teselas libres de OpenStreetMap / ArcGIS, cálculo de rutas viales en tiempo real mediante **OSRM**, sincronización reactiva directa con **Supabase** y un modelo de acceso gobernado por roles (**RBAC**).

---

## 🎨 Identidad Visual & UI/UX

La interfaz de GeoTurismo combina el rigor técnico de los paneles de telemetría y cartografía táctica con la paleta orgánica y turística de El Salvador:

- **Tokens de Color Oficiales (`AppColors`):**
  - `Azul Ubicación` (`#2A73B5`): Indicador del operador, radar y pines interactivos.
  - `Verde Turquesa` (`#218B8D`): Bordes, isotipo, anillos de escáner y badges tácticos.
  - `Naranja Dorado` (`#F39C12`): **Trazo de rutas viales (`PolylineLayer`)**, balizas de eventos y alertas.
  - `Verde Volcán` (`#1E5A5A`): Atalayas naturales, cordilleras y chips de dificultad.
  - `Azul Marino` (`#1B365D`): Contornos de polilíneas, textos principales en modo claro y sombras.
  - `Fondo Neutro` (`#F8F9FA`): Superficies en modo claro.
  - `Fondo Oscuro Táctico` (`#0D1B2A`): Entorno inmersivo nocturno de cartografía.
- **Tipografía y Estilo:**
  - Estilo monoespaciado limpio (`fontFamily: monospace`) para telemetría, coordenadas GPS y cabeceras de sistema.
  - Títulos con espaciado expandido (`letterSpacing: 4-6`) y badges en mayúsculas estilo consola de mando.

---

## 📂 Arquitectura Modular por Features (`lib/`)

La aplicación sigue los principios de **Clean Architecture Táctica** dividida por dominios funcionales (*feature-first*):

```text
frontend/lib/
├── main.dart                       # Inicialización de Supabase, AuthGate y temas globales
├── core/                           # Capa transversal y utilidades compartidas
│   ├── constants/
│   │   ├── app_colors.dart         # Paleta de colores oficial de GeoTurismo
│   │   └── environment.dart        # Configuración de URLs y credenciales públicas
│   ├── localization/
│   │   └── app_localizations.dart  # Diccionarios completos de traducción (Español / Inglés)
│   ├── providers/
│   │   └── settings_provider.dart  # Singleton ChangeNotifier para tema, escala y lenguaje
│   ├── theme/
│   │   └── app_theme.dart          # Temas Oscuro Táctico y Claro estructurados
│   └── utils/
│       └── responsive.dart         # Breakpoints adaptativos (Móvil <600dp, Tablet >=600dp)
└── features/                       # Módulos organizados por dominio
    ├── auth/                       # Autenticación y Registro con RBAC
    │   ├── presentation/
    │   │   ├── screens/auth_screen.dart # Formulario con indicador de entropía y fecha
    │   │   └── widgets/            # CustomTextField, CustomButton, TacticalAlert
    │   └── services/auth_service.dart   # Sincronización con GoTrue y gestión de perfiles
    ├── map/                        # Cartografía y Trazado de Rutas
    │   ├── presentation/
    │   │   ├── screens/map_screen.dart  # Visor OpenStreetMap, PolylineLayer y radar
    │   │   └── widgets/
    │   │       ├── add_location_modal.dart   # Modal de captura GPS para administradores
    │   │       └── advanced_search_modal.dart# Filtro por 14 departamentos y zonas
    │   └── services/
    │       ├── location_service.dart    # PostGIS RPC y enrutamiento con OSRM
    │       └── map_cache_service.dart   # Caché persistente de teselas en SQLite
    ├── events/                     # Agenda Táctica de Eventos
    │   ├── models/tactical_event.dart   # Modelo de datos con serialización Supabase
    │   ├── presentation/
    │   │   ├── screens/events_screen.dart# Lista reactiva y buscador en tiempo real
    │   │   └── widgets/add_event_modal.dart # Creación de eventos con organizer_id
    │   └── services/events_service.dart # Sincronización con RPC get_all_events
    ├── settings/                   # Ajustes y Consola Administrativa
    │   └── presentation/screens/
    │       ├── settings_screen.dart     # Perfil, cambio de password, avatar y GPS switch
    │       └── admin_panel_screen.dart  # Panel de Mando (Operadores, Eventos, Atalayas)
    ├── shell/                      # Contenedor de Navegación
    │   └── presentation/screens/app_shell.dart # Barra inferior y botón radar flotante
    └── splash/                     # Pantalla de Arranque
        └── presentation/screens/splash_screen.dart # Escáner radar, isotipo y ping de salud
```

---

## 🖥️ Componentes Clave de la Interfaz (UI)

### 1. `MapScreen` (`features/map/presentation/screens/map_screen.dart`)
- **Capas Cartográficas:** Renderizado de teselas mediante `flutter_map` (ArcGIS Dark Gray Canvas con fallback a OpenStreetMap estándar).
- **Rutas Viales Tácticas (`PolylineLayer`):** Traza el camino vial óptimo en color **Naranja Dorado (`#F39C12`)** con contorno **Azul Marino (`#1B365D`)** calculado por OSRM.
- **Captura GPS para Administradores:** Si el usuario tiene rol `admin`, se despliega un botón flotante (`admin_capture_current_position_fab`) y se habilita la pulsación sobre el mapa para registrar una atalaya con coordenadas exactas en tiempo real.
- **Lanzador de Navegación Externa:** Botón de un toque para abrir la ruta en **Google Maps** o **Waze** a través de `url_launcher`.
- **Buscador y Filtro Territorial:** Modal avanzado con los 14 departamentos y 4 zonas de El Salvador, filtrando por costo y dificultad.

### 2. `EventsScreen` (`features/events/presentation/screens/events_screen.dart`)
- **Lista Reactiva:** Conectada a `EventsService.eventsNotifier`, actualizándose instantáneamente ante inserciones o modificaciones.
- **Filtrado Dinámico:** Búsqueda en tiempo real por título, descripción, ubicación o departamento, y filtrado por estado (`upcoming`, `live`, `completed`).
- **Modal de Creación `AddEventModal`:** Disponible para usuarios autenticados; auto-asigna el `auth.uid()` como `organizer_id` para garantizar la autoría del evento.

### 3. `AuthScreen` y `SplashScreen`
- **Isotipo Oficial y Anillo de Escáner:** Incorporan el emblema de GeoTurismo con un radar animado de escaneo, resplandor turquesa pulsante y micro-animaciones continuas.
- **Tipografía ASCII Limpia:** Indicadores de estado del sistema (`SYS-BOOT // V1.0`, `EL SALVADOR`), telemetría paso a paso y diseño de consola de comando.
- **Seguridad en Entrada:** Formulario con medidor de entropía de contraseñas (`PasswordStrengthIndicator`), selector de fecha de nacimiento y protección contra contraseñas débiles.

### 4. `AdminPanelScreen` (`features/settings/presentation/screens/admin_panel_screen.dart`)
- **Consola de Mando para Administradores:**
  1. *OPERADORES:* Nómina completa de usuarios con control de suspensión/desuspensión inmediata (`is_banned`).
  2. *EVENTOS:* Modificación y eliminación de la agenda de eventos.
  3. *ATALAYAS:* Control CRUD de destinos y atalayas turísticas.
  4. *ESTADÍSTICAS:* Métricas cuantitativas del sistema y desglose territorial por departamento.

---

## 🔄 Flujo de Servicios y Sincronización con Supabase

```
  ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
  │   AuthService   │       │ LocationService │       │  EventsService  │
  └────────┬────────┘       └────────┬────────┘       └────────┬────────┘
           │                         │                         │
           │ GoTrue                  │ RPC get_all_locations   │ RPC get_all_events
           │ JWT / Storage           │ OSRM Driving Engine     │ CRUD en 'events'
           ▼                         ▼                         ▼
  ┌─────────────────────────────────────────────────────────────────────┐
  │                      SUPABASE BACKEND-AS-A-SERVICE                  │
  │                                                                     │
  │   • Autenticación: auth.users -> Triggers -> public.profiles        │
  │   • Políticas RLS: Validación en cada INSERT, UPDATE y DELETE       │
  │   • Storage: Subida de avatares a bucket 'avatars'                  │
  │   • Cálculos Espaciales: Funciones PL/pgSQL PostGIS en servidor     │
  └─────────────────────────────────────────────────────────────────────┘
```

### 1. Enrutamiento Vial con OSRM
En `LocationService.calculateTacticalRoute`:
- Realiza una petición HTTP a `https://router.project-osrm.org/route/v1/driving/{lng1},{lat1};{lng2},{lat2}?overview=full&geometries=geojson`.
- Decodifica la geometría GeoJSON en una lista de puntos `LatLng` para alimentar el `PolylineLayer`.
- Si el servicio externo no responde en 4 segundos, conmuta automáticamente a un cálculo geodésico Haversine en línea recta como mecanismo de resiliencia.

### 2. Caché de Teselas Offline (`MapCacheService`)
- Almacena en una base de datos local SQLite (`dio_cache_interceptor_db_store`) las teselas cartográficas de todo El Salvador para los niveles de zoom del 8 al 11.
- Permite la visualización continua de la cartografía básica incluso sin conectividad a internet en áreas remotas o senderos de montaña.

### 3. Almacenamiento Multimedia (Storage)
- Al actualizar el avatar en `SettingsScreen`, la imagen se comprime en formato JPEG y se sube directamente al bucket `avatars` en la ruta `{user_id}/avatar_{timestamp}.jpg`.
- La URL pública generada se almacena en la columna `avatar_url` de `public.profiles`.

---

## 🚀 Guía de Instalación y Compilación

### 1. Requisitos Previos
- Flutter SDK `>= 3.24.0` (Dart `>= 3.5.0`).
- Android Studio / Android SDK configurado con Java 17 o 21.

### 2. Configurar Variables de Entorno
Verifica los valores en [`lib/core/constants/environment.dart`](file:///frontend/lib/core/constants/environment.dart):
```dart
abstract class Environment {
  static const String supabaseUrl = 'https://tu-proyecto.supabase.co';
  static const String supabaseAnonKey = 'tu-llave-anonima-publica';
  static const String apiBaseUrl = 'https://tu-backend-en-render.onrender.com';
}
```

### 3. Comandos de Desarrollo
```bash
cd frontend

# Descargar dependencias
flutter pub get

# Ejecutar análisis estático de código (debe reportar 0 issues)
flutter analyze

# Iniciar aplicación en emulador o dispositivo conectado
flutter run
```

### 4. Compilación del APK para Producción (Android)
Para generar el archivo binario optimizado para distribución en dispositivos Android:
```bash
flutter build apk --release
```
El archivo resultante se generará en:
`build/app/outputs/flutter-apk/app-release.apk`
