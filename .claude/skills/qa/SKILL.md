# Browser QA Skill (V2)
**Goal:** Verify functionality via Chrome automation. 
**Focus:** Flutter Web, Supabase Auth, Stripe Checkout.

## 🕹️ Execution Protocol
1. **Scenario Prep:** Read the `Acceptance Criteria` in the `STUDIO_PLAN.md`.
2. **Action:** Navigate to the target URL. Perform actions as a "Naive User" (no assumptions).
3. **Verification:** Check console logs for 400/500 errors. Verify DB state via Supabase MCP if available.
4. **Reporting:** Always save results to `qa/reports/YYYY-MM-DD_feature_name.md`.

## 🧪 High-Stakes Test Flows
- **Auth:** Test Signup -> Email Verification -> Login -> Session Persistence.
- **Stripe:** Test Checkout Success -> Redirect -> Profile Upgrade (Polling check).
- **Regression:** Verify the "Core Loop" (Adding a Quest) still works after UI changes.

## 🛑 Failure Definition
- UI hangs/spinners that never resolve.
- Error toasts appearing on valid input.
- Layout overflows (Material3 rendering issues).

## 📝 Mandatory Report Template
- **Status:** [PASS / FAIL / PARTIAL]
- **Environment:** [e.g., Localhost:5000 / Staging URL]
- **Log Snippets:** [Paste relevant terminal/console errors]
- **Screenshots:** [Note filenames if captured]