# Feature: Item Detail — Social Sharing

## Status
TODO

## Priority
Medium — growth/acquisition via organic sharing

## Overview
Add a share button on the movie, TV show, and actor detail pages that opens the native OS share sheet. The share payload includes a human-readable message and a link (TMDB URL or app deep link) for the item.

## Acceptance Criteria
- [ ] A share icon/button is visible on movie, show, and actor detail pages.
- [ ] Tapping it opens the native share sheet (iOS share sheet / Android intent chooser).
- [ ] Share text includes the item title and a usable link.
- [ ] Sharing works for all three content types: movie, TV show, actor/person.
- [ ] If deep links are configured, the link opens the item in the app for recipients who have it installed.

## Backend Changes
None required for basic sharing. If app deep links are added later, a link-routing rule will be needed.

## Frontend Changes
- Add `share_plus` package (or confirm it's already a dependency).
- Add a share `IconButton` to the detail page AppBar actions.
- Compose share text:
  - Movie: `"Check out {title} on BingeQuest! https://www.themoviedb.org/movie/{tmdbId}"`
  - TV Show: `"Check out {title} on BingeQuest! https://www.themoviedb.org/tv/{tmdbId}"`
  - Person: `"Check out {name} on BingeQuest! https://www.themoviedb.org/person/{tmdbId}"`
- Call `Share.share(text)` from `share_plus`.

## Dependencies
- `share_plus` Flutter package.
- TMDB IDs are available on detail page models.

## QA Checklist
- [ ] Share button visible on movie detail page.
- [ ] Share button visible on TV show detail page.
- [ ] Share button visible on actor/person detail page.
- [ ] Tapping share opens OS share sheet with correct title and link.
- [ ] Shared link opens correctly in browser (TMDB page loads).
