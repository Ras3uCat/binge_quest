# Feature: Add Friend — Exact Match Hint Text

## Status
TODO

## Priority
Low — minor UX polish, reduces support confusion

## Overview
The Add Friend search field currently returns no results unless the user types an exact email or username. Users expect fuzzy/partial matching and get confused when nothing appears. Add a helper text note below the search field to set expectations.

## Acceptance Criteria
- [ ] A helper/hint text is displayed below (or inside) the search field on the Add Friend screen.
- [ ] The hint communicates that the full email or username must be entered exactly.
- [ ] The hint is visible before the user starts typing (not just on empty results).
- [ ] Optional: mention case-sensitivity if applicable.

## Backend Changes
None.

## Frontend Changes
- On the Add Friend / friend search screen, add a `Text` widget below the `TextField`:
  - Suggested copy: `"Enter an exact email or username to find someone."`
  - Style: subdued / caption size, using `EColors` theme secondary text color.
- Alternatively, use `InputDecoration.helperText` on the search field itself.

## QA Checklist
- [ ] Hint text visible on screen load before any input.
- [ ] Hint text does not obscure search results when they appear.
- [ ] Hint text matches the app's typography/color system.
