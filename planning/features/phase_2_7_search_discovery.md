# Feature: Phase 2.7 - Enhanced Search & Discovery

## Status
Completed

**Mode**: FLOW (Low risk, standard API integrations)
**Assigned**: Flutter Engineer

## Summary
Enhance the content discovery experience by adding Actor search, Trailer playback, and Streaming Availability information. All data will be sourced from the existing TMDB API integration.

## Objectives
1.  **Actor Search**: Allow users to search for people and view their filmography.
2.  **Trailers**: Enable users to watch trailers for movies/shows (via YouTube).
3.  **Streaming Info**: Show where content can be watched (via TMDB/JustWatch).

## Technical Implementation

### 1. Actor Search & Details
*   **API**:
    *   Search: `GET /search/person?query=...`
    *   Details: `GET /person/{person_id}?append_to_response=combined_credits`
*   **Models**:
    *   `Person` (id, name, profilePath, knownForDepartment)
    *   `PersonDetails` (biography, birthday, placeOfBirth, combinedCredits)
*   **UI**:
    *   Update `SearchScreen` to include a "People" filter chip.
    *   Create `PersonDetailScreen` with bio and horizontal scroll of "Known For" (movies/shows).
    *   Tapping a credit navigates to `ItemDetailScreen`.

### 2. Watch Trailers
*   **API**: `GET /{movie_id}/videos` or `/{tv_id}/videos`
*   **Logic**:
    *   Filter results for `site: "YouTube"` and `type: "Trailer"`.
    *   Prioritize `official: true`.
*   **UI**:
    *   Add "Watch Trailer" button to `ItemDetailScreen`.
    *   Action: Open a modal/dialog or navigate to a `TrailerPlayerScreen` with `youtube_player_flutter`.
    *   Support fullscreen playback and auto-play.

### 3. Streaming Availability (Where to Watch)
*   **API**: `GET /{movie_id}/watch/providers` or `/{tv_id}/watch/providers`
*   **Logic**:
    *   Check `results.US` (or user's locale if we add that setting later, default to US for MVP).
    *   Extract `flatrate` (subscription), `rent`, and `buy` lists.
    *   Extract `link` (JustWatch landing page).
*   **UI**:
    *   Add "Where to Watch" section to `ItemDetailScreen`.
    *   Display provider logos (using TMDB image base URL).
    *   Add "Check Availability" button that launches the `link` URL.

## Acceptance Criteria
- [ ] User can search for "Tom Cruise" and see his profile.
- [ ] User can view Tom Cruise's filmography and tap a movie to see details.
- [ ] "Watch Trailer" button appears on Movie/TV details if a trailer exists.
- [ ] Tapping "Watch Trailer" opens YouTube.
- [ ] "Where to Watch" section shows logos for Netflix, Hulu, etc.
- [ ] Tapping a provider or "Check Availability" opens the JustWatch web page.

## Dependencies
- `url_launcher` package (for JustWatch links).
- `youtube_player_flutter` package (for in-app trailers).
- TMDB API Key (already configured).
