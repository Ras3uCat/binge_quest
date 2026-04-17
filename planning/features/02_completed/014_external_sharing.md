# Feature: External Sharing

## Status
Completed

## Overview
Allow users to share their completion milestones, badges, and profile cards to external social media platforms.

## Acceptance Criteria
- [ ] Share button on completion screens and badge unlocks
- [ ] Generate shareable image or text with app link
- [ ] Integration with native share sheet

## Backend Changes
- None

## Frontend Changes
- `ShareService` using `share_plus` package
- UI: Share icons on relevant screens

## QA Checklist
- [ ] Verify share sheet opens with correct content
- [ ] Verify links are valid
