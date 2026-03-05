# Use official Dart image
FROM dart:stable AS build

# Resolve app dependencies
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

# Copy app source code and compile
COPY . .
# Ensure packages are still up-to-date if anything changed
RUN dart pub get --offline
RUN dart compile exe bin/dart_domain_resolver.dart -o bin/server

# Build minimal serving image from AOT-compiled `/server` and required system libraries
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/bin/server /app/server

# Server runs on port 8080 by default, but is overridable via the PORT environment variable
EXPOSE 8080
# Optional PORT environment variable
ENV PORT=8080

CMD ["/app/server"]
