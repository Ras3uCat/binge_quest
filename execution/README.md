# Execution Layer (Control Panel)

This directory contains the source of truth for all runnable code.

## 🛠️ Developer Commands
| System | Command | Purpose |
| :--- | :--- | :--- |
| **Flutter** | `flutter pub get` | Install dependencies |
| **Flutter** | `flutter run` | Start the app |
| **Flutter** | `dart run build_runner build` | Generate reactive code |
| **Supabase**| `supabase start` | Start local backend |
| **Supabase**| `supabase db push` | Apply migrations |

## 📂 System Mapping
- `/frontend/flutter`: Main UI logic (GetX + Material3).
- `/backend/supabase`: DB schema, RLS, and Edge Functions.
- `/backend/payments`: Stripe webhook handlers and logic.

## 📜 Execution Rules
1. **Never** modify files in `lib/core` without Architect approval.
2. **Always** run `flutter test` before committing UI changes.
3. All code must stay under the **300-line limit** per file.