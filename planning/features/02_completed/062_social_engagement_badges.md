# Feature: Social Engagement Badges

## Status
COMPLETE

## Overview
Expand the badge system with a new `social` category covering engagement actions that are already implemented: leaving reviews, creating playlists, adding co-curators, making friends, sharing content externally, and participating in watch parties (as host or guest). Adds 20 new badges via one migration and wires badge checks into the relevant controllers.

## New Badges (`social` category)

### Review Badges
| Name | Icon | Trigger |
|---|---|---|
| First Critic | emoji:🖊️ | Leave 1 review |
| Film Critic | emoji:📰 | Leave 5 reviews |
| Master Critic | emoji:⭐ | Leave 25 reviews |

### Playlist Badges
| Name | Icon | Trigger |
|---|---|---|
| Curator | emoji:📋 | Create 1 playlist |
| Playlist Pro | emoji:🎵 | Create 5 playlists |
| Master Curator | emoji:🏆 | Create 10 playlists |

### Co-Curator Badges
| Name | Icon | Trigger |
|---|---|---|
| Collaborator | emoji:🤝 | Add 1 co-curator |
| Team Player | emoji:👥 | Add 3 co-curators across playlists/watchlists |
| Super Collaborator | emoji:🌟 | Add 10 co-curators across playlists/watchlists |

### Friend Badges
| Name | Icon | Trigger |
|---|---|---|
| First Friend | emoji:👋 | Make 1 friend |
| Social Circle | emoji:🫂 | Have 5 friends |
| Well Connected | emoji:🌐 | Have 25 friends |

### Sharing Badges
| Name | Icon | Trigger |
|---|---|---|
| Spread the Word | emoji:📣 | Share 1 item externally |
| Influencer | emoji:🚀 | Share 10 items externally |
| Hype Machine | emoji:📡 | Share 50 items externally |

### Watch Party Badges
| Name | Icon | Trigger |
|---|---|---|
| Party Starter | emoji:🎬 | Host 1 watch party |
| Host with the Most | emoji:🎉 | Host 5 watch parties |
| Party Crasher | emoji:🥳 | Join 1 watch party |
| Watch Party Regular | emoji:🍿 | Join 5 watch parties |
| Social Butterfly | emoji:🦋 | Host + join 10 watch parties combined |

**Total: 20 badges**

## Acceptance Criteria
- [ ] `badges.category` CHECK constraint accepts `'social'`
- [ ] All 20 new badges seeded in `badges` table with correct `criteria_json`
- [ ] `Badge.isEarned()` handles new criteria types: `reviewsLeft`, `playlistsCreated`, `cocuratorsAdded`, `friendsAdded`, `itemsShared`, `watchPartiesHosted`, `watchPartiesJoined`, `watchPartiesTotal`
- [ ] `BadgeRepository.getUserStats()` fetches counts for all new stat types
- [ ] Badge check triggered after: posting a review, creating a playlist, adding a co-curator, accepting a friend request, sharing an item, starting a watch party, joining a watch party
- [ ] `BadgesScreen` displays new Social section (no UI changes required — groups by category dynamically)
- [ ] `BadgeUnlockDialog` fires correctly for each new badge type
- [ ] Existing 24 badges unaffected

## Backend Changes
- Migration `070_social_engagement_badges.sql`:
  - `ALTER TABLE badges DROP CONSTRAINT badges_category_check` → re-add with `'social'`
  - `INSERT INTO badges` for all 20 new entries
  - `criteria_json` shape: `{"type": "reviewsLeft", "value": 1}` etc.
  - Check `watch_party_badge.dart` for any already-seeded watch party badges to avoid duplicates

## Frontend Changes
- `lib/shared/models/badge_model.dart` — add `isEarned()` cases for 8 new criteria types
- `lib/shared/repositories/badge_repository.dart` — extend `getUserStats()` with new stat queries
- `lib/features/badges/controllers/badge_controller.dart` — pass new stats through `checkAndAwardBadges()`
- Hook `BadgeController.checkForNewBadges()` into:
  - `lib/features/playlists/controllers/playlist_controller.dart` → after `createPlaylist()`
  - `lib/features/watchlist/controllers/watchlist_member_controller.dart` → after adding co-curator
  - `lib/features/social/controllers/watch_party_controller.dart` → after `startWatchParty()` and `joinWatchParty()`
  - Review controller → after posting a review
  - `lib/features/social/controllers/friend_controller.dart` → after `acceptFriendRequest()`
  - `lib/core/services/share_service.dart` → after a successful external share

## QA Checklist
- [ ] Leave a review → First Critic badge unlocks
- [ ] Create a playlist → Curator badge unlocks
- [ ] Add a co-curator → Collaborator badge unlocks
- [ ] Accept a friend request → First Friend badge unlocks
- [ ] Share an item externally → Spread the Word badge unlocks
- [ ] Start a watch party → Party Starter badge unlocks
- [ ] Join a watch party → Party Crasher badge unlocks
- [ ] Reaching milestone thresholds (3, 5, 10, 25, 50) awards the correct tier badge
- [ ] BadgeUnlockDialog appears immediately after each qualifying action
- [ ] Badges screen Social section renders with correct earned/locked visual states
- [ ] No duplicate badge awards on repeat actions
