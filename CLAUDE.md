# Claude Shared Memory
## Mandatory Startup Behavior (Read First)
On the first message of any new session, the agent must:
1. Read `claude.md` and `agents.md` completely
2. Identify its assigned role(s)
3. Confirm understanding of:
   - Project file structure
   - FLOW vs STUDIO modes
   - Authority boundaries
   - That Antigravity owns planning, roadmap, and decisions
4. Do not implement, edit, or generate code
5. Respond only with a summary and wait for explicit task assignment

## Project
BingeQuest full-stack application.

Target platforms:
- Android
- iOS
- Web (optional)

## Frontend
- Flutter (stable)
- GetX for state management
- No business logic in widgets
- Controllers handle all reactive state
- Feature-first architecture in lib/features/<feature>
- Reusable widgets in lib/shared/widgets
- Keep files short; extract large widgets or logic to new files
- Apply E-prefixed constants
- Each feature lives in `lib/features/<feature>/`
- Each feature may contain:
  - controllers/
  - screens/
  - widgets/
  - models/
- Shared widgets live in `lib/shared/widgets`
- Core utilities live in `lib/core`

## Backend
- Supabase preferred; Firebase fallback
- API-first design
- All schema changes require migrations
- Row Level Security enabled
- Repositories abstract all database logic
- Backend services live in execution/backend
- Tests live in /tests
- Never trust client state for auth or payments

## Payments
- Stripe is source of truth
- Webhooks are authoritative
- Client should never set subscription state
- Webhook handlers and subscription logic live in execution/backend/payments

## QA
- Unit tests mandatory before integration or Chrome QA
- Chrome QA for auth, checkout, and regression flows
- QA reports saved in /qa/reports
- QA scripts should be self-contained and reusable
- Keep scripts short and modular

## Rules
- Never expose production secrets
- Prefer clarity over cleverness
- Small, incremental changes

## Naming Conventions
- All constant classes must start with "E" (EColors, ESizes, EImages, EText)
- Methods and variables use lowerCamelCase
- Controllers: suffix with Controller (e.g., AuthController)
- Widgets: suffix with Widget if reusable (e.g., PlaceholderButtonWidget)

## File Guidelines
- Keep files 150–300 lines max
- Modularize features; do not mix unrelated concerns
- Refactor large functions/classes/widgets into new files
- Refactors should preserve functionality
- Use reusable components and helpers
- Maintain consistent structure across features
- Prefer using reusable widgets to maintain consistency throughout.

## File Structure
/Project
├── CLAUDE.md               # Shared memory & coding rules
├── AGENTS.md               # Agent roles & responsibilities
├── planning/
│   ├── roadmap.md
│   ├── features/
│   ├── current_task.md
│   └── decisions.md
├── execution/
│   ├── frontend/
│   │   └── flutter/
│   │       └── lib/       # main.dart + features/core/shared structure
│   ├── backend/
│   │   ├── supabase/
│   │   ├── firebase/
│   │   └── api/
│   ├── payments/
│   │   └── stripe/
│   └── README.md
├── tests/
│   ├── unit/
│   └── integration/
├── qa/
│   ├── chrome/
│   │   ├── auth_flows.md
│   │   ├── stripe_checkout.md
│   │   └── regression.md
│   └── reports/
├── .cloud/
│   └── skills/
│       ├── flutter_dev/
│       ├── backend_dev/
│       └── qa_browser/
├── agents/
│   └── workflows/
├── ops/
│   ├── ci/
│   └── scripts/
└── README.md

## Modes
### FLOW (default)
- Small, safe changes
- Bug fixes, minor UI updates, local refactors
- Keep diffs small

### STUDIO
- Multi-step features
- Backend schema changes or migrations
- Cross-feature refactors
- Must document impact and consult Architect / Planner

## Collaboration
- Agents communicate via markdown:
  - planning/current_task.md
- Planner breaks features into steps and acceptance criteria
- Claude Code implements Flutter + backend code
- QA validates via tests and Chrome
- Architect (Claude) approves major refactors or schema changes

## FEATURE TEMPLATE
# Feature: Feature Name
Mode: STUDIO or FLOW
Assigned To: SELECT ENGINEER(s)

## Summary
Summary of goal goes here

## Acceptance Criteria
- 

## Dependencies
- 

## Tasks
1. Planner: outline steps in planning/features/<feature>.md
2. Implementer: create files in execution/...
3. QA: add tests or QA scripts

## Notes
- Files must remain short
- Follow "E" constant convention
- Refactors go in new files
