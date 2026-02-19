# ============================================
# DOCKERFILE - FRONTEND (React + Vite)
# ============================================
# Build multi-etapa para optimizar tamaño
# ============================================

# ==========================================
# ETAPA 1: Build (Compilar la aplicación)
# ==========================================
FROM oven/bun:1 as build

WORKDIR /app

# Copiar archivos de dependencias
COPY package.json bun.lockb ./

# Instalar dependencias
RUN bun install --frozen-lockfile

# Copiar todo el código fuente
COPY . .

# Argumentos de build (variables en tiempo de compilación)
ARG VITE_API_URL=http://localhost:5000/api
ENV VITE_API_URL=$VITE_API_URL

# Compilar aplicación para producción
# Genera archivos optimizados en /app/dist
RUN bun run build

# ==========================================
# ETAPA 2: Producción (Servidor Nginx)
# ==========================================
FROM nginx:alpine as production

# Copiar archivos compilados desde la etapa anterior
COPY --from=build /app/dist /usr/share/nginx/html

# Copiar configuración personalizada de Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Exponer puerto 80 (HTTP)
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Nginx se ejecuta en foreground (necesario para Docker)
CMD ["nginx", "-g", "daemon off;"]

# ============================================
# TAMAÑO FINAL DE LA IMAGEN
# ============================================
# Build stage: ~500MB (con Bun + node_modules)
# Production stage: ~25MB (solo Nginx + archivos estáticos)
#
# Solo la "production stage" se incluye en la imagen final
# ============================================

# ============================================
# CÓMO USAR ESTE DOCKERFILE
# ============================================
#
# Build con variable de entorno:
#   docker build --build-arg VITE_API_URL=https://api.miapp.com/api -t crm-frontend .
#
# Run:
#   docker run -p 3000:80 crm-frontend
#
# Con docker-compose:
#   docker-compose up frontend
#
# ============================================
