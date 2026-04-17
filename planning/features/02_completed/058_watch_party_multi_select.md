# Feature: Watch Party Multi-Select

## Status
TODO

## Priority
Medium — quality-of-life for users with multiple watch parties per show

## Overview
When a user has more than one watch party associated with the same show, tapping "Watch Party" on the item detail page should present a picker so they can choose which party to open. If only one party matches, navigate directly as today.

## Acceptance Criteria
- [ ] Tapping "Watch Party" with exactly 1 matching party navigates directly (no picker).
- [ ] Tapping "Watch Party" with 2+ matching parties opens a bottom sheet listing each party by name.
- [ ] Selecting a party from the picker navigates to that party's screen.
- [ ] Dismissing the picker without selecting does nothing.
- [ ] Party names and member counts are shown in the picker list.

## Backend Changes
None — existing query for watch parties by `content_id` is sufficient; just filter client-side.

## Frontend Changes
- In the item detail controller, after fetching watch parties for the show, check count.
- If count > 1: show a `Get.bottomSheet` with a `ListView` of party options.
- If count == 1: navigate directly (existing behavior).
- Reuse the bottom sheet decoration pattern from MEMORY (no `isScrollControlled`, compact `ListTile`).

## QA Checklist
- [ ] User with 0 watch parties for show: "Watch Party" button hidden or disabled.
- [ ] User with 1 watch party: navigates directly without picker.
- [ ] User with 2 watch parties: picker appears with both listed.
- [ ] User with 3+ watch parties: picker scrolls correctly.
