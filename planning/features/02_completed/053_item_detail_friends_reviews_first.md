# Feature: Item Detail — Friends' Reviews First

## Status
TODO

## Priority
Medium — improves social relevance of review feed

## Overview
On the item detail page, reviews from the current user's friends should appear at the top of the list, followed by all other reviews. Currently reviews are shown in a flat chronological order with no social prioritization.

## Acceptance Criteria
- [ ] Friends' reviews appear before non-friends' reviews in the review list.
- [ ] Within the friends group, reviews are sorted newest first.
- [ ] Within the non-friends group, reviews are sorted newest first.
- [ ] If the user has no friends with reviews, the list is unchanged from current behavior.
- [ ] The "friend" label or visual indicator remains on friend reviews.

## Backend Changes
Update the reviews query for item detail to join with `friendships`:

```sql
SELECT r.*,
  CASE WHEN f.user_id_1 IS NOT NULL THEN true ELSE false END AS is_friend
FROM reviews r
LEFT JOIN friendships f
  ON (f.user_id_1 = auth.uid() AND f.user_id_2 = r.user_id)
  OR (f.user_id_2 = auth.uid() AND f.user_id_1 = r.user_id)
WHERE r.content_id = $contentId
ORDER BY is_friend DESC, r.created_at DESC;
```

Use the `are_friends(UUID, UUID)` helper if already indexed for this query shape.

## Frontend Changes
- Update the repository method that fetches reviews for an item to use the new query.
- Map the `is_friend` boolean from the response (already used for the friend badge).
- No UI change needed if the badge already exists — just reorder.

## QA Checklist
- [ ] Item with friend and non-friend reviews: friend reviews appear first.
- [ ] Item with only non-friend reviews: order unchanged (newest first).
- [ ] Item with only friend reviews: all shown, newest first.
- [ ] Blocked users' reviews do not appear (existing behavior preserved).
