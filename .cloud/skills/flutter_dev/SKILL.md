# Flutter Development Skill
Flutter app root is at execution/frontend/flutter.
All Dart source code lives under lib/.

## Stack
- Flutter (stable)
- GetX
- Material 3
- Feature-based structure

## Structure
execution/frontend/flutter/lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
│       ├── themes.dart
│       └── custom_themes/
├── bindings/
│   └── general_bindings.dart
├── common/
│   └── widgets/
│       ├── buttons/
│       ├── cards/
│       ├── dialogs/
│       └── loaders/
├── data/
│   ├── repositories/
│   │   ├── authentication/
│   │   └── user/
│   └── services/
│       ├── cloud_storage/
│       └── payments/
├── features/
│   ├── auth/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── screens/
│   │   └── widgets/
│   └── dashboard/
│       ├── controllers/
│       ├── models/
│       ├── screens/
│       └── widgets/
├── routes/
└── utils/
    ├── constants/
    │   ├── colors.dart
    │   ├── enums.dart
    │   ├── images.dart
    │   ├── sizes.dart
    │   └── text.dart
    ├── device/
    │   └── device_utility.dart
    └── helpers/


## Rules
- No logic in widgets
- Controllers manage state
- Services handle API calls
- Strong null safety
- Widgets only handle UI
- Use lib/features/<feature>/ structure

## When to Use
Whenever creating or modifying Flutter UI, state, routing, or tests.
- Creating Flutter screens
- Adding features
- Refactoring UI or state

## Naming Conventions
- Constants: Always start class name with "E", e.g., `EColors.primary`.
- Controllers: End with "Controller".
- Widgets: Add "Widget" suffix for reusable components.
- Keep feature folders and class names aligned.

## Refactoring and File Size Rules
- Files should be short and focused. If a class or widget is too large, split it.
- Create a new file for extracted logic or widgets; do not clutter existing files.
- Use clear folder placement for refactored files: e.g., lib/features/<feature>/widgets/<widget_name>.dart
- Keep each file understandable on its own.
- When asked to refactor, always preserve functionality and test coverage.

