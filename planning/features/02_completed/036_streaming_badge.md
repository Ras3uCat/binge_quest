# Feature: Streaming Availability Badge

## Status
Competed

## Overview
Display a visual badge on content thumbnails to indicate the item is available for streaming (subscription services, not rent/buy). Helps users quickly identify what they can watch now.

## User Stories
- As a user, I want to quickly see which items I can stream right now
- As a user, I want to distinguish between streamable and theater/rent-only content
- As a user, I want the badge to reflect my streaming subscriptions

## Acceptance Criteria
- [ ] Badge appears on thumbnails for items with streaming availability
- [ ] Badge only shows for subscription services (not rent/buy)
- [ ] Badge is subtle but visible (corner icon or indicator)
- [ ] Optional: Badge shows specific service logo(s)
- [ ] Works on: watchlist items, search results, recommendations

## Design Options

### Option A: Simple Indicator
```
┌──────────────┐
│ ┌──┐         │
│ │▶ │ Poster  │  ▶ = "Streamable" icon
│ └──┘         │
│              │
└──────────────┘
```

### Option B: Service Logo
```
┌──────────────┐
│      ┌─────┐ │
│      │ N   │ │  Netflix logo badge
│      └─────┘ │
│   Poster     │
└──────────────┘
```

### Option C: Multi-Service Dots
```
┌──────────────┐
│ ● ● ●        │  Colored dots for each service
│              │
│   Poster     │
└──────────────┘
```

## Data Requirements
- Streaming provider data already fetched via TMDB
- `content_cache` stores `streaming_providers` JSON
- Need to filter for subscription types only

## Provider Type Filtering
TMDB provides:
- `flatrate` = Subscription streaming (Netflix, Disney+, etc.)
- `rent` = Rental options
- `buy` = Purchase options
- `free` = Free with ads

Badge should show for: `flatrate` and optionally `free`

## Frontend Changes
- Create `StreamingBadge` widget
- Add to poster/thumbnail components
- Conditionally render based on streaming data
- Optional: User preference for which services to highlight

## Affected Components
- `lib/shared/widgets/poster_card.dart` (or similar)
- `lib/features/watchlist/widgets/watchlist_item_card.dart`
- `lib/features/search/widgets/search_result_card.dart`
- `lib/features/recommendations/widgets/recommendation_card.dart`

## Implementation Notes
```dart
class StreamingBadge extends StatelessWidget {
  final List<StreamingProvider>? providers;

  bool get hasStreaming => providers?.any(
    (p) => p.type == 'flatrate' || p.type == 'free'
  ) ?? false;

  @override
  Widget build(BuildContext context) {
    if (!hasStreaming) return const SizedBox.shrink();

    return Positioned(
      top: 4,
      left: 4,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: EColors.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(Icons.play_circle, size: 16, color: EColors.primary),
      ),
    );
  }
}
```

## QA Checklist
- [ ] Badge appears on items with subscription streaming
- [ ] Badge does NOT appear on rent/buy only items
- [ ] Badge visible but not obstructive
- [ ] Works in watchlist view
- [ ] Works in search results
- [ ] Works in recommendations
- [ ] Performance: No lag from badge rendering
