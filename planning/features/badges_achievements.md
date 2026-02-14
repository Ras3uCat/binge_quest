# Feature: Badges & Achievements

## Status
Completed

## Overview
Gamify the watchlist experience by awarding badges for various milestones, genres, and streaks.

## Acceptance Criteria
- [ ] Badge data model implemented in Supabase
- [ ] Logic to detect badge unlocks (e.g., finishing a series, watching 5 horror movies)
- [ ] In-app notifications when a badge is unlocked
- [ ] Profile section to display earned badges

## Backend Changes
- `badges` table: id, name, description, icon_path, category, criteria_json
- `user_badges` table: id, user_id, badge_id, earned_at
- RLS policies for both tables

## Frontend Changes
- `Badge` model
- `BadgeRepository` to fetch user badges
- `BadgeController` to handle unlock logic and notifications
- UI: Badge display grid on Profile
- UI: Celebration dialog for new unlocks

## QA Checklist
- [ ] Verify badge is awarded immediately upon meeting criteria
- [ ] Verify badge appears on profile after unlock
- [ ] Verify duplicate badges are not awarded
