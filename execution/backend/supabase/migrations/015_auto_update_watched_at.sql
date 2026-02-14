-- BingeQuest Migration: Auto-update watched_at timestamp
-- Supports "Recent Progress Mode" feature
--
-- This trigger automatically sets watched_at = NOW() whenever
-- minutes_watched or watched status changes on watch_progress entries.

-- Create the trigger function
CREATE OR REPLACE FUNCTION update_watched_at()
RETURNS TRIGGER AS $$
BEGIN
    -- On INSERT: set watched_at if there's actual progress
    IF TG_OP = 'INSERT' THEN
        IF NEW.minutes_watched > 0 OR NEW.watched = true THEN
            NEW.watched_at = NOW();
        END IF;
        RETURN NEW;
    END IF;

    -- On UPDATE: set watched_at when progress changes
    IF TG_OP = 'UPDATE' THEN
        IF NEW.minutes_watched IS DISTINCT FROM OLD.minutes_watched
           OR NEW.watched IS DISTINCT FROM OLD.watched THEN
            NEW.watched_at = NOW();
        END IF;
        RETURN NEW;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for INSERT and UPDATE
CREATE TRIGGER trg_watch_progress_update_watched_at
    BEFORE INSERT OR UPDATE ON public.watch_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_watched_at();

-- Backfill: Set watched_at for existing progress entries that have none
-- Uses created_at approximation or NOW() as fallback
UPDATE public.watch_progress
SET watched_at = NOW()
WHERE watched_at IS NULL
  AND (minutes_watched > 0 OR watched = true);
