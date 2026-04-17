# Feature: Watchlist Dashboard — Pill Selector UX

## Status
TODO

## Priority
Medium — improves dashboard scannability and consistency

## Overview
Replace the watchlist dropdown on the dashboard with a horizontal scrollable pill/badge selector, matching the filter chip style used in the Recent Progress section. Move the "Create New" action to be right-aligned next to the "Watchlists" section heading (matching the "See All" pattern).

## Acceptance Criteria
- [ ] The watchlist dropdown is removed from the dashboard.
- [ ] A horizontal row of pill/chip buttons replaces it, one per watchlist.
- [ ] The active watchlist pill is highlighted (selected state).
- [ ] Tapping a pill switches the displayed watchlist content.
- [ ] "Create New" appears as a right-aligned text action in the "Watchlists" section header.
- [ ] Tapping "Create New" opens the existing create-watchlist flow.
- [ ] If the user has many watchlists, the pill row scrolls horizontally.
- [ ] An "All" pill is shown first (if applicable) to show combined content.

## Backend Changes
None — watchlist data already available.

## Frontend Changes
- Remove `DropdownButton` (or equivalent) from the watchlist dashboard section.
- Add a `SingleChildScrollView(scrollDirection: Axis.horizontal)` wrapping a `Row` of `FilterChip` / `ChoiceChip` widgets.
- Update the section header `Row` to include a right-aligned `TextButton('Create New', onPressed: ...)`.
- Keep controller logic the same — only the selection widget changes.
- Match chip styling to the existing Recent Progress filter chips (same `EColors`, border radius, padding).

## QA Checklist
- [ ] Dropdown no longer present on dashboard.
- [ ] All user watchlists shown as pills.
- [ ] Selecting a pill updates the displayed list.
- [ ] "Create New" header button opens create flow.
- [ ] Horizontal scroll works when pills overflow.
- [ ] Selected pill styling is visually distinct.
- [ ] No layout overflow errors on small screen sizes.
