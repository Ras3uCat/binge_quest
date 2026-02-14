# Backend Development Skill (V2)
**Scope:** `execution/backend/` | **Primary:** Supabase | **Secondary:** Stripe

## 🏗️ Architectural Patterns
- **Database:** PostgreSQL via Supabase. All changes MUST be in `supabase/migrations/`.
- **Security:** Row Level Security (RLS) is the default. Every table must have a policy.
- **Logic:** Business logic lives in **Repositories** (`execution/backend/repositories/`).
- **External:** Third-party logic (Stripe, TMDB) lives in **Services** (`execution/backend/services/`).

## 🛠️ Implementation Rules
- **Migrations:** Use timestamped SQL files. Never edit production DB directly.
- **Auth:** Use Supabase Auth (JWT). Never store passwords in plain text.
- **Validation:** Never trust client-side data. Re-verify all "Pro" status on the server.
- **Stripe:** Use Webhooks as the authoritative source for subscription state.

## 🧪 Testing Protocol
- Write PostgreSQL unit tests for RLS policies.
- Write Dart/Node.js tests for Edge Functions.
- All new API endpoints require a mock-test in `/tests`.

## 🔄 Naming Conventions
- Tables: `snake_case` (e.g., `user_quests`).
- Functions: `camelCase`.
- Repositories: Suffix with `Repository`.