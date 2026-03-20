# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run                  # interactive platform selection
flutter run -d macos         # macOS desktop
flutter run -d chrome        # web browser
flutter run -d android       # Android device/emulator

# Build
flutter build apk            # Android APK
flutter build ios            # iOS (requires Xcode on macOS)
flutter build web            # Web
flutter build macos          # macOS desktop

# Code quality
flutter analyze              # static analysis / linting
flutter test                 # run tests

# Regenerate app icons (after changing assets/logo.png)
flutter pub run flutter_launcher_icons:main
```

## Architecture

This is a Flutter app following a three-layer clean architecture:

```
lib/
├── core/constants/        # App-wide config (Supabase URL/key)
├── data/
│   ├── models/            # Data classes with fromJson/toJson
│   └── services/          # SupabaseService wrapper
└── presentation/
    ├── providers/         # Business logic (ChangeNotifier)
    └── screens/           # UI screens
```

**State management:** Provider + ChangeNotifier pattern. `get_it` is available as a service locator but Provider is the primary mechanism used in the codebase.

**Backend:** Supabase (PostgreSQL + Auth + Edge Functions). All data access goes through `SupabaseService` in `lib/data/services/supabase_service.dart`. Credentials are in `lib/core/constants/app_config.dart`.

**Two user roles with separate flows:**
1. **Agent de santé** — authenticated agents in the `agents` table get the full dashboard (`MainContainer` with bottom nav)
2. **Patient** — authenticated users NOT in the `agents` table get the patient portal (`PatientDashboard`)

The `SplashScreen` routes between these after checking `supabase.auth.currentSession` and whether the user exists in the `agents` table.

## Key Providers

**`AuthProvider`** — login, signup, logout, password reset, loads `agentName`/`hospitalName` from the `agents` table.

**`PatientProvider`** — all patient and appointment logic: dashboard stats, CRUD for patients and `rendez_vous`, PDF report generation, "perdus de vue" (missed appointments). Dashboard data is fetched in parallel using `Future.wait`. The `reset()` method must be called on logout to clear state.

## Database Tables

- `agents` — healthcare workers (full_name, centre_sante, adresse, role)
- `patients` — patient records, supports parent–child via `mother_id`, filtered by `created_by`
- `rendez_vous` — appointments with statuses: `PLANIFIE`, `EFFECTUE`, `MANQUE`

Appointment statuses and vaccine names (`BCG`, `PENTA`, `POLIO`, `ROUGEOLE`, `FIÈVRE JAUNE`, `ROR`) are magic strings used directly; keep them consistent.

## Edge Functions

SMS invitations are sent via the Supabase Edge Function `send-invite`, called from `PatientProvider.addPatient()`.

## Language

All UI text and code comments are in French.
