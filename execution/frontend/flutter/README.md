# BingeQuest — Flutter Frontend

A gamified watchlist tracker that transforms streaming backlog management into a quest.

## Tech Stack

- **Framework:** Flutter (Material 3)
- **State Management:** GetX
- **Backend:** Supabase (Postgres, Auth, Realtime, Edge Functions)
- **Push Notifications:** Firebase Cloud Messaging
- **UI Constants:** `E-Prefix` design system (`EColors`, `ESizes`, `EText`)

## Project Structure

```
lib/
├── core/           # Constants, services, config
├── features/       # Feature-first modules (auth, dashboard, watchlist, social, ...)
└── shared/         # Reusable widgets, models, repositories
```

## Getting Started

```bash
flutter pub get
flutter run
```

Requires a valid `lib/core/config/env.dart` with Supabase and TMDB credentials.
