# ==========================================
# Etapa 1: Builder
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /app

# Instalar dependencias necesarias para la compilación
COPY package*.json ./
RUN npm ci || npm install

# Copiar código fuente y compilar TypeScript
COPY tsconfig.json ./
COPY src/ ./src/
RUN npm run build

# ==========================================
# Etapa 2: Runner (Producción ultraligera)
# ==========================================
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000

# Crear usuario sin privilegios root para mayor seguridad
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

# Instalar únicamente dependencias de producción
COPY package*.json ./
RUN npm ci --omit=dev || npm install --omit=dev && \
    npm cache clean --force

# Copiar artefactos compilados desde el builder
COPY --from=builder /app/dist ./dist

# Asignar permisos al usuario no-root
RUN chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3000

# Healthcheck para Docker
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "dist/server.js"]
