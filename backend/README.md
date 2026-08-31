# 🌋 Vértice Backend API

Servicio Backend de alto rendimiento construido con **Node.js**, **TypeScript** y **Fastify**, integrado con **Supabase** (PostgreSQL / PostGIS) para la aplicación **Vértice** (turismo y gamificación con niebla de guerra en El Salvador).

---

## 🛠️ Tecnologías y Arquitectura

- **Runtime & Lenguaje**: Node.js 20+ con TypeScript estricto (ESM / NodeNext).
- **Framework Web**: [Fastify v5](https://fastify.dev/) (Rápido, bajo overhead).
- **Seguridad**: `@fastify/helmet` y `@fastify/cors`.
- **Validación de Datos**: [Zod](https://zod.dev/) para esquemas de entorno y endpoints.
- **Base de Datos & Auth**: [Supabase](https://supabase.com/) (`@supabase/supabase-js`).
- **Despliegue**: Preparado para [Render](https://render.com/) (usando `render.yaml`), [Koyeb](https://www.koyeb.com/) y contenedores Docker multi-stage.

---

## 📁 Estructura del Proyecto

```text
backend/
├── src/
│   ├── config/
│   │   ├── env.ts          # Validación de variables de entorno con Zod
│   │   └── supabase.ts     # Cliente oficial de Supabase (Anon & Admin)
│   ├── modules/
│   │   ├── health/
│   │   │   └── health.routes.ts   # GET /health
│   │   └── places/
│   │       ├── places.schema.ts   # Validación de query params (lat, lng, radius)
│   │       └── places.routes.ts   # GET /api/v1/places/nearby
│   ├── app.ts              # Configuración de Fastify, middlewares y rutas
│   └── server.ts           # Inicialización y Graceful Shutdown
├── .dockerignore
├── .env.example
├── .gitignore
├── Dockerfile              # Multi-stage build (node:20-alpine)
├── package.json
├── render.yaml             # Configuración IaC para Render
├── tsconfig.json
└── README.md
```

---

## 🚀 Inicio Rápido (Desarrollo Local)

### 1. Requisitos Previos
- Node.js >= 20.0.0
- npm >= 9.0.0

### 2. Instalación de Dependencias
```bash
cd backend
npm install
```

### 3. Configuración de Variables de Entorno
Copia el archivo `.env.example` a `.env` y define tus credenciales:
```bash
cp .env.example .env
```

Variables necesarias en `.env`:
```env
PORT=3000
HOST=0.0.0.0
NODE_ENV=development
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu-anon-key-aqui
SUPABASE_SERVICE_ROLE_KEY=tu-service-role-key-aqui
```

### 4. Ejecutar en Modo Desarrollo (con Hot-Reload)
```bash
npm run dev
```

El servidor iniciará en `http://localhost:3000`.

---

## 📦 Scripts Disponibles

| Script | Descripción |
| :--- | :--- |
| `npm run dev` | Inicia el servidor de desarrollo con `tsx watch` y recarga en caliente |
| `npm run build` | Compila el código TypeScript a JavaScript en `./dist` |
| `npm start` | Ejecuta la versión compilada en producción (`node dist/server.js`) |
| `npm run clean` | Elimina la carpeta de compilación `./dist` |

---

## 📡 Endpoints Iniciales

### 1. Healthcheck
- **Ruta**: `GET /health`
- **Uso**: Verificación de estado para Render, Docker y el Splash Screen de la app móvil.
- **Respuesta**:
  ```json
  {
    "status": "ok",
    "service": "vertice-backend",
    "timestamp": "2026-08-31T16:00:00.000Z",
    "uptime": 14.5
  }
  ```

### 2. Lugares Cercanos (Nearby Places)
- **Ruta**: `GET /api/v1/places/nearby?lat=13.6929&lng=-89.2182&radius=5000`
- **Query Params**:
  - `lat` *(number, requerido)*: Latitud (-90 a 90)
  - `lng` *(number, requerido)*: Longitud (-180 a 180)
  - `radius` *(number, opcional)*: Radio en metros (por defecto: `5000`, máx: `50000`)
- **Respuesta Stub**:
  ```json
  {
    "success": true,
    "meta": {
      "center": { "lat": 13.6929, "lng": -89.2182 },
      "radiusInMeters": 5000,
      "count": 0
    },
    "data": [],
    "message": "Endpoint stub listo para conexión con PostGIS / Supabase"
  }
  ```

---

## 🐳 Docker

Para construir y ejecutar la imagen Docker en local:

```bash
# Construir imagen
docker build -t vertice-backend .

# Ejecutar contenedor
docker run -p 3000:3000 --env-file .env vertice-backend
```

---

## ☁️ Despliegue en Render

1. Conecta tu repositorio de GitHub a [Render](https://dashboard.render.com/).
2. Crea un nuevo **Blueprint** seleccionando el archivo `backend/render.yaml` o crea un **Web Service** apuntando al directorio `backend`.
3. Configura las variables de entorno secretas (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`) en el panel de Render.
