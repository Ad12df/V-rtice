# 🧭 VÉRTICE — Plataforma de Turismo Oculto & Cartografía

> **Plataforma de exploración y turismo alternativo para El Salvador basada en mecánicas de mapa con niebla de guerra (*Fog of War*) estilo Animus / Assassin's Creed.**

---

## 🎨 Concepto Visual & UI/UX

La interfaz de usuario está diseñada bajo un enfoque **Minimalista Oscuro / Cyber-Cartográfico**, evocando consolas de sincronización satelital y telemetría táctica:

* **Paleta de Colores (`AppColors`):**
  * `Fondo Principal`: `#0A0A0C` (Negro profundo).
  * `Superficies & Tarjetas`: `#141419` y `#1C1C24` con bordes sutiles en `#262633`.
  * `Acento Neón (Sincronización)`: `#00F0FF` (Cyan Animus con micro-resplandor).
  * `Acento Reliquia / Oro`: `#E5B842` (Dorado táctico para modo invitado y sincronizaciones).
  * `Texto & Telemetría`: `#F0F2F5` (Primario) y `#8E92A0` (Secundario).
* **Componentes Atómicos:**
  * `CustomTextField`: Inputs responsivos con etiquetas superiores en mayúsculas, iconos sutiles y selector de visibilidad de clave.
  * `CustomButton`: Botón modular con estados interactivos, variantes (Primary, Secondary, Outline, Ghost), ajuste elástico de texto y spinner de carga integrado.
* **Experiencia de Entrada:**
  * `SplashScreen`: Secuencia de arranque con radar giratorio adaptativo, pulso lumínico del glifo Vértice y telemetría dinámica en tiempo real antes de la transición suave a la autenticación.
  * `MapScreen`: Cartografía táctica interactiva potenciada por el **SDK oficial de Mapbox** (`mapbox_maps_flutter`), centrada en El Salvador con orientación norte, gestos libres, retícula táctica y HUD superpuesto.

---

## 📱 Soporte Multi-dispositivo y Responsividad

La aplicación cuenta con una arquitectura de diseño adaptativo nativa en [`lib/core/utils/responsive.dart`](file:///c:/Users/javie/Documents/GitHub/V-rtice/frontend/lib/core/utils/responsive.dart):

* **Breakpoints Oficiales:**
  * **Móviles (`< 600dp`)**: Layouts verticales optimizados para uso a una mano en smartphones convencionales y plegables cerrados.
  * **Tablets & Plegables (`>= 600dp` y `< 1024dp`)**: Reorganización espacial de 2 columnas (ej. Marca e Historia a la izquierda, Formularios a la derecha) y escalas tipográficas proporcionadas.
  * **Pantallas de Escritorio / Grandes (`>= 1024dp`)**: Contenedores acotados con `ConstrainedBox` (`maxWidth`) para evitar deformaciones o estiramientos excesivos.
* **Helpers Disponibles:**
  * `Responsive.isMobile(context)`, `Responsive.isTablet(context)`, `Responsive.isDesktop(context)`.
  * `Responsive.value(context, mobile: ..., tablet: ..., desktop: ...)` para asignación rápida de tamaños de fuente, paddings y alturas.
  * `ResponsiveLayout(mobile: ..., tablet: ..., desktop: ...)` para intercambio declarativo de vistas completas.

---

## 🗺️ Configuración del SDK de Mapbox (Android / iOS)

Para habilitar la cartografía táctica en tiempo real, se requiere configurar las credenciales de Mapbox:

### 1. Variables de Entorno en Flutter
Se puede pasar el token público en tiempo de compilación o ejecución con `--dart-define`:

```bash
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.eyJ1Ijoi...
```

O editar el valor por defecto en [`lib/core/constants/environment.dart`](file:///c:/Users/javie/Documents/GitHub/V-rtice/frontend/lib/core/constants/environment.dart).

### 2. Configuración para Android
1. **Token Secreto de Descarga (SDK Binaries):**
   Crea o añade en tu archivo global `~/.gradle/gradle.properties` (o en `android/gradle.properties`):
   ```properties
   MAPBOX_DOWNLOADS_TOKEN=sk.eyJ1Ijoi...
   ```
2. **Permisos de Ubicación & Internet (`android/app/src/main/AndroidManifest.xml`):**
   Asegúrate de contar con los permisos requeridos dentro de la etiqueta `<manifest>`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   ```

### 3. Configuración para iOS
1. **Token Secreto de Descarga:**
   Crea o añade en `~/.netrc`:
   ```text
   machine api.mapbox.com
     login mapbox
     password sk.eyJ1Ijoi...
   ```
2. **Token Público en `ios/Runner/Info.plist`:**
   Añade la clave del token y las descripciones de permisos de ubicación:
   ```xml
   <key>MBXAccessToken</key>
   <string>pk.eyJ1Ijoi...</string>
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>Vértice necesita tu ubicación para sincronizar sectores y despejar la niebla de guerra en el mapa.</string>
   ```

---

## 📂 Arquitectura del Proyecto (`frontend/lib/`)

El frontend está estructurado bajo principios de **Clean Architecture** y separación por dominios (*feature-first*):

```text
frontend/lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         # Paleta de colores centralizada (#0A0A0C, #00F0FF, #E5B842)
│   │   └── environment.dart        # Variables de entorno y llaves de acceso (Mapbox)
│   ├── theme/
│   │   └── app_theme.dart          # Configuración global de ThemeData oscuro
│   └── utils/
│       └── responsive.dart         # Breakpoints y helpers para diseño adaptativo
├── features/
│   ├── splash/
│   │   └── presentation/
│   │       └── screens/
│   │           └── splash_screen.dart   # Pantalla de carga con radar y telemetría
│   ├── auth/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── auth_screen.dart     # Login/Registro adaptativo (1 col móvil / 2 col tablet)
│   │       └── widgets/
│   │           ├── custom_button.dart   # Botones reutilizables estilizados
│   │           └── custom_text_field.dart # Inputs estilizados
│   └── map/
│       └── presentation/
│           └── screens/
│               └── map_screen.dart      # HUD Táctico y Cartografía interactiva Mapbox (El Salvador)
└── main.dart                            # Punto de entrada ultralimpio
```

---

## 🚀 Cómo Ejecutar el Proyecto

### Requisitos Previos
* **Flutter SDK** (versión `>= 3.13.2` o superior).
* Dispositivo físico Android/iOS configurado con depuración USB o emulador en ejecución.

### Pasos de Inicialización

1. **Navegar a la carpeta frontend:**
   ```bash
   cd frontend
   ```

2. **Obtener dependencias:**
   ```bash
   flutter pub get
   ```

3. **Verificar análisis de código (sin advertencias ni errores):**
   ```bash
   flutter analyze
   ```

4. **Ejecutar pruebas unitarias / de widgets:**
   ```bash
   flutter test
   ```

5. **Lanzar la aplicación:**
   ```bash
   flutter run --dart-define=MAPBOX_ACCESS_TOKEN=tu_token_aqui
   ```

---

## 🗺️ Próximas Funcionalidades
- [x] Integración con el SDK oficial de Mapbox (`mapbox_maps_flutter`) con estilos oscuros y telemetría.
- [ ] Módulo de sincronización GPS para despejar polígonos visitados en tiempo real (Niebla de Guerra).
- [ ] Sistema de desbloqueo de "Puntos de Sincronización" (monumentos, volcanes, reservas naturales).
- [ ] Backend en FastAPI / Node.js para persistencia de progreso y rutas turísticas.
