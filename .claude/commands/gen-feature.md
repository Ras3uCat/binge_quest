Scaffold a new feature module: $ARGUMENTS

Generate the complete file structure for a new module following this project's architecture.

**Input expected:** Feature name (e.g., "user profile", "notifications", "search")

**Steps:**

1. **Derive the feature slug** from the input (snake_case, e.g., `user_profile`)

2. **Create the module directory structure under `execution/frontend/flutter/lib/features/<slug>/`:**
```
lib/features/<slug>/
├── controllers/
│   └── <slug>_controller.dart
├── views/
│   └── <slug>_view.dart
├── bindings/
│   └── <slug>_binding.dart
└── repositories/               ← only if data access needed
    ├── <slug>_repository.dart           (abstract)
    └── supabase_<slug>_repository.dart  (concrete)
```

3. **Scaffold with correct patterns:**

`<slug>_controller.dart`:
```dart
class <Feature>Controller extends GetxController {
  // RxTypes for reactive state
  // Methods for business logic only — no UI logic
}
```

`<slug>_view.dart`:
```dart
class <Feature>View extends GetView<<Feature>Controller> {
  const <Feature>View({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(...);
}
```

`<slug>_binding.dart`:
```dart
class <Feature>Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<<Feature>Repository>(() => Supabase<Feature>Repository());
    Get.lazyPut<<Feature>Controller>(() => <Feature>Controller());
  }
}
```

`<slug>_repository.dart` (abstract, only if DB access needed):
```dart
abstract class <Feature>Repository {
  // Method signatures only
}
```

`supabase_<slug>_repository.dart` (concrete):
```dart
class Supabase<Feature>Repository implements <Feature>Repository {
  // All Supabase calls isolated here
}
```

4. **Create a backlog feature file:**
```
planning/features/00_backlog/NNN_<slug>.md
```
Use the next sequential ID (check `planning/features/` dirs for the highest existing NNN).

Output a summary of all files created and next steps.
