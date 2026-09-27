# 🧭 Next Trip (v1.5.0 beta) — Aplicación Móvil Flutter

> **Next Trip Client v1.5.0 beta (Build 1.5.0+1)**  
> Desarrollado por **The Green Team**  
> Fecha de edición: **Septiembre 2026**  
> Ámbito Territorial: República de El Salvador (14 Departamentos)

Aplicación móvil multiplataforma de turismo descentralizado, cartografía interactiva y movilidad vial para El Salvador, construida con **Flutter 3.x** y **Dart 3.x** (`version: 1.5.0+1`). Integra renderizado de mapas sobre teselas libres de OpenStreetMap / ArcGIS, cálculo de rutas viales en tiempo real con consideración de tráfico, capa conmutable de flujo vehicular, sincronización reactiva con **Supabase** y un modelo de acceso basado en roles (**RBAC**).

---

## 🎨 Identidad Visual & UI/UX

La interfaz de Next Trip ofrece una experiencia de navegación moderna, inmersiva y formal:

- **Tokens de Color Oficiales (`AppColors`):**
  - `Azul Ubicación` (`#2A73B5`): Indicador de posición del usuario y enlaces interactivos.
  - `Verde Turquesa` (`#218B8D`): Bordes de acento, isotipo circular oficial e indicadores de estado.
  - `Naranja Dorado` (`#F39C12`): **Trazado de rutas viales (`PolylineLayer`)**, botón de tráfico activo y destacados.
  - `Verde Volcán` (`#1E5A5A`): Destinos naturales, parques nacionales y chips informativos.
  - `Azul Marino` (`#1B365D`): Contornos de polilíneas, textos principales en modo claro y sombras.
  - `Fondo Neutro` (`#F8F9FA`): Superficies en modo claro.
  - `Fondo Oscuro` (`#0D1B2A`): Entorno inmersivo para cartografía nocturna y alto contraste.
- **Tipografía y Estilo:**
  - Tipografía clara con soporte monoespaciado para telemetría vial, distancias métricas y coordenadas GPS.
  - Diseño responsivo adaptado tanto a pantallas móviles (<600dp) como tabletas (>=600dp).
- **Emblema Oficial:**
  - Logotipo circular transparente en `frontend/assets/images/logo.png` con antialiasing para todas las densidades de pantalla.

---

## 📂 Arquitectura Modular por Features (`lib/`)

La aplicación sigue una arquitectura limpia estructurada por dominios (*feature-first*):

```text
frontend/lib/
├── main.dart                       # Inicialización, AuthGate, MaterialApp reactivo y temas
├── core/                           # Núcleo transversal y utilidades compartidas
│   ├── constants/
│   │   ├── app_colors.dart         # Paleta de colores oficial de Next Trip
│   │   └── environment.dart        # Configuración de URLs y credenciales públicas
│   ├── localization/
│   │   └── app_localizations.dart  # Diccionarios de traducción i18n (Español / Inglés)
│   ├── providers/
│   │   └── settings_provider.dart  # Estado persistente (SharedPreferences + Supabase sync)
│   ├── theme/
│   │   └── app_theme.dart          # Temas Oscuro y Claro estructurados
│   └── utils/
│       └── responsive.dart         # Breakpoints adaptativos (Móvil / Tablet)
└── features/                       # Módulos organizados por dominio
    ├── auth/                       # Autenticación, registro con indicador de seguridad y perfiles
    ├── map/                        # Cartografía, tráfico vehicular, rutas y gestión de destinos
    │   ├── presentation/
    │   │   ├── screens/map_screen.dart   # Visor cartográfico, capa de tráfico y panel HUD
    │   │   └── widgets/
    │   │       ├── add_location_modal.dart    # Formulario asistido para nuevos destinos
    │   │       └── advanced_search_modal.dart # Filtros por 14 departamentos y precios
    │   └── services/
    │       ├── location_service.dart     # Enrutamiento con tráfico y consultas a Supabase
    │       ├── map_cache_service.dart    # Caché offline de teselas en SQLite
    │       └── traffic_network_service.dart # Red de tráfico vial en tiempo real
    ├── events/                     # Cartelera de eventos turísticos y culturales
    │   ├── presentation/
    │   │   ├── screens/events_screen.dart # Lista reactiva y buscador de actividades
    │   │   └── widgets/add_event_modal.dart  # Creación de eventos con organizer_id
    │   └── services/events_service.dart  # Sincronización con RPC get_all_events
    ├── settings/                   # Ajustes y panel de administración
    │   └── presentation/screens/
    │       ├── settings_screen.dart      # Selector de idioma, modo visual y perfil
    │       └── admin_panel_screen.dart   # Panel de control de usuarios y destinos
    ├── shell/                      # Contenedor de navegación (AppShell)
    └── splash/                     # Pantalla de arranque con isotipo oficial
```

---

## 🖥️ Nuevas Capacidades en la UI/UX (v1.5.0 beta)

### 1. `MapScreen`: Capa de Tráfico Vial y Enrutamiento Nativo
- **Capa Conmutable de Tráfico:** Botón lateral flotante (**TRÁFICO**) que alterna al instante la visibilidad de la red de tráfico vehicular sobre las calles de El Salvador (verde: fluido, ámbar: moderado, rojo: congestión).
- **Enrutamiento Dinámico con Factor de Tráfico:** Cálculo de tiempo estimado (ETA) realista considerando la congestión y horas pico.
- **Panel HUD Superior Flotante:** Despliega distancia formateada (ej. `18.4 km`), duración estimada y botón directo `✕` para cancelar la trayectoria activa.
- **Navegación 100% Nativa:** Sin redirecciones forzadas a aplicaciones de terceros.

### 2. Modo Administrador: Conversión de Marcadores a Destinos Turísticos
- **Detección Automática de Rol:** Al tocar cualquier punto provisional en el mapa, los usuarios con rol `admin` disponen del botón destacado: **`AGREGAR COMO DESTINO TURÍSTICO`**.
- **Formulario Asistido (`AddLocationModal`):** Precarga de forma automática las coordenadas geográficas exactas del punto seleccionado (latitud y longitud).
- **Campos del Registro:** Nombre del destino, descripción informativa, departamento (14 departamentos de El Salvador), zona geográfica, categoría turística, tarifa de ingreso ($ USD) y URLs de imágenes.

### 3. Módulo de Ajustes (`SettingsScreen`): Selector Bilingüe y Offline-First
- **Selector de Idioma:** Opciones intuitivas para alternar entre **Español (es)** e **English (en)**.
- **Actualización en Caliente:** El cambio de idioma se refleja de inmediato en toda la aplicación mediante `AppLocalizations` sin requerir reinicio.
- **Estrategia Offline-First:** Las preferencias se cargan instantáneamente desde `SharedPreferences` al abrir la app. Si existe conexión y sesión activa, se sincronizan de forma bidireccional con la tabla `public.user_settings` en Supabase.

### 4. Purga Integral de Terminología Gamificada
- Se eliminó cualquier etiqueta o concepto de "Dificultad" en modales, filtros y fichas de destino.
- Sustitución de jerga por términos profesionales de cartografía y turismo formal.

---

## 🔄 Servicios y Persistencia

### 1. `SettingsProvider`
- Gestiona el estado reactivo del tema visual, tamaño de fuente, idioma, capa de tráfico y notificaciones.
- Almacena las preferencias localmente en `SharedPreferences` y ejecuta upserts asíncronos en `public.user_settings`.

### 2. `LocationService` & `TrafficNetworkService`
- Administra el catálogo de destinos turísticos en Supabase.
- Calcula rutas con OSRM y aplica el modelo de congestión vehicular adaptado a la red vial salvadoreña.

### 3. `MapCacheService`
- Almacena teselas de OpenStreetMap en una base de datos local SQLite para permitir la exploración en áreas rurales o zonas sin cobertura celular.

---

## 🚀 Guía de Instalación y Compilación

### 1. Requisitos Previos
- Flutter SDK `>= 3.24.0` (Dart `>= 3.5.0`).
- Android Studio / Android SDK configurado con JDK 17 o 21.

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

# Ejecutar análisis estático (0 issues)
flutter analyze

# Ejecutar batería de pruebas unitarias
flutter test

# Iniciar aplicación en modo desarrollo
flutter run
```

### 4. Compilación del APK para Producción (Release)
Para generar el paquete binario de instalación de la versión `1.5.0+1`:
```bash
flutter build apk --release
```
El archivo generado se ubicará en:  
`build/app/outputs/flutter-apk/app-release.apk`
