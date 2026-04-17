# Bug Fix: Genre Filter Sheet Visibility

## Status
Incomplete

## Context
The "Filter by Genre" button in the Dashboard dims the screen (indicating the modal barrier is active) but displays no content. This suggests a rendering issue where the bottom sheet content is either transparent, collapsed to zero size, or failing to render due to missing Material context.

## Root Cause Analysis
The current implementation relies on `Get.bottomSheet`'s `backgroundColor` and `shape` parameters, while the child widget is a `Material` wrapper. This differs from the working `WatchlistSelectorWidget`, which passes a self-contained `Container` with styling to `Get.bottomSheet` and ignores the sheet's native styling parameters.

## Proposed Solution
Refactor `GenreFilterSheet` to match the "known good" pattern used in `WatchlistSelectorWidget`. This involves moving the styling (color, border radius) from the `Get.bottomSheet` call into a container within the widget itself.

## Implementation Plan

### 1. Update `GenreFilterSheet.show()`
Remove styling arguments from the static show method to rely on the widget's internal styling.

**File:** `lib/features/dashboard/widgets/genre_filter_sheet.dart`

```dart
static void show() {
  Get.bottomSheet(
    const GenreFilterSheet(),
    isScrollControlled: true, // Ensures sheet can take required height
    // Remove backgroundColor and shape from here
  );
}
```

### 2. Update `GenreFilterSheet.build()`
Wrap the content in a `Container` that defines the visual structure, followed by `SafeArea`.

**File:** `lib/features/dashboard/widgets/genre_filter_sheet.dart`

```dart
@override
Widget build(BuildContext context) {
  return Container(
    decoration: const BoxDecoration(
      color: EColors.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(ESizes.radiusLg)),
    ),
    child: SafeArea(
      top: false, // Bottom sheet attaches to bottom, so top safe area isn't needed usually
      child: Padding(
        padding: const EdgeInsets.only(bottom: ESizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildHeader(),
            const SizedBox(height: ESizes.md),
            _buildGenreGrid(),
            _buildActions(),
          ],
        ),
      ),
    ),
  );
}
```

### 3. Verification
1.  Launch the app.
2.  Navigate to Dashboard.
3.  Tap "Genres" filter button.
4.  **Expectation:** The sheet slides up, has a dark grey background (`EColors.surface`), rounded top corners, and visible content (Header, Grid, Actions).

## Fallback
If the issue persists, we will investigate:
1.  `ContentGenre.allGenres` data integrity.
2.  `WatchlistController.items` population status (to ensure `userGenreIds` isn't empty causing an empty state that renders poorly).
