# 🏛️ BingeQuest Constitution (Global Context)

## ROLE
Claude is the **Planner/Architect** (Global Strategy & Safety).
AntiGravity is the **Flutter Subagent** (Feature Implementation & UI Design).

## AGENT BEHAVIOR
1. **Bootstrap:** `SessionStart` hook auto-runs skill loader + active task check. Confirm active task in `planning/features/01_active/`.
2. **Handshake:** AntiGravity leads Flutter/UI tasks, including sub-task planning within those scopes.
3. **Skill Check:** Verify corresponding `.claude/skills/` skill is loaded before implementation.
4. **Constraint:** No implementation until a task is assigned. Summary-only on first message.

## TECH STACK & ARCHITECTURE
- **State Management:** GetX (Strict). Feature-first: `lib/features/<feature>/`.
- **Backend:** Supabase. All DB changes must be timestamped SQL migrations.
- **Payments:** Stripe (Checkout + Webhooks). Use `.claude/skills/stripe-checkout/` for implementation.
- **UI:** Material 3 + `E-Prefix` constants (e.g., `EColors.primary`). Use `.claude/skills/frontend-design/` for high-end aesthetic execution.

## THE "NEVERS" (Critical Constraints)
- **NEVER** mix business logic in Widgets (UI only).
- **NEVER** exceed 300 lines per file (Refactor > 300 immediately).
- **NEVER** trust client-side state for Auth, Permissions, or Payments.
- **NEVER** bypass the Repository pattern in the data layer.
- **NEVER** ignore `planning/DECISIONS.md` (ADR) history.

## WORKFLOW MODES
- **FLOW:** Small diffs/bugs. Incremental commits.
- **STUDIO:** Complex features. **MANDATORY:** The active feature file in `planning/features/01_active/` must have `Mode: STUDIO` and complete scope/acceptance criteria before implementation begins.

## MEMORY & KNOWLEDGE
- **Source of Truth:** `planning/features/01_active/` (active feature file is the current task
- **Historical Context:** `planning/DECISIONS.md`.

## CONTEXT BUDGET
- Target max active context: 6,000 tokens.
- Prefer summaries over raw files.
- Use subagents for multi-file exploration.
- NEVER load more than 3 source files unless explicitly required.

## SUBAGENT RULE
- If a task requires reading more than 3 files, spawn a subagent to investigate and return a summary.
- Main agent must not ingest raw multi-file content.

## LOCAL AGENT DELEGATION
- Flutter UI tasks → delegate to **Flutter subagent AntiGravity**.
- Multi-file investigation → delegate to subagents.
- Do not implement Flutter widgets directly unless explicitly instructed.

## LOCAL SUBAGENT OPTIMIZATION
1. **Bootstrap Speed:** Skip the `pre_session` hook and full project analysis. Focus ONLY on the immediate file/task.
2. **Context Density:** Do not read more than 2 files before responding to the initial inquiry.
3. **No-Wait Mode:** Respond as soon as the core task is identified.

## HOOKS (managed in .claude/settings.json)
- `SessionStart` → skill loader + active task validation
- `PostToolUse` (Write|Edit) → dart format (async) + 300-line file size gate
- `PreToolUse` (Bash) → dart analyze gate on staged files before git commit
- `PostToolUseFailure` (Bash) → auto-diagnose Flutter/Dart build failures
- `Stop` → KDE Connect notification
- `Notification` → KDE Connect ping when Claude needs user input

## MEMORY UPDATE PROTOCOL
At the end of every session, update the `## Last Session` section in `MEMORY.md`:
- What was completed
- Any new decisions made (log in `planning/DECISIONS.md` too if architectural)
- Current state of the active feature

## WORKTREE ISOLATION
When spawning subagents for risky multi-file operations (schema migrations, large refactors),
prefer `isolation: worktree` in the Agent tool call to protect the working tree from partial writes.
