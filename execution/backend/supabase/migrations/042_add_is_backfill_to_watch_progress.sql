-- Migration 042: Add is_backfill to watch_progress
-- Safe, non-breaking — existing rows default to false.
-- Backfill rows are excluded from all time-series analytics queries.

ALTER TABLE watch_progress
  ADD COLUMN is_backfill BOOLEAN NOT NULL DEFAULT false;
