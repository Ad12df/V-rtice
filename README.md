# 🗺️ Next Trip (v1.5.0 beta) — Plataforma de Turismo, Cartografía y Movilidad en El Salvador

> **Desarrollado por The Green Team**  
> *Edición Oficial — Septiembre 2026*  
> Ámbito Territorial: República de El Salvador (14 Departamentos)

---

## 🧭 Visión General

**Next Trip (v1.5.0 beta)** es una solución tecnológica integral de turismo descentralizado, cartografía interactiva, movilidad vehicular y agenda de eventos culturales y ecoturismo en El Salvador. La plataforma combina datos geoespaciales de alta precisión (PostGIS / OpenStreetMap / OSRM / Capa de Tráfico Vial en Tiempo Real) con una interfaz oscura moderna, accesible y sobria, control de acceso basado en roles (RBAC) y persistencia híbrida en la nube con Supabase y almacenamiento local offline (*Offline-First*).

El sistema está diseñado bajo estándares formales de cartografía y turismo nacional, erradicando cualquier jerga militar o de videojuego, permitiendo a turistas, viajeros, administradores y organizadores:

- **Descubrir Destinos Turísticos:** Explorar reservas naturales, sitios arqueológicos, volcanes, lagos, miradores y costas en los 14 departamentos salvadoreños.
- **Consultar la Cartelera de Eventos:** Explorar y publicar actividades culturales, festivales, torneos y expediciones, vinculando la autoría al organizador (`organizer_id`).
- **Navegación y Rutas Nativas con Tráfico Real:** Trazar trayectorias viales dentro de la aplicación, incorporando el factor de congestión del tráfico vehicular y tiempo estimado de viaje (ETA) dinámico.
- **Capa Conmutable de Tráfico Vial:** Monitorear el flujo vehicular en carreteras y avenidas mediante código cromático (verde, ámbar y rojo) con control lateral independiente.
- **Preferencias Sincronizadas y Modo Bilingüe:** Soporte para Español (`es`) e Inglés (`en`) en caliente, modo de tema visual y notificaciones con sincronización en la nube (`user_settings`) y respaldo offline en `SharedPreferences`.
- **Administración en Terreno:** Registro asistido de nuevos destinos turísticos desde cualquier punto tocado en el mapa, exclusivo para usuarios con rol de administrador.

---

## 🚀 Novedades y Características de la Versión v1.5.0 beta

1. **Capa de Tráfico Vial en Tiempo Real (In-App):**
   - Visualización de la red arterial de carreteras de El Salvador con código cromático vehicular (verde: fluido, ámbar: moderado, rojo: congestionado).
   - Botón lateral flotante conmutable (**TRÁFICO**) que activa y desactiva las líneas de tráfico de forma instantánea sin interrumpir la ruta activa ni los marcadores.
2. **Cálculo de Rutas con Tráfico y ETA Dinámico:**
   - Algoritmo de enrutamiento nativo que contempla la congestión vial y horas pico salvadoreñas para ofrecer estimaciones de tiempo realistas.
   - Panel HUD flotante superior con telemetría de viaje (distancia en km, tiempo estimado y botón de cancelación directa `✕`).
   - Navegación 100% nativa dentro de Next Trip sin redirecciones a aplicaciones externas.
3. **Nueva Tabla de Ajustes de Usuario (`public.user_settings`):**
   - Persistencia en Supabase vinculada 1:1 con `auth.users` (`user_id`, `language`, `theme_mode`, `traffic_layer_enabled`, `notifications_enabled`).
   - Políticas RLS estrictas para que cada usuario gestione sus propias preferencias.
   - Inicialización automática mediante trigger `handle_new_user()` con `ON CONFLICT (user_id) DO NOTHING`.
4. **Estrategia de Persistencia Offline-First e Internacionalización (i18n):**
   - Carga instantánea de preferencias desde `SharedPreferences` al abrir la app, garantizando funcionamiento fluido sin conexión a internet.
   - Selector intuitivo de idioma en Ajustes (**Español (es)** / **English (en)**) con actualización en caliente sin reiniciar la aplicación.
5. **Conversión de Puntos a Destinos Turísticos (Exclusivo Administrador):**
   - Al tocar cualquier coordenada en el mapa, los usuarios administradores disponen del botón prioritario **`AGREGAR COMO DESTINO TURÍSTICO`**.
   - Apertura asistida de `AddLocationModal` con coordenadas precargadas (latitud y longitud exactas), permitiendo ingresar departamento, categoría, tarifas y fotos.
6. **Depuración Total de Lenguaje y Purga de Dificultades:**
   - Erradicación completa del concepto "Dificultad" de la interfaz de usuario (tarjetas, filtros y modales).
   - Sustitución de terminología residual hacia un español formal, neutro y turístico.

---

## 🛠️ Stack Tecnológico Completo

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             ARQUITECTURA DEL SISTEMA                        │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌─────────────────────────┐               ┌─────────────────────────┐
    │     CLIENTE MÓVIL       │               │      MICROSERVICIO      │
    │   (Flutter / Android)   │               │   (Fastify / Node.js)   │
    │                         │               │                         │
    │  • flutter_map (OSM)    │   REST Pings  │  • Fastify v5 (TS)      │
    │  • OSRM Routing Engine  │──────────────>│  • Zod Validation       │
    │  • Traffic Flow Layer   │               │  • ST_DWithin Endpoints │
    │  • SettingsProvider     │               │  • Render Hosting       │
    │  • SQLite Offline Store │               └───────────┬─────────────┘
    └───────────┬─────────────┘                           │
                │                                         │
                │ Conexión Directa SDK                    │ Service Role
                │ (GoTrue / PostGIS RPC / Storage)        │ Admin Client
                ▼                                         ▼
    ┌───────────────────────────────────────────────────────────────────┐
    │                    SUPABASE CLOUD INFRASTRUCTURE                  │
    │                                                                   │
    │  • PostgreSQL 15 + PostGIS Geo-engine (SRID 4326)                 │
    │  • GoTrue Auth (JWT, email/password, triggers automáticos)        │
    │  • Row Level Security (RLS) en el 100% de tablas                 │
    │  • Tablas: profiles, user_settings, locations, events             │
    │  • Storage Bucket público ('avatars')                             │
    │  • Procedimientos Almacenados (get_all_locations, get_all_events) │
    └───────────────────────────────────────────────────────────────────┘
```

### 📱 Frontend (Aplicación Móvil — Flutter)
- **Framework & Lenguaje:** [Flutter 3.x](https://flutter.dev/) & [Dart 3.x](https://dart.dev/) (`version: 1.5.0+1`).
- **Motor Cartográfico:** [flutter_map 7.0](https://pub.dev/packages/flutter_map) + [latlong2](https://pub.dev/packages/latlong2) sobre teselas de OpenStreetMap y ArcGIS World Dark Gray.
- **Capa de Tráfico Vial en Tiempo Real:** Red arterial conmutable con polilíneas coloreadas y estimación de congestión.
- **Trazado de Rutas Viales:** [OSRM (Open Source Routing Machine)](https://project-osrm.org/) con decodificación GeoJSON y fallback geodésico Haversine.
- **Internacionalización y Ajustes:** `AppLocalizations` con selector dinámico Español/Inglés y `SettingsProvider` sincronizado con Supabase.
- **Caché Cartográfica Offline:** `dio_cache_interceptor` con base de datos SQLite embebida.
- **Geolocalización:** `geolocator` con sensor GPS de alta precisión y límites territoriales de El Salvador.
- **Integración BaaS:** `supabase_flutter` para autenticación, consultas directas y subida de imágenes de perfil.

### ⚡ Backend (Microservicio API REST)
- **Runtime:** [Node.js 22 LTS](https://nodejs.org/) con soporte ESM nativo.
- **Framework Web:** [Fastify v5](https://fastify.dev/) (arquitectura de alto rendimiento).
- **Lenguaje:** [TypeScript 5.x](https://www.typescriptlang.org/) en modo estricto.
- **Validación de Esquemas:** [Zod](https://zod.dev/) para sanitización y tipado riguroso de parámetros.
- **Seguridad HTTP:** `@fastify/helmet` y `@fastify/cors`.
- **SDK Base de Datos:** `@supabase/supabase-js` con clientes anon y admin (Service Role).

### 🗄️ Base de Datos & Backend-as-a-Service (BaaS)
- **Motor:** PostgreSQL 15 en [Supabase Cloud](https://supabase.com/).
- **Extensión Geoespacial:** PostGIS (`extensions.postgis`) para manejo de coordenadas `GEOGRAPHY(Point, 4326)` e índices espaciales `GIST`.
- **Seguridad:** Row Level Security (RLS) habilitado en `profiles`, `user_settings`, `locations` y `events`.
- **Triggers Automatizados:** Inicialización de `profiles` y `user_settings` con valores estándar al registrarse en `auth.users`.
- **Almacenamiento Multimedia:** Bucket público `avatars` para fotos de perfil y soporte de URLs para imágenes de destinos.

---

## 🎨 Paleta de Colores Oficial

| Nombre del Color | Código Hex / Token | Aplicación en la Interfaz |
| :--- | :--- | :--- |
| **Azul Ubicación** | `#2A73B5` (`locationBlue`) | Marcador de posición del usuario, acentos primarios y badges informativos. |
| **Verde Turquesa** | `#218B8D` (`turquoise`) | Bordes de acento, isotipo circular oficial y elementos activos. |
| **Naranja Dorado** | `#F39C12` (`goldenOrange`) | Trazado de rutas viales (`PolylineLayer`) y botón de tráfico activo. |
| **Verde Volcán** | `#1E5A5A` (`volcanoGreen`) | Categorías de parques naturales, áreas protegidas y chips informativos. |
| **Azul Marino** | `#1B365D` (`navyBlue`) | Texto de contraste en modo claro, bordes de polilíneas y sombreados. |
| **Fondo Neutro** | `#F8F9FA` (`neutralLight`) | Fondos de pantallas y tarjetas en modo claro. |
| **Fondo Oscuro** | `#0D1B2A` (`darkOrganic`) | Fondo principal inmersivo para cartografía y modo nocturno. |

---

## 🔐 Modelo de Control de Acceso por Roles (RBAC)

La plataforma implementa un control de acceso gobernado por la función SQL `public.is_admin()` y políticas RLS:

```
                      ┌───────────────────────────────────────┐
                      │                USUARIO                │
                      └──────────────────┬────────────────────┘
                                         │
                        ¿profile.role == 'admin'?
                                         │
                    ┌────────────────────┴────────────────────┐
                    ▼                                         ▼
            [ ROL ADMINISTRADOR ]                     [ ROL TURISTA / USUARIO ]
                    │                                         │
    • Captura de posiciones GPS en vivo       • Exploración interactiva del mapa
    • Botón "AGREGAR COMO DESTINO"            • Búsqueda por 14 departamentos
    • Creación/Edición/Borrado de Destinos    • Creación de eventos (organizer_id)
    • Creación/Edición/Borrado de Eventos     • Trazado de rutas con tráfico en vivo
    • Panel de Control de Usuarios            • Activación de capa vial conmutable
    • Moderación y suspensión de cuentas      • Selector bilingüe (Español / English)
    • Métricas y analíticas territoriales     • Gestión de perfil y avatar propio
```

---

## 📁 Estructura del Repositorio

```text
NextTrip/
├── README.md                           # Documentación técnica principal del proyecto
├── backend/                            # Microservicio API REST (Fastify + TypeScript)
│   ├── Dockerfile                      # Imagen multi-stage en node:22-alpine
│   ├── render.yaml                     # Despliegue en Render (Infraestructura como código)
│   ├── package.json                    # Dependencias y scripts de Node.js
│   ├── tsconfig.json                   # Configuración de compilación TypeScript
│   ├── .env.example                    # Plantilla de variables de entorno
│   ├── src/
│   │   ├── app.ts                      # Configuración de Fastify, middlewares y rutas
│   │   ├── server.ts                   # Punto de entrada y Graceful Shutdown
│   │   ├── config/                     # Configuración y clientes Supabase
│   │   ├── db/
│   │   │   └── schema.sql              # Esquema DDL: PostGIS, tablas, RLS, triggers y RPCs
│   │   └── modules/                    # Módulos: health, locations, places, profiles
│   └── README.md                       # Documentación técnica del backend
│
└── frontend/                           # Aplicación Móvil Flutter Multiplataforma
    ├── pubspec.yaml                    # Especificación de paquetes y versión (1.5.0+1)
    ├── analysis_options.yaml           # Reglas de análisis estático (flutter_lints)
    ├── android/                        # Proyecto nativo Android
    ├── assets/images/                  # Logotipo circular oficial (logo.png)
    ├── lib/
    │   ├── main.dart                   # Inicialización, AuthGate y MaterialApp reactivo
    │   ├── core/                       # Núcleo transversal (tema, colores, i18n, providers)
    │   │   ├── constants/              # AppColors, Environment
    │   │   ├── localization/           # AppLocalizations (i18n bilingüe)
    │   │   ├── providers/              # SettingsProvider (offline-first & sync)
    │   │   └── theme/                  # AppTheme (Oscuro y Claro)
    │   └── features/                   # Módulos por dominio
    │       ├── auth/                   # Autenticación, registro y perfiles
    │       ├── map/                    # MapScreen, capa de tráfico, AddLocationModal
    │       ├── events/                 # EventsScreen y AddEventModal
    │       ├── settings/               # SettingsScreen y AdminPanelScreen
    │       ├── shell/                  # AppShell y barra de navegación
    │       └── splash/                 # SplashScreen con isotipo oficial
    └── README.md                       # Documentación técnica del frontend
```

---

## 🚀 Guía de Instalación y Despliegue

### 1. Requisitos del Sistema
- **Node.js:** Versión `>= 22.0.0` y `npm >= 10.0.0`.
- **Flutter SDK:** Versión `>= 3.24.0` (Dart `>= 3.5.0`).
- **Java Development Kit (JDK):** Versión `17` o `21` LTS.
- **Proyecto Supabase:** Proyecto activo con extensión PostGIS.

### 2. Configuración de Base de Datos en Supabase
1. Ingresa al panel de Supabase y dirígete al **SQL Editor**.
2. Abre el archivo [`backend/src/db/schema.sql`](file:///backend/src/db/schema.sql).
3. Ejecuta el script. Configurará de forma idempotente:
   - Extensiones `postgis` y `pgcrypto`.
   - Tablas `public.profiles`, `public.user_settings`, `public.locations`, `public.events` y `public.user_explorations`.
   - Triggers automáticos para inicializar perfiles y preferencias de usuario por defecto.
   - Políticas RLS y bucket público de almacenamiento `avatars`.
   - Funciones RPC espaciales: `get_all_locations()`, `nearby_locations(...)` y `get_all_events()`.

### 3. Backend (Fastify)
```bash
cd backend
cp .env.example .env
npm install
npm run dev        # Modo desarrollo en http://localhost:3000
npm run build      # Compilar a JavaScript en /dist
npm start          # Ejecutar en producción
```

### 4. Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter analyze    # Verificación de calidad (0 issues)
flutter test       # Pruebas unitarias y de integración
flutter run        # Modo desarrollo en dispositivo/emulador

# Compilar APK de producción para Android:
flutter build apk --release
```
El archivo de instalación resultante se genera en:  
`frontend/build/app/outputs/flutter-apk/app-release.apk`

---

## 👥 Credenciales de Prueba Iniciales
- **Administrador:** `admin@vertice.app` / `123456` (Rol: `admin`)
- **Usuarios regulares:** Registro disponible directamente desde la pantalla de bienvenida de la aplicación móvil (Rol: `user`).

---

## 📄 Licencia
Este proyecto está distribuido bajo los términos de la licencia ISC. Consulte los archivos individuales para más detalles.
