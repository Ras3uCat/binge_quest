# Feature: Reviews & Ratings

## Status
Completed

## Overview
Allow users to rate (1-5 TV screens) and review content. Reviews are displayed at the bottom of ContentDetailSheet and shared across the community.

## Acceptance Criteria
- [ ] 1-5 "TV Screen" rating selector (interactive icons)
- [ ] Optional text review (500 char limit)
- [ ] Reviews section at bottom of ContentDetailSheet
- [ ] Display reviewer usernames
- [ ] User can edit/delete their own review
- [ ] Sort by newest first (default)
- [ ] Average BingeQuest rating in header

## Backend Changes
- `reviews` table: id, user_id, tmdb_id, media_type, rating, review_text (500 char limit)
- RLS policies for community reading and owner writing
- `get_average_rating` RPC function
- Join with `users` table for display names

## Frontend Changes
- `Review` model (with username support)
- `ReviewRepository`
- `TvRatingSelector` widget
- `ReviewsSection`, `ReviewCard`, and `ReviewFormSheet` widgets

## Future Scope (v2)
- Helpful votes on reviews
- "Most helpful" sort option
- Review reporting/moderation

## QA Checklist
- [ ] Verify rating is saved correctly
- [ ] Verify reviews from other users are visible
- [ ] Verify usernames display correctly
- [ ] Verify 500 char limit enforced
- [ ] Verify user can only edit their own review
- [ ] Verify reviews sorted by newest first
