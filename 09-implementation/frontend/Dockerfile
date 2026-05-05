# PTIT Contest Frontend — Flutter web build, served by nginx
# Multi-stage: builder (Flutter SDK) → runtime (nginx slim)

FROM ghcr.io/cirruslabs/flutter:3.27.1 AS builder
WORKDIR /app

# Cache pubspec deps
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# Copy source và build
COPY . .

# API_BASE truyền lúc build (vd: --build-arg API_BASE=https://api.example.com)
ARG API_BASE=http://localhost:8000
RUN flutter build web --release --dart-define=API_BASE=${API_BASE}

# ================ Runtime ================
FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
HEALTHCHECK --interval=15s --timeout=4s CMD wget -q --spider http://localhost/ || exit 1
