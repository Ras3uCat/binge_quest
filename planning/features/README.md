# 📂 Features Directory
This folder contains one file per feature describing behavior and requirements.
- **Roadmap:** Defines *when* to build.
- **This Directory:** Defines *what* to build.

## 📜 Rules
* **One feature per file:** Avoid "Mega-features." Split into `sub_features` if the file exceeds 200 lines.
* **Snake_case naming:** `badges_achievements.md`.
* **Acceptance Criteria:** Must be binary (Pass/Fail).
* **Context Isolation:** Reference existing ADRs (from `decisions.md`) instead of re-explaining architecture.

## 👥 Agent Hand-off (New)
* **Planner:** Responsible for drafting these feature files.
* **Architect:** Must approve the "Scope" and "Backend" sections before work begins.
* **Flutter Subagent:** Focuses 100% on the **UX** and **Acceptance Criteria** sections.

---

## 📄 Minimal Template
# Feature: [Name]

## 📝 Summary
High-level "pitch" of the feature.

## 🎯 Scope
- [ ] Included: X, Y, Z
- [ ] **NOT** Included: A, B (Crucial for preventing scope creep)

## 🎨 UX & Interaction
- Flow: [Step 1] -> [Step 2]
- Key Widgets: List any specific `E-Prefix` components needed.

## 💾 Backend / Data Layer
- **Schema:** Changes needed to Supabase.
- **RLS:** New policies required?
- **Skills:** Does this require `payments_dev` or `auth_dev`?

## 🏁 Acceptance Criteria
- [ ] Criterion 1 (e.g., "User sees toast on success")
- [ ] Criterion 2 (e.g., "Stripe metadata includes quest_id")