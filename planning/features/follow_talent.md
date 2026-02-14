# Feature: Follow Talent (Actors & Directors)

## Status
Completed

## Overview
Allow users to "follow" actors and directors. When new content featuring followed talent is released or added to TMDB, the user receives a push notification alert.

## User Stories
- As a user, I want to follow my favorite actors so I never miss their new movies/shows
- As a user, I want to follow directors whose style I enjoy
- As a user, I want to manage my followed talent from my profile
- As a user, I want to be notified when followed talent has new content

## Acceptance Criteria
- [ ] Follow/unfollow actors from content detail or search
- [ ] Follow/unfollow directors from content detail
- [ ] "Following" section on user profile showing all followed talent
- [ ] Push notification when new content is detected for followed talent
- [ ] In-app notification center showing recent talent alerts
- [ ] Quick-add to watchlist from notification

## Data Model

### followed_talent
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to users |
| tmdb_person_id | INTEGER | TMDB person ID |
| person_name | TEXT | Cached name |
| person_type | TEXT | 'actor' or 'director' |
| profile_path | TEXT | Cached photo URL |
| created_at | TIMESTAMPTZ | When followed |

### talent_content_events
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| tmdb_person_id | INTEGER | TMDB person ID |
| tmdb_content_id | INTEGER | New content TMDB ID |
| media_type | TEXT | 'movie' or 'tv' |
| content_title | TEXT | Title of new content |
| detected_at | TIMESTAMPTZ | When discovered |

## Backend Changes
- Migration for `followed_talent` and `talent_content_events` tables
- RLS policies (users can only see their own follows)
- Background job or Edge Function to check TMDB for new content by person
- Integration with push notification system

## Frontend Changes
- `FollowedTalentRepository`
- `FollowedTalentController` (GetX)
- UI: Follow button on person cards/detail
- UI: "Following" tab on profile screen
- UI: Talent notification cards

## Dependencies
- Push notification infrastructure (see `push_notifications.md`)
- TMDB person endpoints already available

## Technical Notes
- TMDB provides `/person/{id}/combined_credits` for all content by person
- Poll frequency: Daily check for new content
- Cache person details to reduce API calls
- Consider rate limiting TMDB calls for users following many people

## QA Checklist
- [ ] Can follow/unfollow actor from content detail
- [ ] Can follow/unfollow director from content detail
- [ ] Following list displays on profile
- [ ] Notification received when new content detected
- [ ] Tapping notification shows content detail
- [ ] Unfollowing stops future notifications
