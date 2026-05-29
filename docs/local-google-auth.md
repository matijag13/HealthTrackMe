# Local Google Auth

Each developer should create a local `.env` file once:

```powershell
Copy-Item .env.example .env
```

Then replace the Google placeholders in `.env` with the real Google OAuth Web Client ID:

```env
GOOGLE_OAUTH_ALLOWED_CLIENT_IDS=your-web-client-id.apps.googleusercontent.com
GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

For local web testing these two values are usually the same Web Client ID. The `.env` file is ignored by Git and must not be committed.

Start the backend:

```powershell
.\scripts\run-api-local.ps1
```

Start the Flutter web app:

```powershell
.\scripts\run-flutter-local.ps1
```
