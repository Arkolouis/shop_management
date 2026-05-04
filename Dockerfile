# Build the Flutter web app in a Flutter-enabled builder image
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Cache pub dependencies when possible
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the app source and build the web release bundle
COPY . .
RUN flutter build web --release --base-href /

# Serve the compiled web app with nginx
FROM nginx:stable-alpine AS runtime
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
