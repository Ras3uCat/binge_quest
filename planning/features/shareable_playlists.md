# Feature: Shareable Playlists

## Status
TODO

## Overview
Allow users to create curated playlists of content they can share externally via social media or direct link. Unlike watchlists (personal tracking), playlists are for sharing recommendations with others. Recipients can view the playlist and add individual items to their own watchlist.

## User Stories
- As a user, I want to create a "Best Rom-Coms" playlist to share with friends
- As a user, I want to share my "Top 10 of 2024" list on social media
- As a user, I want to browse a friend's playlist and add items to my watchlist
- As a user, I want to update my playlists over time

## Acceptance Criteria
- [ ] Create playlist with name and optional description
- [ ] Add items to playlist (movies and/or TV shows)
- [ ] Reorder items in playlist
- [ ] Set playlist visibility (public link or private)
- [ ] Generate shareable link
- [ ] Share to social platforms (Twitter, Instagram, etc.)
- [ ] Recipients can view playlist without account
- [ ] Logged-in recipients can add items to their watchlist
- [ ] Edit/delete own playlists

## Playlist vs Watchlist

| Feature | Watchlist | Playlist |
|---------|-----------|----------|
| Purpose | Personal tracking | Sharing/recommendations |
| Progress tracking | Yes | No |
| Public shareable | No | Yes |
| Co-owners | Yes | No (single creator) |
| Item limit | Unlimited | Optional cap (e.g., 25) |

## Data Model

### playlists
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to users (creator) |
| name | TEXT | Playlist name |
| description | TEXT | Optional description |
| slug | TEXT | URL-friendly ID for sharing |
| visibility | TEXT | 'public' or 'private' |
| cover_image | TEXT | Custom or auto from first item |
| item_count | INTEGER | Cached count |
| view_count | INTEGER | Times viewed |
| created_at | TIMESTAMPTZ | - |
| updated_at | TIMESTAMPTZ | - |

### playlist_items
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| playlist_id | UUID | FK to playlists |
| tmdb_id | INTEGER | Content TMDB ID |
| media_type | TEXT | 'movie' or 'tv' |
| title | TEXT | Cached title |
| poster_path | TEXT | Cached poster |
| position | INTEGER | Order in playlist |
| note | TEXT | Optional creator note |
| added_at | TIMESTAMPTZ | - |

## Sharing Implementation

### Shareable Link Format
```
https://bingequest.app/playlist/{slug}
or
https://bingequest.app/p/{slug}
```

### Deep Link Handling
- Web: Render playlist page (works without app)
- App: Open playlist view directly

### Social Share Options
- Copy link
- Share to Twitter/X
- Share to Instagram Stories
- Share to Facebook
- Share via system share sheet

## UI Design

### Create Playlist
```
┌─────────────────────────────────────┐
│ Create Playlist                     │
├─────────────────────────────────────┤
│ Name: [Best Horror Movies      ]    │
│                                     │
│ Description (optional):             │
│ [My favorite scary movies for   ]   │
│ [Halloween season...            ]   │
│                                     │
│ Visibility:                         │
│ ○ Public (anyone with link)         │
│ ● Private (only you)                │
│                                     │
│           [Create Playlist]         │
└─────────────────────────────────────┘
```

### Playlist View (Owner)
```
┌─────────────────────────────────────┐
│ 🎬 Best Horror Movies        [Share]│
│ by @username • 8 items              │
├─────────────────────────────────────┤
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐    │
│ │  1  │ │  2  │ │  3  │ │  4  │    │
│ │     │ │     │ │     │ │     │    │
│ │     │ │     │ │     │ │     │    │
│ └─────┘ └─────┘ └─────┘ └─────┘    │
│ Hereditary The Ring Get Out Midsomm │
│                                     │
│ [+ Add Item]              [Edit]    │
└─────────────────────────────────────┘
```

### Playlist View (Recipient)
```
┌─────────────────────────────────────┐
│ 🎬 Best Horror Movies               │
│ by @username • 8 items              │
├─────────────────────────────────────┤
│ 1. Hereditary (2018)     [+ Add]    │
│ 2. The Ring (2002)       [+ Add]    │
│ 3. Get Out (2017)        [✓ Added]  │
│ ...                                 │
│                                     │
│ [Add All to Watchlist]              │
└─────────────────────────────────────┘
```

## Backend Changes
- Migration for `playlists` and `playlist_items` tables
- RLS: Public playlists readable by anyone
- RLS: Only owner can modify
- Slug generation (unique, URL-safe)
- View count increment function

## Frontend Changes
- `PlaylistRepository`
- `PlaylistController` (GetX)
- UI: Playlist creation/edit screens
- UI: Playlist view screen
- UI: My Playlists section on profile
- Share sheet integration
- Deep link handler for playlist URLs

## Web Considerations
- Playlist pages should be SEO-friendly
- Open Graph meta tags for social previews
- Server-side rendering or pre-rendering for share previews

## Dependencies
- Deep linking infrastructure
- Social share packages (`share_plus`)
- Optional: Web app or landing pages for non-app users

## QA Checklist
- [ ] Can create playlist
- [ ] Can add items to playlist
- [ ] Can reorder items
- [ ] Can set visibility
- [ ] Share link generated correctly
- [ ] Link opens in app (deep link)
- [ ] Link works in browser (web view)
- [ ] Recipient can view without account
- [ ] Logged-in recipient can add to watchlist
- [ ] Social share shows preview card
- [ ] Can edit/delete own playlist
