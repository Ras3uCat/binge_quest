# Bug: Archetype History Duplicate Entries

## Status
TODO

## Priority
High — history data is corrupted / misleading

## Overview
The archetype history screen is showing far more entries than there have been days in the month. The `user_archetypes` table IS the history (no separate table) — each computation run inserts 12 rows (one per archetype), all sharing the same `computed_at` timestamp. The current conflict key is `(user_id, archetype_id, computed_at)`. Since `computed_at` is a full timestamp, an hourly cron produces 12 new rows every hour with no conflict triggered. The guard needs to operate at the **date** level, not the timestamp level.

## Root Cause
In `compute_user_archetype` (SQL function):
- `v_now := now()` is set at function start
- All 12 archetype rows are inserted with that exact timestamp
- `ON CONFLICT (user_id, archetype_id, computed_at) DO NOTHING` — only deduplicates within the same second
- If cron fires hourly, each hour's `now()` is different → 12 new rows per hour, no conflict

## Investigation Steps
1. Confirm cron frequency: `SELECT * FROM cron.job WHERE jobname ILIKE '%archetype%';`
2. Check actual row counts per user per day: `SELECT user_id, DATE(computed_at), COUNT(*) FROM user_archetypes GROUP BY 1,2 ORDER BY 3 DESC LIMIT 20;`
3. Confirm there is no existing date-level unique index on `user_archetypes`

## Acceptance Criteria
- [ ] At most one computation run (12 rows) per user per calendar day.
- [ ] Existing duplicate rows cleaned up — keep only the latest `computed_at` per `(user_id, DATE(computed_at))`.
- [ ] Running `compute_user_archetype` multiple times in a day is a no-op after the first run.
- [ ] History screen shows one entry per day.

## Backend Changes

### 1. Add date-level guard to `compute_user_archetype`
At the top of the function body, after resolving `v_tz`, add an early exit:
```sql
-- Skip if already computed today (in user's timezone)
IF EXISTS (
  SELECT 1 FROM user_archetypes
  WHERE user_id = p_user_id
    AND DATE(computed_at AT TIME ZONE v_tz) = DATE(now() AT TIME ZONE v_tz)
) THEN
  SELECT primary_archetype INTO result.prev_archetype FROM users WHERE id = p_user_id;
  result.new_archetype := result.prev_archetype;
  RETURN result;
END IF;
```

### 2. Add unique index to enforce at DB level
```sql
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_archetypes_user_date
  ON public.user_archetypes (user_id, DATE(computed_at));
```
Note: This index uses `DATE(computed_at)` in UTC. The function-level guard above uses the user's timezone for the skip check — the index is a safety net.

### 3. One-time cleanup migration
```sql
-- Keep only the latest computed_at per (user_id, date) — delete all earlier duplicates
DELETE FROM user_archetypes
WHERE id NOT IN (
  SELECT DISTINCT ON (user_id, DATE(computed_at)) id
  FROM user_archetypes
  ORDER BY user_id, DATE(computed_at), computed_at DESC
);
```
Run cleanup BEFORE adding the unique index.

## Frontend Changes
None — display is correct once data is deduplicated.

## QA Checklist
- [ ] After fix: `SELECT user_id, DATE(computed_at), COUNT(*) FROM user_archetypes GROUP BY 1,2 HAVING COUNT(*) > 12` returns 0 rows.
- [ ] Trigger `compute_user_archetype` twice in one day for a test user — second call is a no-op.
- [ ] History screen shows one entry per day, no duplicates.
- [ ] Historical duplicates from March 2026 are gone.
