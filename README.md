# Dart Domain Resolver

This project is a microservice that connects to the Freename registry to provide Web3 domain resolution (e.g., resolving `0x...` into a `.moon` domain, or vice versa).

It wraps `web3dart` to query Freename smart contracts across multiple networks (Ethereum, Polygon, Base, etc.).

## Setup

1. Rename `.env.example` to `.env`.

   ```bash
   cp .env.example .env
   ```

2. Set your `ALCHEMY_API_KEY`.
3. (Optional) Set your `PORT` (defaults to 8080).

## Running Locally

Run the following command to start the HTTP server:

```bash
dart run bin/dart_domain_resolver.dart
```

You can then test it:

```bash
curl http://localhost:8080/resolve/example.moon
curl http://localhost:8080/resolve/0x123...
```

## Deploying on Coolify

To deploy this microservice on Coolify via Docker, you must set the following **Environment Variables** in the Coolify dashboard for this project:

- `ALCHEMY_API_KEY`: Your Alchemy API key (Required)
- `PORT`: Define the port the server listens on (e.g., `8080`, `3000`). If left blank, it defaults to `8080`.

The provided `Dockerfile` will automatically compile the Dart application statically and serve it from a lightweight image.
