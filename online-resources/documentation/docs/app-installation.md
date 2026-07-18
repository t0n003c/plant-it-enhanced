# App installation

Assume the server is reachable at `192.168.1.5`, the web app uses port `3000`, and the API uses
port `8080`. Replace those values with the host, ports, or HTTPS names from your deployment.

## Web app

1. Open `http://192.168.1.5:3000`.
2. When asked for the server URL, enter `http://192.168.1.5:8080` without `/api`.
3. Create an account or sign in.

The web app stores pending Trail Journal drafts in durable browser storage. Use a normal browser
profile, allow site storage, and do not clear site data while drafts are pending. The Trail Journal
shows pending or failed synchronization explicitly.

## HTTPS and reverse proxies

Camera file selection works over HTTP on a local network, but browser geolocation generally
requires HTTPS (or localhost). For full trail capture on a phone, expose both the web and API routes
through HTTPS and enter the public API base URL during setup. Configure `ALLOWED_ORIGINS` if you do
not use the default `*` value.

A reverse proxy must route the frontend to container port `3000` and the API hostname or path to
container port `8080`. Do not proxy MySQL or Redis.

For the recommended Cloudflare Tunnel → Nginx Proxy Manager deployment, use one public hostname:
route `/` to `plantit-server:3000` and `/api/` to `plantit-server:8080`. Open that HTTPS hostname
and enter the same origin, such as `https://plants.example.com`, as the server URL—do not append
`/api`. Configure the tunnel to target Nginx Proxy Manager, not the Plant-it container directly.

## Android

The enhanced web app works in Chrome and can be added to the home screen. A native enhanced APK can
also be downloaded from the
[Plant-it Enhanced releases](https://github.com/t0n003c/plant-it-enhanced/releases/latest) when an
APK is attached to the release.

The F-Droid package is the upstream Plant-it client. Its release cadence and feature set may differ
from this maintained fork, especially for Trail Journal and offline capture.

## iPhone and iPad

1. Open the HTTPS web-app address in Safari.
2. Tap **Share**.
3. Choose **Add to Home Screen**.
4. Open the installed web app and enter the API base URL when prompted.

Keep the same Safari/PWA site data until pending field observations have synchronized. Native iOS
packaging is not currently published by this fork.

## Verify the connection

After signing in, open **More → System diagnostics**. Confirm the application version, database,
and cache are healthy. Provider entries may show **not configured** when their optional API keys are
blank; common-name search and the bundled care catalog still work.

The REST API and Swagger UI are available at
`http://192.168.1.5:8080/api/swagger-ui/index.html` for administrators and integrations.
