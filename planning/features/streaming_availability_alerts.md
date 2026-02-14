# Feature: Streaming Availability Alerts

## Status
TODO

## Overview
Alert users when items on their watchlist become available on new streaming platforms. Particularly useful for theatrical releases added to watchlist that later come to streaming.

## Related
- Extends `push_notifications.md` infrastructure
- Uses existing streaming provider data from TMDB

## User Stories
- As a user, I want to know when a movie I added in theaters becomes streamable
- As a user, I want to be alerted when a show I'm watching adds a new streaming option
- As a user, I want to control which streaming services I care about

## Acceptance Criteria
- [ ] Push notification when watchlist item gains new streaming option
- [ ] Notification shows which platform(s) now have the content
- [ ] User can set preferred streaming services in settings
- [ ] Only alert for subscription services (not rent/buy) by default
- [ ] Option to include rent/buy alerts
- [ ] In-app notification history

## Data Model

### user_streaming_preferences
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to users |
| provider_id | INTEGER | TMDB provider ID |
| provider_name | TEXT | e.g., "Netflix" |
| notify_enabled | BOOLEAN | Alert for this service |
| created_at | TIMESTAMPTZ | - |

### streaming_change_events
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| tmdb_id | INTEGER | Content TMDB ID |
| media_type | TEXT | 'movie' or 'tv' |
| provider_id | INTEGER | New provider ID |
| provider_name | TEXT | Provider name |
| change_type | TEXT | 'added' or 'removed' |
| detected_at | TIMESTAMPTZ | When discovered |

## Backend Changes
- Migration for preference and event tables
- Store last-known streaming providers per content in `content_cache`
- Background job to detect provider changes during backfill
- Compare new vs cached providers, emit events for additions
- Integration with push notification system

## Frontend Changes
- Streaming preference selector in Settings
- Notification cards for streaming alerts
- Deep link from notification to content detail

## Detection Logic
```
On content backfill:
1. Fetch current providers from TMDB
2. Compare to cached providers in content_cache
3. For each NEW provider:
   a. Insert streaming_change_event
   b. Find all users with this item in watchlist
   c. Filter to users who have this provider in preferences
   d. Queue push notification
4. Update cached providers
```

## Dependencies
- Push notification infrastructure
- Content backfill system (already exists)
- TMDB watch provider data (already fetched)

## QA Checklist
- [ ] Alert received when new streaming option added
- [ ] No alert for rent/buy options (unless enabled)
- [ ] Respects user's preferred services
- [ ] Notification deep links to content
- [ ] Can disable alerts per-service
