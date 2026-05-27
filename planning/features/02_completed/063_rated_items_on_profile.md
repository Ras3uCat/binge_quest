# Feature: Rated Items on Profile

**Mode:** STUDIO  
**Status:** COMPLETED

## Context

Users rate content (1–5 stars) via the `reviews` table. Right now those ratings are only surfaced on individual content detail screens. There is no way to browse everything a user has rated, and profiles show nothing about their rating history. This feature adds a "Ratings" section to both the own-profile screen and the user-profile screen (friends/public), sortable by date or rating value.

## Scope

### What's included
- `ReviewRepository`: new `getReviewsByUser(userId)` method — two-step fetch that merges `reviews` with `content_cache` for title/poster; no sort param (sorting is client-side)
- `RatedItemCard` widget: poster thumbnail + title + media-type chip + star rating row + date
- `RatedItemsSection` widget: header with sort toggle (Date ↕ / Rating ↕), lazy-loaded list of `RatedItemCard`s, empty state
- `ProfileController`: `ratedItems` observable + `loadRatedItems()` + sort state
- `UserProfileController`: same additions (reads the target user's reviews, not the auth user's)
- `ProfileScreen`: add `RatedItemsSection` below `BadgesSection`
- `UserProfileScreen`: add `RatedItemsSection` below the playlists/badges section

### What's excluded
- Pagination (load all reviews; revisit if counts grow large)
- Privacy toggle (reviews are already public per existing RLS)
- `reviewText` preview in card (model has the field; deliberately omitted for card density — revisit)
- Stats section rated-count update (derive from `ratedItems.length` if needed, no separate query)

## Data Layer

**New method:** `ReviewRepository.getReviewsByUser(String userId)`

**Join strategy — two-step fetch (no migration required):**
PostgREST nested selects only work via declared foreign keys. `reviews.tmdb_id` has no FK to `content_cache`, so `select('*, content_cache(...)')` will fail at runtime. Use a two-step approach instead:

1. Fetch all reviews for user: `.select('*').eq('user_id', userId)`
2. Collect unique `(tmdb_id, media_type)` pairs; fetch matching `content_cache` rows in one query using `.in_()` or `or()` filters
3. Merge in Dart — attach `title`/`posterPath` from the cache map before returning

If a future migration adds the FK, this can be simplified to a single `.select('*, content_cache(title, poster_path)')` call.

**`ReviewSort` enum** — declare in `lib/shared/repositories/review_repository.dart` (data-layer concern, shared by both controllers):

```dart
enum ReviewSort { dateDesc, dateAsc, ratingDesc, ratingAsc }
```

**`Review` model additions** — new fields are flat (not nested), populated by Dart merge step:

```dart
final String? title;       // from content_cache
final String? posterPath;  // from content_cache
```

`fromJson` does NOT need to handle a `content_cache` nested key — the merge happens in the repository before constructing `Review` objects. Add a `copyWith(title, posterPath)` or a secondary factory to support the merge pattern.

Existing RLS on `reviews` allows SELECT for all authenticated users; `content_cache` has permissive RLS (intentional per ADR). No policy change needed.

## Files to Create / Modify

| File | Action |
|------|--------|
| `lib/shared/repositories/review_repository.dart` | Add `ReviewSort` enum + `getReviewsByUser()` method |
| `lib/shared/models/review.dart` | Add `title`, `posterPath` nullable fields + `copyWith`; **no** `fromJson` change for join |
| `lib/features/profile/widgets/rated_items_section.dart` | **New** — section widget with sort toggle + list |
| `lib/features/profile/widgets/rated_item_card.dart` | **New** — single rated item card |
| `lib/features/profile/controllers/profile_controller.dart` | Add `ratedItems`, `ratedItemsSort`, `isLoadingRatings`, `ratingsError`, `loadRatedItems()`, `onSortRatingsDate()`, `onSortRatingsRating()`, `_applySortAndUpdate()` — landed at 230 lines |
| `lib/features/profile/controllers/user_profile_controller.dart` | Add same rated-items state (public observables, matching existing pattern) — landed at 199 lines |
| `lib/features/profile/screens/profile_screen.dart` | Insert `RatedItemsSection()` below `BadgesSection` |
| `lib/features/profile/screens/user_profile_screen.dart` | Insert `RatedItemsSection(isOwnProfile: false)` below `FriendBadgesSection` |

## UI Design Notes

- `RatedItemCard`: 60×90 poster (same aspect ratio as `WatchlistItemCard`), title truncated to 2 lines, row of 5 TV-screen icons (reuse pattern from `ReviewCard`), media-type chip, relative date ("2 days ago")
- `RatedItemsSection` sort toggle: two pill buttons ("Date" / "Rating") implemented as `AnimatedContainer` with border + active fill; active button shows an `↑`/`↓` arrow icon indicating direction
- **Sort toggle behavior:** tapping the active button cycles asc↔desc (arrow flips); tapping the inactive button switches category, defaulting to desc. Maps all four `ReviewSort` values to two buttons via `onSortRatingsDate()` / `onSortRatingsRating()` on the controller.
- **Navigation:** tapping a card opens `ContentDetailSheet` (not `ItemDetailScreen`). `ItemDetailScreen` requires a full `WatchlistItem` which cannot be constructed from a `Review`. `TmdbSearchResult` is built from `tmdbId`, `mediaType`, `title`, `posterPath` and passed to `Get.bottomSheet(ContentDetailSheet(result: result))`.
- Respect the 300-line file limit; split widget file if needed

## Acceptance Criteria

1. Own profile shows a "Ratings" section listing all content the auth user has rated
2. Another user's profile shows the same section for their ratings
3. Sort by Date (newest first default) and Sort by Rating both work correctly; tapping the active sort button cycles asc↔desc
4. Empty state shown when user has no ratings
5. Tapping a rated item opens `ContentDetailSheet` as a bottom sheet with the correct title and poster
6. Loading state is shown while fetch is in progress (spinner or skeleton)
7. On fetch error, an inline error message is shown (not a crash); list does not remain permanently empty without feedback

## Verification

1. Add a review via item detail screen, then open own profile — item appears in Ratings section
2. Switch sort to Rating — list reorders correctly; tap again — order reverses (asc↔desc cycles)
3. View a friend's profile — their Ratings section is visible
4. User with no reviews — empty state renders without errors
5. Simulate network error (disable wifi) — error message shown, no crash
6. Tap a rated item — `ContentDetailSheet` opens with correct title and poster
7. `dart analyze` passes with no new warnings
