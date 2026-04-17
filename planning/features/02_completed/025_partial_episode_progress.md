# Feature: Partial Episode Progress & Draggable Slider

## Status
Completed

## Overview
Enable partial progress tracking for TV episodes and introduce a draggable slider for fine-grained progress control for both movies and episodes.

## Acceptance Criteria
- [x] Episodes support `minutes_watched` (partial progress)
- [x] Draggable slider widget for precise progress selection
- [x] Episode list shows progress bars for partially watched episodes

## Backend Changes
- None (uses existing `watch_progress.minutes_watched`)

## Frontend Changes
- `ProgressSlider` reusable widget
- Update `EpisodeListItem` to show progress and handle slider input
- Update `ItemDetailScreen` (Movie) to use the new slider

## QA Checklist
- [ ] Verify slider updates `minutes_watched` correctly
- [ ] Verify episode progress is saved and restored
- [ ] Verify "Resume" state is correctly identified for partial episodes
