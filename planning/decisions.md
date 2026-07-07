# 🏛️ BingeQuest Decision Log (ADR)

> **Goal:** Document the 'Why' behind major technical pivots to prevent regressive logic and hallucination loops.

---

## [ADR-NNN] {Title}
- **Date:** YYYY-MM-DD
- **Status:** Proposed | Approved | Superseded
- **Context:** What was the problem or requirement?
- **Decision:** What did we choose to do?
- **Consequences:** What are the new rules/constraints for the agents?

---

## [ADR-001] Controller-level testability seam over repository DI refactor
- **Date:** 2026-07-07
- **Status:** Approved
- **Context:** Every repository in the app (`WatchlistRepository`, `BadgeRepository`, `CalendarRepository`, etc.) uses `static` methods hardwired to the `Supabase.instance.client` singleton via `SupabaseService.client`. This makes repositories fundamentally unmockable with `mocktail` without an app-wide refactor to instance-based, injectable repositories. Writing `calendar_controller_test.dart` required *some* seam for testability.
- **Decision:** Controllers that need unit tests take an optional constructor-injected callable interface (e.g. `CalendarEventsFetcher`) that defaults to wrapping the static repository call. Repositories stay static and untouched. Repository-level RPC/query behavior itself is not unit-testable under this pattern — verify via manual QA or (future) integration tests against a local Supabase instance.
- **Consequences:** Future controller tests should follow the same pattern (small injectable interface per controller, not a repository refactor) unless/until a decision is made to migrate the whole repository layer to instance-based DI. Repository-level test coverage remains a known gap.

---
