-- Revoke social badges awarded incorrectly due to criteria_json type mismatch bug.
-- Only one user was affected (all 19 awards within a 2-second burst on 2026-05-26).
DELETE FROM public.user_badges
WHERE badge_id IN (SELECT id FROM public.badges WHERE category = 'social')
  AND earned_at BETWEEN '2026-05-26 20:19:00+00' AND '2026-05-26 20:20:00+00';
