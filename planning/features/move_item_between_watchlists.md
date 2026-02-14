# Feature: Move Item Between Watchlists

## Status
Completed

## Overview
Allow users to easily move a watchlist item from one watchlist to another, preserving all watch progress data.

## Problem Statement
Currently, if a user wants to move an item from one watchlist to another, they must:
1. Remove the item from the original watchlist (loses all progress)
2. Add it to the new watchlist (starts fresh)

This is frustrating when:
- An item was added to the wrong watchlist by mistake
- Watching circumstances change (e.g., "my wife doesn't want to watch this anymore")
- Users reorganize their watchlists

## User Stories
1. As a user, I want to move a show from "Watch with Wife" to "Solo Watching" without losing my episode progress
2. As a user, I want to quickly fix adding something to the wrong watchlist
3. As a user, I want to reorganize my watchlists without re-tracking progress

## Requirements

### Functional
- Move item preserves ALL watch progress (watched episodes, partial progress, timestamps)
- User can select destination watchlist from a list
- Cannot move to a watchlist that already contains the same item
- Move operation is atomic (no data loss on failure)

### Non-Functional
- Operation should complete in < 2 seconds
- Confirmation before move (prevents accidents)
- Success feedback after move

## Proposed UX Flow

### Entry Point 1: Item Detail Screen (Primary)
1. User opens item detail screen
2. Taps overflow menu (⋮) or dedicated "Move" button
3. Bottom sheet appears: "Move to Watchlist"
4. Shows list of other watchlists (excludes current, excludes ones already containing item)
5. User selects destination
6. Confirmation: "Move [Title] to [Watchlist Name]?"
7. On confirm: item moves, success snackbar, UI updates

### Entry Point 2: Long-press on Watchlist Grid/List
1. User long-presses item in watchlist view
2. Context menu appears with options: "Move to...", "Remove"
3. Selecting "Move to..." opens same bottom sheet as above

## UI Mockups

### Move Bottom Sheet
```
┌─────────────────────────────────────┐
│ ─────                               │
│                                     │
│  Move "Breaking Bad"                │
│  Currently in: Watch with Wife      │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Select destination:                │
│                                     │
│  ○ My Solo Watchlist                │
│  ○ Sci-Fi Collection                │
│  ○ To Watch Later                   │
│  ● Already in: Family Movies ✓      │  <- disabled
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  [ Cancel ]        [ Move Item ]    │
│                                     │
└─────────────────────────────────────┘
```

### Confirmation Dialog
```
┌─────────────────────────────────────┐
│                                     │
│  Move "Breaking Bad"?               │
│                                     │
│  From: Watch with Wife              │
│  To: My Solo Watchlist              │
│                                     │
│  Your watch progress (3 of 5        │
│  seasons) will be preserved.        │
│                                     │
│  [ Cancel ]           [ Move ]      │
│                                     │
└─────────────────────────────────────┘
```

## Technical Implementation

### Backend Changes

#### Option A: Update watchlist_id (Recommended)
Simple UPDATE query - just change the `watchlist_id` on the `watchlist_items` row.

```sql
-- Move item to different watchlist
UPDATE watchlist_items
SET watchlist_id = $new_watchlist_id
WHERE id = $item_id
AND watchlist_id = $old_watchlist_id;
```

**Pros:**
- Single query, atomic
- All `watch_progress` entries automatically preserved (they reference `watchlist_item_id`, not `watchlist_id`)
- No data duplication

**Cons:**
- None significant

#### Database Consideration
The `watch_progress` table references `watchlist_item_id`, not `watchlist_id` directly. This means moving the item (changing its `watchlist_id`) automatically preserves all progress - no additional migration needed.

### Repository Method

```dart
/// Move a watchlist item to a different watchlist.
/// Returns true if successful, false if item already exists in destination.
static Future<bool> moveItemToWatchlist({
  required String itemId,
  required String fromWatchlistId,
  required String toWatchlistId,
}) async {
  // Check if item already exists in destination
  final existingItem = await _client
      .from('watchlist_items')
      .select('id')
      .eq('watchlist_id', toWatchlistId)
      .eq('tmdb_id', /* get from item */)
      .eq('media_type', /* get from item */)
      .maybeSingle();

  if (existingItem != null) {
    return false; // Already exists in destination
  }

  // Move the item
  await _client
      .from('watchlist_items')
      .update({'watchlist_id': toWatchlistId})
      .eq('id', itemId);

  return true;
}
```

### Frontend Changes

#### New Widget: MoveItemSheet
`lib/features/watchlist/widgets/move_item_sheet.dart`

```dart
class MoveItemSheet extends StatefulWidget {
  final WatchlistItem item;
  final String currentWatchlistId;
  final VoidCallback? onMoved;

  static Future<void> show({
    required BuildContext context,
    required WatchlistItem item,
    required String currentWatchlistId,
    VoidCallback? onMoved,
  });
}
```

#### Item Detail Screen Updates
- Add "Move" option to overflow menu or as dedicated button
- Handle move result and refresh UI

#### Watchlist Screen Updates (Optional)
- Add long-press gesture for context menu
- Include "Move to..." option

## Files to Create

| File | Purpose |
|------|---------|
| `lib/features/watchlist/widgets/move_item_sheet.dart` | Bottom sheet for selecting destination |

## Files to Modify

| File | Changes |
|------|---------|
| `lib/shared/repositories/watchlist_repository.dart` | Add `moveItemToWatchlist()` method |
| `lib/features/watchlist/screens/item_detail_screen.dart` | Add move button/menu option |
| `lib/features/watchlist/controllers/watchlist_controller.dart` | Add move method, refresh after move |

## Edge Cases

1. **Item already in destination**: Show error, don't allow move
2. **Only one watchlist**: Hide/disable move option
3. **Network failure during move**: Show error, item stays in original location
4. **Destination watchlist deleted during selection**: Refresh list, show error if selected

## Testing Checklist

- [ ] Move item preserves all watched episodes
- [ ] Move item preserves partial episode progress
- [ ] Move item preserves timestamps (watched_at)
- [ ] Cannot move to watchlist already containing item
- [ ] Cannot move to same watchlist
- [ ] Move option hidden when only one watchlist exists
- [ ] UI updates correctly after move (both source and destination)
- [ ] Error handling for network failures

## Future Enhancements

1. **Copy to watchlist**: Duplicate item to another watchlist (for shared watching)
2. **Bulk move**: Select multiple items and move together
3. **Move with progress reset**: Option to move but start fresh

## Priority
Medium - Quality of life improvement for multi-watchlist users

## Estimated Scope
- Backend: Small (1 repository method)
- Frontend: Medium (new widget, UI updates to 2-3 screens)
