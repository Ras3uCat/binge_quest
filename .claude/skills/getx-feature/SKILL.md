---
name: getx-feature
description: Scaffold and implement GetX features following the project's feature-first + centralized-controller architecture. Trigger when creating a new feature, wiring a controller, setting up bindings, or adding routes.
when_to_use: Any task involving a new GetX feature, controller creation, binding wiring, route registration, or GetX dependency injection setup.
scope: lib/features/, lib/controllers/, lib/bindings/, lib/routes/
authority: medium
alwaysApply: false
---

# GetX Feature Scaffold Skill

## Architecture Rules (Non-Negotiable)
- **Controllers**: `lib/controllers/<feature>_controller.dart` ONLY. Never inside feature folders.
- **Views**: `lib/features/<feature>/views/` — extend `GetView<TController>`, never StatefulWidget for business state.
- **Repositories**: `lib/features/<feature>/repositories/` — data access only, return `Either<Failure, T>`.
- **Models**: `lib/features/<feature>/models/` — pure Dart, `fromJson`/`toJson` only.
- **Bindings**: Central = `app_bindings.dart` for always-on; route-level = `lib/bindings/route_bindings/` for heavy screens.
- **300-line rule**: Extract immediately when approaching limit.

## Feature Folder Structure
```
lib/features/<feature>/
├── <feature>.dart              ← barrel: exports views, models (NOT controller)
├── views/
│   └── <feature>_view.dart
├── repositories/
│   └── <feature>_repository.dart
└── models/
    └── <feature>_model.dart
```

## Barrel Rule
The feature barrel (`<feature>.dart`) exports views and models only.
Controllers are NOT re-exported from feature barrels — import from `lib/controllers/` directly.

## Dependency Injection Flow
```
AppBindings (app start)
  └── registers always-on services + global controllers

<Feature>Binding (route push)
  └── registers repository + feature controller
  └── destroyed automatically when route is popped
```

See `DETAILED_GUIDE.md` for complete file templates and routing wiring.
