# shop_management

## Getting Started

This project is a starting point for a shop management system using flutter.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Docker

This repository includes a Docker build and compose setup for the Flutter web app.

- Build and run the production web image:

```bash
docker-compose up --build
```

Then open `http://localhost:8080`.

- Run the development web server with hot reload inside a container:

```bash
docker-compose run --service-ports dev
```

Then open `http://localhost:5000`.
