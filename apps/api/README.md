# HealthTrackMe Backend API

Kotlin/Spring Boot backend for HealthTrackMe. The API stores user health data, medicines, sport activities, wearable devices, friendships, Health Shield progress, export data, authentication state, and AI Detective insights.

## What This Service Does

- Provides versioned REST endpoints under `/api/v1`.
- Uses PostgreSQL with Flyway migrations and JPA/Hibernate entities.
- Supports email/password authentication and Google Sign-In verification.
- Issues JWT tokens and protects user-scoped data when auth is enabled.
- Stores health entries, vitals, sleep, medicines, reminders, sport activities, wearable devices, friends, alerts, and Health Shield state.
- Exports CSV summaries and can send optional email summaries.
- Generates Health Detective insights through Groq when configured, with rule-based fallback logic.

## Stack

| Area | Technology |
| --- | --- |
| Language | Kotlin 2.1 |
| Runtime | Java 25 configured in Maven |
| Framework | Spring Boot 3.5 |
| Data | Spring Data JPA, Hibernate, PostgreSQL |
| Migrations | Flyway |
| Auth | JWT with `jjwt`, Spring Security crypto, Google token verification |
| Email | Brevo, Resend, or SMTP depending on environment variables |
| Tests | JUnit/Spring Boot Test, H2 for test profile |
| Deploy | Docker/Railway |

## Directory Structure

```text
apps/api/
├── pom.xml
├── Dockerfile
├── src/main/kotlin/com/healthwithme/api/
│   ├── config/          Security, CORS, app configuration
│   ├── controller/      REST controllers
│   ├── dto/             Request/response DTOs
│   ├── exception/       Global error handling
│   ├── model/           JPA entities
│   ├── repository/      Spring Data repositories
│   ├── service/         Business logic
│   └── util/            Helpers and export utilities
├── src/main/resources/
│   ├── application.yml
│   └── db/migration/    Flyway SQL migrations and seed data
└── src/test/kotlin/     Backend tests
```

## Local Setup

### Prerequisites

- JDK compatible with the Maven configuration. The project is configured for Java 25.
- Docker Desktop for local PostgreSQL.
- PowerShell on Windows if using helper scripts.

### 1. Environment

From the repository root:

```powershell
Copy-Item .env.example .env
```

Useful local variables:

```env
DATABASE_URL=jdbc:postgresql://localhost:5432/healthtrackme
DATABASE_USERNAME=healthtrackme
DATABASE_PASSWORD=healthtrackme
JWT_SECRET=change-this-for-real-use
GOOGLE_OAUTH_ALLOWED_CLIENT_IDS=your-web-client-id.apps.googleusercontent.com
```

Optional features:

```env
GROQ_API_KEY=your-groq-key
GROQ_MODEL=llama-3.3-70b-versatile
APP_MAIL_ENABLED=true
APP_MAIL_FROM=HealthTrackMe <your-verified-sender@example.com>
BREVO_API_KEY=your-brevo-key
```

### 2. Database

From the repository root:

```powershell
docker compose up -d
```

The default database is available on `localhost:5432`.

### 3. Run the API

Using the helper script from the repository root:

```powershell
./scripts/run-api-local.ps1
```

Or directly:

```powershell
cd apps/api
./mvnw.cmd spring-boot:run
```

API base URL:

```text
http://localhost:8080/api/v1
```

## Configuration

Main configuration lives in `src/main/resources/application.yml`.

| Variable | Purpose | Default |
| --- | --- | --- |
| `PORT` | HTTP server port | `8080` |
| `DATABASE_URL` | JDBC URL | local PostgreSQL |
| `DATABASE_USERNAME` | DB user | `healthtrackme` |
| `DATABASE_PASSWORD` | DB password | `healthtrackme` |
| `JWT_SECRET` | JWT signing secret | local placeholder |
| `JWT_EXPIRATION_SECONDS` | Token lifetime | 30 days |
| `AUTH_ENABLED` | Enforce JWT on API endpoints | `true` |
| `GOOGLE_OAUTH_ALLOWED_CLIENT_IDS` | Allowed Google OAuth clients | empty |
| `GROQ_API_KEY` | Enables AI Detective | empty |
| `GROQ_MODEL` | Groq model name | `llama-3.3-70b-versatile` |
| `APP_MAIL_ENABLED` | Enables email summaries | `false` |
| `BREVO_API_KEY` | Brevo email provider | empty |
| `RESEND_API_KEY` | Resend email provider | empty |
| `SMTP_USERNAME` / `SMTP_PASSWORD` | SMTP fallback | empty |

## Current Endpoint Groups

All modern endpoints use `/api/v1` unless noted.

### Auth

- `POST /api/v1/auth/login`
- `POST /api/v1/auth/google`
- `GET /api/v1/auth/me`

### Users

- `POST /api/v1/users`
- `GET /api/v1/users`
- `GET /api/v1/users/{id}`
- `PUT /api/v1/users/{id}`
- `PUT /api/v1/users/{id}/password`
- `POST /api/v1/users/{id}/profile-photo`
- `GET /api/v1/users/{id}/weekly-report`
- `PUT /api/v1/users/{id}/weekly-report`
- `DELETE /api/v1/users/{id}`

### Health Entries and Vitals

- `POST /api/v1/health-entries/users/{userId}`
- `POST /api/v1/health-entries/users/{userId}/sync`
- `GET /api/v1/health-entries/{id}`
- `GET /api/v1/health-entries/users/{userId}`
- `GET /api/v1/health-entries/vitals-history`

### Medicines

- `POST /api/v1/medicines/users/{userId}`
- `POST /api/v1/medicines/{id}/dose`
- `GET /api/v1/medicines/{id}`
- `GET /api/v1/medicines/{id}/adherence`
- `PUT /api/v1/medicines/{id}`
- `GET /api/v1/medicines/users/{userId}`
- `GET /api/v1/medicines/users/{userId}/active`
- `DELETE /api/v1/medicines/{id}/dose/today`
- `DELETE /api/v1/medicines/{medicineId}`

### Sport Activities

- `POST /api/v1/sport-activities/users/{userId}`
- `GET /api/v1/sport-activities/{id}`
- `GET /api/v1/sport-activities/users/{userId}`
- `GET /api/v1/sport-activities/users/{userId}/raw`
- `GET /api/v1/sport-activities/users/{userId}/stats`
- `DELETE /api/v1/sport-activities/{id}`

### Wearable Devices

- `POST /api/v1/wearable-devices/users/{userId}`
- `GET /api/v1/wearable-devices/{id}`
- `GET /api/v1/wearable-devices/users/{userId}`
- `POST /api/v1/wearable-devices/{id}/sync`
- `DELETE /api/v1/wearable-devices/{id}`

### Friends

- `GET /api/v1/friends/users/{userId}/leaderboard`
- `GET /api/v1/friends/users/{userId}`
- `GET /api/v1/friends/users/{userId}/requests/incoming`
- `GET /api/v1/friends/users/{userId}/requests/outgoing`
- `POST /api/v1/friends/users/{userId}/requests`
- `POST /api/v1/friends/users/{userId}/requests/{friendshipId}/accept`
- `POST /api/v1/friends/users/{userId}/requests/{friendshipId}/decline`
- `DELETE /api/v1/friends/users/{userId}/{friendshipId}`

### Alerts, Shield, Detective, Export

- `GET /api/v1/health-alerts/{id}`
- `GET /api/v1/health-alerts/users/{userId}`
- `GET /api/v1/health-alerts/users/{userId}/unread`
- `PUT /api/v1/health-alerts/{id}/read`
- `DELETE /api/v1/health-alerts/{id}`
- `GET /api/v1/health-shield/{userId}`
- `GET /api/health-shield/{userId}` legacy compatibility route
- `GET /api/v1/detective/analyze`
- `GET /api/v1/detective/latest`
- `GET /api/v1/detective/history`
- `POST /api/v1/detective/ask`
- `GET /api/v1/export/health-entries/csv/{userId}`
- `GET /api/v1/export/sport-activities/csv/{userId}`
- `GET /api/v1/export/summary/{userId}`
- `POST /api/v1/export/summary/email/{userId}`
- `GET /api/v1/export/all/{userId}`

## Database

The backend uses Flyway migrations in `src/main/resources/db/migration`. Important tables include users, health entries, medicines, sport activities, wearable devices, health alerts, friendships, detective insights, and Health Shield state.

ER diagram:

![ER diagram](../../docs/database/ER-diagram.png)

Seed/demo data is inserted through Flyway migrations, including demo users and richer history data for testing dashboards and reports.

## Testing

```powershell
cd apps/api
./mvnw.cmd clean test
```

For a packaged build:

```powershell
./mvnw.cmd package -DskipTests
```

## Docker and Deploy

Build Docker image locally:

```powershell
cd apps/api
docker build -t healthtrackme-api .
```

The backend is designed for Railway deployment. Railway should provide database and app variables listed above. The service listens on `${PORT:8080}`.

## CI

GitHub Actions workflow: `.github/workflows/backend-ci.yml`

The backend CI pipeline:

- checks out the repository
- sets up Java
- runs Maven tests
- packages the application
- builds the Docker image

## Notes for Future Changes

- Add new schema changes as Flyway migrations, never by changing an already-applied migration.
- Keep API paths under `/api/v1` unless intentionally adding a compatibility route.
- Keep auth and per-user ownership behavior in mind when adding endpoints.
- Update this README whenever a controller or environment variable changes.
