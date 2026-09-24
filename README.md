# 🗺️ GeoTurismo — Plataforma de Turismo Táctico, Cartografía y Agenda de Eventos en El Salvador

> **GeoTurismo** (anteriormente conocido con el nombre clave *Vértice*) es una solución tecnológica integral de cartografía táctica, turismo interactivo y agenda de eventos culturales y expediciones en El Salvador. La plataforma combina la precisión de datos espaciales (PostGIS / OpenStreetMap / OSRM) con una interfaz oscura táctica, control de acceso basado en roles (RBAC) y sincronización reactiva en tiempo real con Supabase.

---

## 🧭 Visión General

GeoTurismo transforma la exploración del territorio salvadoreño en una experiencia táctica e interactiva, permitiendo a turistas, expedicionarios y operadores:
- Explorar **atalayas naturales, sitios arqueológicos, volcanes, lagos y playas de clase mundial** a lo largo de los 14 departamentos de El Salvador.
- Consultar y publicar eventos en la **Agenda Táctica de Eventos** (torneos de surf, senderismo nocturno, hackathones y festivales culturales).
- Trazar **rutas viales automáticas** mediante el motor de enrutamiento OSRM y exportar trayectorias directas hacia **Google Maps y Waze**.
- Gestionar el ecosistema turístico mediante una consola administrativa de alto mando con control de operadores, moderación y estadísticas territoriales.

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
    │  • ValueNotifier State  │               │  • ST_DWithin Endpoints │
    │  • SQLite Offline Tiles │               │  • Render Hosting       │
    └───────────┬─────────────┘               └───────────┬─────────────┘
                │                                         │
                │ Conexión Directa SDK                    │ Service Role
                │ (GoTrue / PostGIS RPC / Storage)        │ Admin Client
                ▼                                         ▼
    ┌───────────────────────────────────────────────────────────────────┐
    │                    SUPABASE CLOUD INFRASTRUCTURE                  │
    │                                                                   │
    │  • PostgreSQL 15 + PostGIS Geo-engine (SRID 4326)                 │
    │  • GoTrue Auth (JWT, email/password, triggers automáticos)        │
    │  • Row Level Security (RLS) en todas las entidades                │
    │  • Storage Bucket público ('avatars')                             │
    │  • Procedimientos Almacenados (get_all_locations, get_all_events) │
    └───────────────────────────────────────────────────────────────────┘
```

### 📱 Frontend (Aplicación Móvil & Multiplataforma)
- **Framework & Lenguaje:** [Flutter 3.x](https://flutter.dev/) & [Dart 3.x](https://dart.dev/).
- **Motor Cartográfico:** [flutter_map 7.0](https://pub.dev/packages/flutter_map) + [latlong2](https://pub.dev/packages/latlong2) sobre teselas de OpenStreetMap y ArcGIS World Dark Gray.
- **Trazado de Rutas Viales:** [OSRM (Open Source Routing Machine)](https://project-osrm.org/) con decodificación GeoJSON y fallback geodésico Haversine.
- **Navegación Externa:** [url_launcher](https://pub.dev/packages/url_launcher) con integración hacia Google Maps y Waze.
- **Gestión de Estado:** Arquitectura reactiva liviana con `ValueNotifier`, `ChangeNotifier` y `ListenableBuilder` (cero overhead de frameworks pesados).
- **Caché Cartográfica Offline:** `dio_cache_interceptor_db_store` con base de datos SQLite embebida en el dispositivo.
- **Geolocalización:** `geolocator` con sensor GPS de alta precisión y control de ahorro de batería.
- **Integración BaaS:** `supabase_flutter` para autenticación, consultas directas y subida de archivos multimedia.

### ⚡ Backend (Microservicio API REST)
- **Runtime:** [Node.js 22 LTS](https://nodejs.org/) con ESM nativo.
- **Framework Web:** [Fastify v5](https://fastify.dev/) (procesamiento ultrarrápido y bajo overhead).
- **Lenguaje:** [TypeScript 5.x](https://www.typescriptlang.org/) en modo estricto.
- **Validación de Datos:** [Zod](https://zod.dev/) para sanitización y tipado de query params y variables de entorno.
- **Seguridad HTTP:** `@fastify/helmet` (políticas CSP y headers estrictos) y `@fastify/cors`.
- **SDK Base de Datos:** `@supabase/supabase-js` con doble cliente: `supabaseClient` (público) y `supabaseAdmin` (Service Role con privilegios para PostGIS).

### 🗄️ Base de Datos & Backend-as-a-Service (BaaS)
- **Motor de Datos:** PostgreSQL 15 alojado en [Supabase Cloud](https://supabase.com/).
- **Extensión Espacial:** PostGIS (`extensions.postgis`) para manejo nativo de coordenadas `GEOGRAPHY(Point, 4326)` e indexación espacial `GIST`.
- **Seguridad a Nivel de Filas:** Row Level Security (RLS) habilitado en el 100% de las tablas.
- **Mecanismos Triggers:** Creación automática de perfiles desde `auth.users`, sincronización de emails y marcas de tiempo `updated_at`.
- **Almacenamiento de Archivos:** Bucket público `avatars` con límite de 5 MB por archivo e inspección de tipos MIME.

### ☁️ Infraestructura DevOps & Despliegue
- **Backend Hosting:** [Render](https://render.com/) (Web Service administrado en región Oregon con `render.yaml` y Dockerfile multi-etapa).
- **Base de Datos Cloud:** Supabase PaaS gestionado en AWS.
- **Compilación Móvil:** Generación de paquetes Android APK Release optimizados.

---

## 🎨 Paleta de Colores y Guía de Estilo Oficial

La identidad visual de GeoTurismo combina la sobriedad de las interfaces tácticas militares con la riqueza natural y costera de El Salvador:

| Nombre del Color | Código Hex / Token | Aplicación en la Interfaz |
| :--- | :--- | :--- |
| **Azul Ubicación** | `#2A73B5` (`locationBlue`) | Punteros de mapa, acentos primarios de navegación y enlaces interactivos. |
| **Verde Turquesa** | `#218B8D` (`turquoise`) | Bordes tácticos, identidad visual costera/volcánica, anillos de escáner y badges. |
| **Naranja Dorado** | `#F39C12` (`goldenOrange`) | **Trazado de rutas viales (`PolylineLayer`)**, balizas de eventos y destacados. |
| **Verde Volcán** | `#1E5A5A` (`volcanoGreen`) | Categorías naturales, cordilleras, estados activos y chips informativos. |
| **Azul Marino** | `#1B365D` (`navyBlue`) | Texto de contraste en modo claro, bordes de polilíneas y sombreados tácticos. |
| **Fondo Neutro** | `#F8F9FA` (`neutralLight`) | Fondos de pantallas y tarjetas en modo claro/exteriores. |
| **Fondo Oscuro Táctico** | `#0D1B2A` (`darkOrganic`) | Fondo principal inmersivo para cartografía nocturna y modo táctico. |

---

## 🔐 Modelo de Control de Acceso por Roles (RBAC)

La plataforma cuenta con un sistema RBAC estricto gobernado por la función SQL `public.is_admin()` y políticas RLS:

```
                      ┌───────────────────────────────────────┐
                      │            USUARIO / AGENTE           │
                      └──────────────────┬────────────────────┘
                                         │
                        ¿profile.role == 'admin'?
                                         │
                    ┌────────────────────┴────────────────────┐
                    ▼                                         ▼
            [ ROL ADMINISTRADOR ]                     [ ROL ESTÁNDAR ]
                    │                                         │
    • Captura de posiciones GPS en vivo       • Exploración interactiva del mapa
    • Creación/Edición/Borrado de Atalayas    • Búsqueda por 14 departamentos
    • Creación/Edición/Borrado de Eventos     • Creación de eventos (organizer_id)
    • Consola de Control de Operadores        • Trazado de rutas viales OSRM
    • Moderación y baneo de cuentas           • Apertura en Google Maps / Waze
    • Métricas y analíticas territoriales     • Gestión de perfil y avatar propio
```

### 1. Administrador (`admin`)
- **Captura GPS en Terreno:** Botón flotante exclusivo en el mapa para capturar la posición actual del dispositivo y registrar una atalaya turística con coordenadas exactas.
- **Gestión Completa de Atalayas (`locations`):** Inserción, actualización y eliminación de puntos de interés turístico con categorización territorial y tarifaria.
- **Gestión de Agenda (`events`):** Creación, modificación de estado (`upcoming`, `live`, `completed`) y borrado de eventos nacionales.
- **Panel de Mando Administrativo (`AdminPanelScreen`):**
  1. *Operadores:* Búsqueda de usuarios y suspensión/reactivación en tiempo real (`is_banned`).
  2. *Eventos:* Mando centralizado de la agenda.
  3. *Atalayas:* Catálogo completo editable.
  4. *Estadísticas:* Métricas de cobertura por departamento y zonas geográficas.

### 2. Usuario Estándar (`user`)
- **Acceso Autenticado Seguro:** Registro y login con medidor interactivo de seguridad de contraseña y selección de fecha de nacimiento.
- **Navegación Territorial:** Filtrado de atalayas por los 14 departamentos salvadoreños (Santa Ana, San Salvador, La Libertad, etc.) y 4 zonas (Occidental, Central, Paracentral, Oriental).
- **Organización de Eventos:** Creación de nuevos eventos tácticos o culturales; el sistema vincula automáticamente su UUID como `organizer_id`.
- **Rutas Viales Inteligentes:** Trazado de ruta en Naranja Dorado desde su ubicación actual hasta cualquier atalaya seleccionada, con distancia y tiempo estimado de viaje.
- **Lanzador de Navegación Externa:** Acceso directo con un toque a la navegación paso a paso por voz en **Google Maps** o **Waze**.
- **Gestión de Perfil:** Carga y actualización de foto de perfil almacenada en Supabase Storage.

---

## 📁 Estructura del Repositorio

```text
GeoTurismo/
├── README.md                           # Documentación principal del proyecto
├── backend/                            # Microservicio API REST (Fastify + TypeScript)
│   ├── Dockerfile                      # Construcción de imagen de producción multi-etapa
│   ├── render.yaml                     # Manifiesto de infraestructura como código (Render)
│   ├── package.json                    # Dependencias y scripts de Node.js
│   ├── tsconfig.json                   # Configuración del compilador TypeScript
│   ├── .env.example                    # Plantilla de variables de entorno
│   ├── src/
│   │   ├── app.ts                      # Configuración de Fastify, middlewares y rutas
│   │   ├── server.ts                   # Arranque del servidor y Graceful Shutdown
│   │   ├── config/
│   │   │   ├── env.ts                  # Validación de entorno con Zod
│   │   │   └── supabase.ts             # Clientes Supabase (Público y Admin)
│   │   ├── db/
│   │   │   └── schema.sql              # Esquema DDL PostGIS, Tablas, RLS y Semillas
│   │   └── modules/
│   │       ├── health/                 # Endpoint de monitoreo /health
│   │       ├── locations/              # Endpoints para listar puntos turísticos
│   │       ├── places/                 # Búsqueda radial con PostGIS ST_DWithin
│   │       └── profiles/               # Consulta de perfiles y roles RBAC
│   └── README.md                       # Documentación técnica del Backend
│
└── frontend/                           # Aplicación Flutter Multiplataforma
    ├── pubspec.yaml                    # Especificación de paquetes y dependencias
    ├── analysis_options.yaml           # Reglas de análisis estático (flutter_lints)
    ├── android/                        # Proyecto nativo Android (Gradle 9, Java 17)
    ├── assets/images/                  # Logotipo e isotipo oficial
    ├── lib/
    │   ├── main.dart                   # Inicialización, AuthGate y temas
    │   ├── core/                       # Núcleo transversal
    │   │   ├── constants/              # Paleta AppColors y URLs Environment
    │   │   ├── localization/           # i18n (Español e Inglés)
    │   │   ├── providers/              # SettingsProvider persistente
    │   │   ├── theme/                  # AppTheme (Oscuro y Claro)
    │   │   └── utils/                  # Responsive helpers
    │   └── features/                   # Módulos por dominio
    │       ├── auth/                   # Login, registro y AuthService
    │       ├── map/                    # MapScreen, LocationService y MapCacheService
    │       ├── events/                 # EventsScreen, AddEventModal y EventsService
    │       ├── settings/               # SettingsScreen y AdminPanelScreen
    │       ├── shell/                  # AppShell con barra de navegación
    │       └── splash/                 # SplashScreen animado con escáner radar
    └── README.md                       # Documentación técnica del Frontend
```

---

## 🚀 Guía de Instalación y Despliegue

### 1. Requisitos Previos del Sistema
- **Node.js:** Versión `>= 22.0.0` y `npm >= 10.0.0`.
- **Flutter SDK:** Versión `>= 3.24.0` (Dart `>= 3.5.0`).
- **Java Development Kit (JDK):** Versión `17` o `21` LTS.
- **Cuenta en Supabase:** Proyecto creado en [supabase.com](https://supabase.com).

---

### 2. Configuración de Base de Datos en Supabase

1. Accede a tu proyecto en el panel de Supabase y dirígete a **SQL Editor**.
2. Abre el archivo [`backend/src/db/schema.sql`](file:///backend/src/db/schema.sql) de este repositorio.
3. Copia y ejecuta todo su contenido. El script ejecutará de manera idempotente:
   - Activación de extensiones espaciales `postgis` y `pgcrypto`.
   - Creación de tablas: `public.profiles`, `public.locations`, `public.events`, `public.user_explorations`.
   - Triggers automáticos para vincular registros de `auth.users` con `public.profiles`.
   - Habilitación de políticas Row Level Security (RLS) en todas las tablas.
   - Creación del bucket público `storage.buckets` llamado `avatars`.
   - Funciones RPC espaciales: `get_all_locations()`, `nearby_locations(...)` y `get_all_events()`.
   - Inserción de semillas geográficas con atalayas icónicas de El Salvador y usuario administrador por defecto (`admin@vertice.app` / `123456`).

---

### 3. Configuración y Despliegue del Backend

#### A. Variables de Entorno (`backend/.env`)
Copia la plantilla de ejemplo y ajusta tus credenciales:
```bash
cd backend
cp .env.example .env
```

Contenido del archivo `.env`:
```env
PORT=3000
HOST=0.0.0.0
NODE_ENV=development
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key-publica
SUPABASE_SERVICE_ROLE_KEY=tu-service-role-key-secreta
```

#### B. Ejecución en Desarrollo
```bash
npm install
npm run dev
```
El servidor responderá en `http://localhost:3000` con recarga automática.

#### C. Compilación para Producción
```bash
npm run build
npm start
```

#### D. Despliegue Continuo en Render
El proyecto incluye el archivo [`backend/render.yaml`](file:///backend/render.yaml) configurado para desplegar el servicio web con salud en `/health` de forma desatendida.

---

### 4. Configuración y Compilación del Frontend

#### A. Variables de Entorno (`frontend/lib/core/constants/environment.dart`)
Configura las credenciales de conexión directa con Supabase y la URL del microservicio:
```dart
abstract class Environment {
  static const String supabaseUrl = 'https://tu-proyecto.supabase.co';
  static const String supabaseAnonKey = 'tu-anon-key-publica';
  static const String apiBaseUrl = 'https://tu-servicio-backend.onrender.com';
}
```

#### B. Instalación de Dependencias y Validación
```bash
cd frontend
flutter pub get
flutter analyze
```

#### C. Ejecución en Modo Desarrollo
```bash
flutter run
```

#### D. Compilación del APK para Android (Release)
Para generar el paquete binario de instalación para dispositivos Android:
```bash
flutter build apk --release
```
El archivo compilado se ubicará en:
`frontend/build/app/outputs/flutter-apk/app-release.apk`

---

## 👥 Credenciales de Prueba (Semilla Inicial)

Al ejecutar [`schema.sql`](file:///backend/src/db/schema.sql) se genera automáticamente la cuenta del administrador del sistema:
- **Correo Electrónico:** `admin@vertice.app`
- **Contraseña:** `123456`
- **Rol Asignado:** `admin`

*(Nota: Para crear usuarios estándar, utiliza la pestaña de Registro en la aplicación móvil; se les asignará automáticamente el rol `user`).*

---

## 📄 Licencia

Este proyecto está distribuido bajo los términos de la licencia ISC. Consulte los archivos individuales de licencia para obtener más información.
